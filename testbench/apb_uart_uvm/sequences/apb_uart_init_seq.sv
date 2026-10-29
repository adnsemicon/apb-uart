// Program the UART control and configuration registers to the startup mode.
`ifndef __GUARD_APB_UART_INIT_SEQ_SV__
`define __GUARD_APB_UART_INIT_SEQ_SV__ 0

class apb_uart_init_seq extends apb_base_seq;

  `uvm_object_utils(apb_uart_init_seq)

  localparam bit [31:0] UART_CTRL_ADDR = 32'h00000000;
  localparam bit [31:0] UART_CFG_ADDR = 32'h00000004;

  bit [31:0] cfg_value = 32'h0003405B;

  function new(string name = "apb_uart_init_seq");
    super.new(name);
  endfunction

  virtual task body();
    // Release/reset the UART, program its framing configuration, then enable it.
    apb_write(UART_CTRL_ADDR, 32'h00000001);
    apb_write(UART_CFG_ADDR, cfg_value);
    apb_write(UART_CTRL_ADDR, 32'h00000018);
  endtask

endclass

`endif
