/*

### Purpose
The `apb_uart_top` module serves as the top-level wrapper for a Universal Asynchronous Receiver-Transmitter (UART) peripheral, designed to interface with an Advanced Peripheral Bus (APB). It integrates register-based configuration, clock division, FIFO buffering for both transmission and reception, and the core UART serial communication logic.

### Use Case
This module is intended to be integrated into SoC designs as a standard serial communication peripheral. It allows a system processor (via the APB bus) to configure baud rates, frame formats (data bits, parity, stop bits), and manage data flow through hardware FIFOs. It is ideal for applications requiring asynchronous serial communication, such as debug consoles, sensor interfacing, or inter-chip communication where low pin-count connectivity is required.

| REVISION | DATE       | AUTHOR              | DESCRIPTION                                            |
|----------|------------|---------------------|--------------------------------------------------------|
| 0.1      | 2026-08-13 | Ahasan Ullah Khalid | Initial version                                        |
| 1.0      | 2026-08-17 | Ahasan Ullah Khalid | Stable release                                         |

Author : Ahasan Ullah Khalid (aukhalid02@gmail.com)
This file is part of ADN-VLSI/apb_uart
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

`include "../submodule/adn_apb/include/apb/typedef.svh"

// Define the packed request and response structs for this module's APB interface
`APB_T(apb, 32, 32)

module apb_uart_top #(
    parameter int ADDR_WIDTH = 32,  // Width of the APB address bus
    parameter int DATA_WIDTH = 32,  // Width of the APB data bus
    parameter int FIFO_SIZE  = 4    // log2(16) -> Depth of 16 for FIFOs
) (
    // Global Clock & Reset
    input logic PCLK,    // APB Clock
    input logic PRESETn, // APB Reset (Active Low)

    // APB Bus Interface (Struct / Typedef Based)
    input  apb_req_t  apb_req_i,  // APB Request: psel, penable, paddr, pwrite, pwdata, etc.
    output apb_resp_t apb_resp_o, // APB Response: pready, prdata, pslverr

    // UART External Interface
    output logic UART_TX,  // UART Transmit Data
    input  logic UART_RX,  // UART Receive Data

    // Interrupt
    output logic UART_IRQ  // UART Interrupt Request
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // APB-to-Register translated signals for bus handshake
  logic               reg_write_en;
  logic               reg_read_en;

  // Hardware Control signals derived from Register Block configuration
  logic               uart_sw_rst;
  logic               datapath_rst_n;
  logic               tx_fifo_rst_n;
  logic               rx_fifo_rst_n;
  logic               tx_fifo_flush;
  logic               rx_fifo_flush;
  logic               tx_en;
  logic               rx_en;
  logic [       11:0] clk_div;
  logic [        3:0] prescaler;
  logic [        1:0] data_bits;
  logic               parity_en;
  logic               parity_type;
  logic               stop_bits;

  // FIFO Status signals for monitoring buffer occupancy
  logic [        9:0] tx_data_cnt;
  logic [        9:0] rx_data_cnt;
  logic [FIFO_SIZE:0] tx_fifo_count;
  logic [FIFO_SIZE:0] rx_fifo_count;
  logic               tx_fifo_empty;
  logic               tx_fifo_full;
  logic               rx_fifo_empty;
  logic               rx_fifo_full;

  // TX Datapath signals connecting FIFO to Transmitter
  logic [        7:0] tx_fifo_wdata;
  logic               tx_fifo_push;  // From APB
  logic               tx_fifo_ready_in;  // To APB
  logic [        7:0] tx_fifo_rdata;  // To Tx
  logic               tx_fifo_valid_out;  // To Tx
  logic               tx_ready_in;  // From Tx
  logic               tx_fifo_pop_ready;  // Gated pop to avoid draining when tx_en=0

  // RX Datapath signals connecting Receiver to FIFO
    logic [        7:0] rx_fifo_wdata;  // From Rx
  logic               rx_data_valid_out;  // From Rx
    logic               rx_data_valid_sync;
    logic               rx_data_valid_sync_d;
  logic               rx_fifo_push;  // To RX FIFO
  logic               rx_fifo_ready_in;  // From RX FIFO
  logic [        7:0] rx_fifo_rdata;  // To APB
  logic               rx_fifo_pop;  // From APB
  logic               rx_fifo_valid_out;  // To RX FIFO

  // Generated Clock for UART baud rate generation
  logic               uart_clk;

  // Arbitration signals for bus access control
  logic [        7:0] tx_access_req_id;
  logic               tx_req_valid;
  logic               tx_grant_pop;
  logic [        7:0] rx_access_req_id;
  logic               rx_req_valid;
  logic               rx_grant_pop;

  // Interrupt Enable configuration bits
  logic               tx_fifo_empty_int_en;
  logic               tx_fifo_full_int_en;
  logic               rx_fifo_empty_int_en;
  logic               rx_fifo_full_int_en;
  logic               tx_data_valid_masked;

  // Interrupt Controller status signals
  logic               tx_empty_irq;
  logic               tx_full_irq;
  logic               rx_empty_irq;
  logic               rx_full_irq;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // APB to Register Bus Bridge (unpacked from apb_req_i struct)
  always_comb reg_write_en = apb_req_i.psel & apb_req_i.penable & apb_req_i.pwrite;
  always_comb reg_read_en = apb_req_i.psel & apb_req_i.penable & ~apb_req_i.pwrite;

  // Datapath Reset Management
  always_comb datapath_rst_n = PRESETn & ~uart_sw_rst;
  always_comb tx_fifo_rst_n = datapath_rst_n & ~tx_fifo_flush;
  always_comb rx_fifo_rst_n = datapath_rst_n & ~rx_fifo_flush;

  // Status flag logic translation mapping
  always_comb tx_fifo_full = ~tx_fifo_ready_in;
  always_comb tx_fifo_empty = ~tx_fifo_valid_out;
  always_comb rx_fifo_full = ~rx_fifo_ready_in;
  always_comb rx_fifo_empty = ~rx_fifo_valid_out;

  // Zero-pad variable sized count flags for fixed width 10-bit APB registers
  always_comb tx_data_cnt = {{(10 - FIFO_SIZE - 1) {1'b0}}, tx_fifo_count};
  always_comb rx_data_cnt = {{(10 - FIFO_SIZE - 1) {1'b0}}, rx_fifo_count};

    // Synchronize the receiver pulse and enqueue only once in the PCLK domain.
    always_ff @(posedge PCLK or negedge datapath_rst_n) begin
        if (!datapath_rst_n) begin
            rx_data_valid_sync <= 1'b0;
            rx_data_valid_sync_d <= 1'b0;
        end else begin
            rx_data_valid_sync <= rx_data_valid_out;
            rx_data_valid_sync_d <= rx_data_valid_sync;
        end
    end

    always_comb rx_fifo_push = rx_data_valid_sync & ~rx_data_valid_sync_d & rx_en;

  // Valid and ready inputs to/from Tx are gated by tx_en
  always_comb tx_data_valid_masked = tx_fifo_valid_out & tx_en;

    // Hold the FIFO dequeue acknowledgement until the UART clock has sampled
    // the current byte; the FIFO itself is clocked by PCLK.
    always_ff @(posedge uart_clk or negedge datapath_rst_n) begin
        if (!datapath_rst_n)
            tx_fifo_pop_ready <= 1'b0;
        else
            tx_fifo_pop_ready <= tx_data_valid_masked & tx_ready_in;
    end

  // Interrupt Controller
  always_comb begin
    tx_empty_irq = tx_fifo_empty & tx_fifo_empty_int_en;
    tx_full_irq  = tx_fifo_full & tx_fifo_full_int_en;
    rx_empty_irq = rx_fifo_empty & rx_fifo_empty_int_en;
    rx_full_irq  = rx_fifo_full & rx_fifo_full_int_en;
    UART_IRQ     = tx_empty_irq | tx_full_irq | rx_empty_irq | rx_full_irq;
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SUBMODULES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Register Interface: Maps APB transactions to internal control/status registers
  adn_uart_register_interface #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) u_reg_intf (
      .clk  (PCLK),
      .rst_n(PRESETn),

      .reg_addr    (apb_req_i.paddr),
      .reg_wdata   (apb_req_i.pwdata),
      .reg_write_en(reg_write_en),
      .reg_read_en (reg_read_en),
      .reg_rdata   (apb_resp_o.prdata),
      .reg_ready   (apb_resp_o.pready),
      .reg_error   (apb_resp_o.pslverr),

      .uart_sw_rst  (uart_sw_rst),
      .tx_fifo_flush(tx_fifo_flush),
      .rx_fifo_flush(rx_fifo_flush),
      .tx_en        (tx_en),
      .rx_en        (rx_en),
      .clk_div      (clk_div),
      .prescaler    (prescaler),
      .data_bits    (data_bits),
      .parity_en    (parity_en),
      .parity_type  (parity_type),
      .stop_bits    (stop_bits),

      .tx_data_cnt  (tx_data_cnt),
      .rx_data_cnt  (rx_data_cnt),
      .tx_fifo_empty(tx_fifo_empty),
      .tx_fifo_full (tx_fifo_full),
      .rx_fifo_empty(rx_fifo_empty),
      .rx_fifo_full (rx_fifo_full),

      .tx_fifo_wdata(tx_fifo_wdata),
      .tx_fifo_push (tx_fifo_push),
      .rx_fifo_rdata(rx_fifo_rdata),
      .rx_fifo_pop  (rx_fifo_pop),

      .tx_access_req_id(tx_access_req_id),
      .tx_req_valid    (tx_req_valid),
      .tx_grant_id     (8'h01),
      .tx_grant_valid  (1'b1),
      .tx_grant_pop    (tx_grant_pop),

      .rx_access_req_id(rx_access_req_id),
      .rx_req_valid    (rx_req_valid),
      .rx_grant_id     (8'h01),
      .rx_grant_valid  (1'b1),
      .rx_grant_pop    (rx_grant_pop),

      .tx_fifo_empty_int_en(tx_fifo_empty_int_en),
      .tx_fifo_full_int_en (tx_fifo_full_int_en),
      .rx_fifo_empty_int_en(rx_fifo_empty_int_en),
      .rx_fifo_full_int_en (rx_fifo_full_int_en)
  );

  // Clock Divider: Generates the baud rate clock from PCLK
  adn_clk_rst_clk_div #(
      .DIV_WIDTH(16)
  ) u_clk_div (
      .arst_ni(datapath_rst_n),
      .clk_i  (PCLK),
      .div_i  ({prescaler, clk_div}),
      .clk_o  (uart_clk)
  );

  // TX FIFO: Buffers data to be transmitted
  adn_common_fifo #(
      .DATA_WIDTH(8),
      .FIFO_SIZE (FIFO_SIZE),
      .PIPELINED (1)
  ) u_tx_fifo (
      .arst_ni(tx_fifo_rst_n),
      .clk_i  (PCLK),

      // Write Port (From APB Register Block)
      .data_in_i      (tx_fifo_wdata),
      .data_in_valid_i(tx_fifo_push),
      .data_in_ready_o(tx_fifo_ready_in),

      .count_o(tx_fifo_count),

      // Read Port (To UART Transmitter)
      .data_out_o      (tx_fifo_rdata),
      .data_out_valid_o(tx_fifo_valid_out),
      .data_out_ready_i(tx_fifo_pop_ready)
  );

  // RX FIFO: Buffers received data
  adn_common_fifo #(
      .DATA_WIDTH(8),
      .FIFO_SIZE (FIFO_SIZE),
      .PIPELINED (1)
  ) u_rx_fifo (
      .arst_ni(rx_fifo_rst_n),
      .clk_i  (PCLK),

      // Write Port (From UART Receiver)
      .data_in_i      (rx_fifo_wdata),
      .data_in_valid_i(rx_fifo_push),
      .data_in_ready_o(rx_fifo_ready_in),

      .count_o(rx_fifo_count),

      // Read Port (To APB Register Block)
      .data_out_o      (rx_fifo_rdata),
      .data_out_valid_o(rx_fifo_valid_out),
      .data_out_ready_i(rx_fifo_pop)
  );

  // UART Transmitter: Serializes data from TX FIFO
  adn_uart_transmitter #(
      .DATA_WIDTH(8)
  ) u_uart_tx (
      .arst_ni(datapath_rst_n),
      .clk_i  (uart_clk),

      .data_ready_o(tx_ready_in),
      .data_valid_i(tx_data_valid_masked),
      .data_i      (tx_fifo_rdata),

      .data_bits_i  (data_bits),
      .parity_en_i  (parity_en),
      .parity_type_i(parity_type),
      .extra_stop_i (stop_bits),

      .tx_o(UART_TX)
  );

  // UART Receiver: Deserializes incoming serial data
  adn_uart_receiver #(
      .OVERSAMPLE(8)
  ) u_uart_rx (
      .arst_ni(datapath_rst_n),
      .clk_i  (uart_clk),

      .data_bits_i  (data_bits),
      .parity_en_i  (parity_en),
      .parity_type_i(parity_type),

      .rx_i        (UART_RX),
      .data_o      (rx_fifo_wdata),
      .data_valid_o(rx_data_valid_out)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ASSERTIONS
  //////////////////////////////////////////////////////////////////////////////////////////////////

`ifdef SIMULATION
  initial begin
    if (DATA_WIDTH > 2) begin
      $display("\033[1;33m%m DATA_WIDTH check\033[0m");
    end
  end
`endif  // SIMULATION

endmodule


