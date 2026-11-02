`ifndef __GUARD_APB_UART_SCBD_SV__
`define __GUARD_APB_UART_SCBD_SV__ 0

`include "uvm_macros.svh"
import uvm_pkg::*;

import uart_reg_if_pkg::ADDR_CTRL;
import uart_reg_if_pkg::ADDR_CFG;
import uart_reg_if_pkg::ADDR_STATUS;
import uart_reg_if_pkg::ADDR_TXR;
import uart_reg_if_pkg::ADDR_TXGP;
import uart_reg_if_pkg::ADDR_TXG;
import uart_reg_if_pkg::ADDR_TXD;
import uart_reg_if_pkg::ADDR_RXR;
import uart_reg_if_pkg::ADDR_RXGP;
import uart_reg_if_pkg::ADDR_RXG;
import uart_reg_if_pkg::ADDR_RXD;
import uart_reg_if_pkg::ADDR_INTR;

`include "apb_uart_uvm_tb/obj/apb/apb_rsp_item.sv"
`include "apb_uart_uvm_tb/obj/uart/uart_rsp_item.sv"

`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_uart_tx)
`uvm_analysis_imp_decl(_uart_rx)


class apb_uart_scbd extends uvm_scoreboard;

  `uvm_component_utils(apb_uart_scbd)

  // ------------------------------------------------------------
  // Analysis ports
  // ------------------------------------------------------------

  uvm_analysis_imp_apb #(
    apb_rsp_item, apb_uart_scbd
  ) apb_imp;

  uvm_analysis_imp_uart_tx #(
    uart_rsp_item, apb_uart_scbd
  ) uart_tx_imp;

  uvm_analysis_imp_uart_rx #(
    uart_rsp_item, apb_uart_scbd
  ) uart_rx_imp;


  // ------------------------------------------------------------
  // Transaction queues
  // ------------------------------------------------------------

  bit [7:0] tx_expected_q[$];
  bit [7:0] tx_actual_q[$];
  bit       tx_framing_error_q[$];

  bit [7:0] rx_received_q[$];


  // ------------------------------------------------------------
  // Counters
  // ------------------------------------------------------------

  int unsigned tx_expected_count;
  int unsigned tx_observed_count;
  int unsigned tx_checked_count;

  int unsigned rx_observed_count;
  int unsigned rx_checked_count;

  int unsigned apb_transaction_count;
  int unsigned apb_error_count;
  int unsigned register_checked_count;

  int unsigned pass_count;
  int unsigned fail_count;


  // ------------------------------------------------------------
  // Register shadow model
  // ------------------------------------------------------------

  bit [31:0] ctrl_model;
  bit [31:0] cfg_model;
  bit [31:0] intr_model;

  localparam bit [31:0] CTRL_MASK = 32'h0000_0018;
  localparam bit [31:0] CFG_MASK  = 32'h001F_FFFF;
  localparam bit [31:0] INTR_MASK = 32'h0000_000F;

  localparam bit [31:0] CTRL_RESET = 32'h0000_0000;
  localparam bit [31:0] CFG_RESET  = 32'h0003_405B;
  localparam bit [31:0] INTR_RESET = 32'h0000_0000;


  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------

  function new(
    string name = "apb_uart_scbd",
    uvm_component parent = null
  );

    super.new(name, parent);

    apb_imp     = new("apb_imp", this);
    uart_tx_imp = new("uart_tx_imp", this);
    uart_rx_imp = new("uart_rx_imp", this);

    ctrl_model = CTRL_RESET;
    cfg_model  = CFG_RESET;
    intr_model = INTR_RESET;

  endfunction


  // ------------------------------------------------------------
  // APB transaction handler
  // ------------------------------------------------------------

  virtual function void write_apb(apb_rsp_item tr);

    bit [31:0] expected;

    if (tr == null) begin
      fail_count++;
      `uvm_error("APB_SB", "Received null APB transaction")
      return;
    end

    apb_transaction_count++;

    `uvm_info("APB_SB",
              $sformatf("APB transaction: %s", tr.convert2string()),
              UVM_HIGH)


    // APB slave error

    if (tr.slverr !== 1'b0) begin

      apb_error_count++;
      fail_count++;

      `uvm_error("APB_SB",
                 $sformatf("APB %s FAIL address=0x%08h SLVERR=%b",
                           tr.we ? "WRITE" : "READ",
                           tr.addr, tr.slverr))
      return;

    end

    pass_count++;


    // ----------------------------------------------------------
    // TXD write: Register expected UART TX byte
    // ----------------------------------------------------------

    if (tr.we && tr.addr == ADDR_TXD) begin

      tx_expected_q.push_back(tr.data[7:0]);
      tx_expected_count++;

      `uvm_info("APB_SB",
                $sformatf("TX expected byte queued: 0x%02h",
                          tr.data[7:0]),
                UVM_MEDIUM)

      compare_tx_pending();

    end


    // ----------------------------------------------------------
    // RXD read: Compare received UART byte
    // ----------------------------------------------------------

    else if (!tr.we && tr.addr == ADDR_RXD) begin

      if (rx_received_q.size() == 0) begin

        fail_count++;

        `uvm_error("UART_SB",
                   $sformatf("RX FAIL: RXD read=0x%02h but no UART RX frame was observed",
                             tr.data[7:0]))

      end
      else begin

        expected = {24'h0, rx_received_q.pop_front()};
        rx_checked_count++;

        if (tr.data[7:0] === expected[7:0]) begin

          pass_count++;

          `uvm_info("UART_SB",
                    $sformatf("RX PASS expected=0x%02h got=0x%02h",
                              expected[7:0], tr.data[7:0]),
                    UVM_LOW)

        end
        else begin

          fail_count++;

          `uvm_error("UART_SB",
                     $sformatf("RX FAIL expected=0x%02h got=0x%02h",
                               expected[7:0], tr.data[7:0]))

        end

      end

    end


    // ----------------------------------------------------------
    // CTRL write
    // ----------------------------------------------------------

    else if (tr.we && tr.addr == ADDR_CTRL) begin

      ctrl_model = tr.data & CTRL_MASK;

    end


    // ----------------------------------------------------------
    // CFG write
    // ----------------------------------------------------------

    else if (tr.we && tr.addr == ADDR_CFG) begin

      cfg_model = tr.data & CFG_MASK;

    end


    // ----------------------------------------------------------
    // INTR write
    // ----------------------------------------------------------

    else if (tr.we && tr.addr == ADDR_INTR) begin

      intr_model = tr.data & INTR_MASK;

    end


    // ----------------------------------------------------------
    // Register readback
    // ----------------------------------------------------------

    else if (!tr.we) begin

      case (tr.addr)

        ADDR_CTRL: begin
          expected = ctrl_model;
          check_register(tr.addr, expected, tr.data, CTRL_MASK);
        end

        ADDR_CFG: begin
          expected = cfg_model;
          check_register(tr.addr, expected, tr.data, CFG_MASK);
        end

        ADDR_INTR: begin
          expected = intr_model;
          check_register(tr.addr, expected, tr.data, INTR_MASK);
        end

        default: begin
          // No register readback check.
        end

      endcase

    end

  endfunction : write_apb


  // ------------------------------------------------------------
  // Register comparison
  // ------------------------------------------------------------

  virtual function void check_register(
    bit [31:0] addr,
    bit [31:0] expected,
    bit [31:0] actual,
    bit [31:0] mask
  );

    register_checked_count++;

    if ((expected & mask) === (actual & mask)) begin

      pass_count++;

      `uvm_info("APB_SB",
                $sformatf("REGISTER PASS addr=0x%03h expected=0x%08h got=0x%08h",
                          addr, expected & mask, actual & mask),
                UVM_LOW)

    end
    else begin

      fail_count++;

      `uvm_error("APB_SB",
                 $sformatf("REGISTER FAIL addr=0x%03h expected=0x%08h got=0x%08h",
                           addr, expected & mask, actual & mask))

    end

  endfunction


  // ------------------------------------------------------------
  // UART TX monitor handler
  // ------------------------------------------------------------

  virtual function void write_uart_tx(uart_rsp_item tr);

    if (tr == null) begin
      fail_count++;
      `uvm_error("UART_SB", "Received null UART TX transaction")
      return;
    end

    tx_actual_q.push_back(tr.data);
    tx_framing_error_q.push_back(tr.frame_error);

    tx_observed_count++;

    `uvm_info("UART_SB",
              $sformatf("TX observed byte: 0x%02h framing_error=%0b",
                        tr.data, tr.frame_error),
              UVM_MEDIUM)

    compare_tx_pending();

  endfunction


  // ------------------------------------------------------------
  // UART RX monitor handler
  // ------------------------------------------------------------

  virtual function void write_uart_rx(uart_rsp_item tr);

    if (tr == null) begin
      fail_count++;
      `uvm_error("UART_SB", "Received null UART RX transaction")
      return;
    end

    rx_observed_count++;

    if (tr.frame_error !== 1'b0) begin

      fail_count++;

      `uvm_error("UART_SB",
                 $sformatf("RX framing error: data=0x%02h",
                           tr.data))

    end
    else begin

      rx_received_q.push_back(tr.data);

      `uvm_info("UART_SB",
                $sformatf("RX byte queued: 0x%02h",
                          tr.data),
                UVM_MEDIUM)

    end

  endfunction


  // ------------------------------------------------------------
  // TX comparison
  // ------------------------------------------------------------

  virtual function void compare_tx_pending();

    bit [7:0] expected;
    bit [7:0] actual;
    bit framing_error;

    // Compare ordered APB writes against UART TX frames.

    while ((tx_expected_q.size() != 0) &&
           (tx_actual_q.size() != 0)) begin

      expected      = tx_expected_q.pop_front();
      actual        = tx_actual_q.pop_front();
      framing_error = tx_framing_error_q.pop_front();

      tx_checked_count++;

      if ((expected === actual) &&
          (framing_error === 1'b0)) begin

        pass_count++;

        `uvm_info("UART_SB",
                  $sformatf("TX PASS expected=0x%02h got=0x%02h",
                            expected, actual),
                  UVM_LOW)

      end
      else begin

        fail_count++;

        `uvm_error("UART_SB",
                   $sformatf("TX FAIL expected=0x%02h got=0x%02h framing_error=%0b",
                             expected, actual, framing_error))

      end

    end

  endfunction


  // ------------------------------------------------------------
  // End-of-test checks
  // ------------------------------------------------------------

  virtual function void check_phase(uvm_phase phase);

    super.check_phase(phase);

    // Expected TX bytes without observed frames.

    while (tx_expected_q.size() != 0) begin

      fail_count++;

      `uvm_error("UART_SB",
                 $sformatf("TX FAIL expected=0x%02h got=<no frame>",
                           tx_expected_q.pop_front()))

    end


    // Observed TX frames without corresponding APB writes.

    while (tx_actual_q.size() != 0) begin

      fail_count++;

      `uvm_error("UART_SB",
                 $sformatf("TX FAIL expected=<no write> got=0x%02h framing_error=%0b",
                           tx_actual_q.pop_front(),
                           tx_framing_error_q.pop_front()))

    end


    // Received RX bytes never read through APB RXD.

    while (rx_received_q.size() != 0) begin

      fail_count++;

      `uvm_error("UART_SB",
                 $sformatf("RX FAIL byte=0x%02h was never read through RXD",
                           rx_received_q.pop_front()))

    end

  endfunction


  // ------------------------------------------------------------
  // Final scoreboard report
  // ------------------------------------------------------------

  virtual function void report_phase(uvm_phase phase);

    super.report_phase(phase);

    `uvm_info("UART_SB",
      $sformatf(
        "\n====================================================\n             APB UART SCOREBOARD SUMMARY\n====================================================\nTOTAL PASS COUNT       : %0d\nTOTAL FAIL COUNT       : %0d\nAPB transactions       : %0d\nAPB slave errors       : %0d\nRegister checks        : %0d\nTX expected bytes      : %0d\nTX observed frames     : %0d\nTX compared frames     : %0d\nRX observed frames     : %0d\nRX compared bytes      : %0d\n====================================================",
        pass_count,
        fail_count,
        apb_transaction_count,
        apb_error_count,
        register_checked_count,
        tx_expected_count,
        tx_observed_count,
        tx_checked_count,
        rx_observed_count,
        rx_checked_count
      ),
      UVM_NONE
    )

    if (fail_count == 0 && pass_count > 0) begin

      `uvm_info("UART_SB",
                "ALL SCOREBOARD CHECKS PASSED",
                UVM_NONE)

    end
    else begin

      `uvm_error("UART_SB",
                 "SCOREBOARD CHECKS FAILED")

    end

  endfunction

endclass : apb_uart_scbd

`endif