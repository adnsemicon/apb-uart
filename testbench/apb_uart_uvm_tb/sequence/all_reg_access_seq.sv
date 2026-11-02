`ifndef __GUARD_ALL_REG_ACCESS_SEQ_SV__
`define __GUARD_ALL_REG_ACCESS_SEQ_SV__ 0

`include "apb_uart_uvm_tb/sequence/apb_uart_base_seq.sv"

class all_reg_access_seq extends apb_uart_base_seq;

  `uvm_object_utils(all_reg_access_seq)

  function new(string name = "all_reg_access_seq");
    super.new(name);
  endfunction

  virtual task body();

    logic [31:0] rdata;

    `uvm_info(get_type_name(), "Starting all-register access sequence", UVM_LOW)

    // CTRL: RW
    apb_write(6'h00, 32'h00000000);
    apb_read(6'h00, rdata);

    // CFG: RW
    apb_write(6'h04, 32'h0003405B);
    apb_read(6'h04, rdata);

    // STATUS: RO
    apb_read(6'h08, rdata);

    // TXR: WO. The VALID bit must be set to enqueue a request.
    apb_write(6'h10, 32'h80000001);
    apb_write(6'h20, 32'h80000001);

    // TXGP: RO
    apb_read(6'h14, rdata);

    // TXG: RO
    apb_read(6'h18, rdata);

    // CTRL: Enable RX and TX, then verify the enable bits.
    apb_write(6'h00, 32'h00000018);
    apb_read(6'h00, rdata);

    // Skip TXD in this access-only smoke test: writing TXD creates a UART TX
    // expectation in the scoreboard, but this test does not provide a monitored
    // serial TX path to observe the emitted frame.

    // RXR: WO. The VALID bit must be set to enqueue a request.
    apb_write(6'h20, 32'h80000001);

    // RXGP: RO
    apb_read(6'h24, rdata);

    // RXG: RO
    apb_read(6'h28, rdata);

    // RXD: RO
    // Skip the RXD data comparison here: no UART RX frame has been sent.

    // INTR: RW
    apb_write(6'h30, 32'h00000005);
    apb_read(6'h30, rdata);

    `uvm_info(get_type_name(), "All-register access sequence completed", UVM_LOW)

  endtask : body

endclass : all_reg_access_seq

`endif
