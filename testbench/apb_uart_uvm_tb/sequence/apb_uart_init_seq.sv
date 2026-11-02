`ifndef __GUARD_APB_UART_INIT_SEQ_SV__
`define __GUARD_APB_UART_INIT_SEQ_SV__ 0

`include "apb_uart_uvm_tb/sequence/apb_uart_base_seq.sv"

class apb_uart_init_seq extends apb_uart_base_seq;

  `uvm_object_utils(apb_uart_init_seq)

  function new(string name = "apb_uart_init_seq");
    super.new(name);
  endfunction

  virtual task body();

    logic [31:0] rdata;

    `uvm_info(get_type_name(), "Starting UART initialization", UVM_LOW)

    // Disable UART TX and RX.
    apb_write(6'h00, 32'h00000000);

    // Configure:
    // data_bits = 3  -> 8-bit mode
    // prescaler = 4
    // clk_div   = 0x05B
    apb_write(6'h04, 32'h0003405B);

    // Clear interrupt configuration.
    apb_write(6'h30, 32'h00000000);

    // Enable RX and TX.
    // CTRL[4] = rx_en
    // CTRL[3] = tx_en
    apb_write(6'h00, 32'h00000018);

    // Verify CTRL.
    apb_read(6'h00, rdata);

    if (rdata[4:3] !== 2'b11) begin
      `uvm_error(get_type_name(), $sformatf("CTRL enable check failed: 0x%08h", rdata))
    end

    // Verify CFG.
    apb_read(6'h04, rdata);

    if (rdata !== 32'h0003405B) begin
      `uvm_error(get_type_name(), $sformatf("CFG mismatch: got 0x%08h expected 0x0003405B", rdata))
    end

    `uvm_info(get_type_name(), "UART initialization completed", UVM_LOW)

  endtask : body

endclass : apb_uart_init_seq

`endif
