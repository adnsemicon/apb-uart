// Assemble both protocol agents and the scoreboard for the UART environment.
`ifndef __GUARD_APB_UART_ENV_SV__
`define __GUARD_APB_UART_ENV_SV__ 0

class apb_uart_env extends uvm_env;
  `uvm_component_utils(apb_uart_env)
  apb_agent apb;
  uart_agent uart;
  apb_uart_scoreboard sb;

  function new(string name="apb_uart_env", uvm_component parent=null);
    super.new(name,parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Keep bus agents and checking logic under one reusable environment.
    apb=apb_agent::type_id::create("apb",this);
    uart=uart_agent::type_id::create("uart",this);
    sb=apb_uart_scoreboard::type_id::create("sb",this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Feed both protocol monitors into the scoreboard's analysis inputs.
    uart.mon.ap.connect(sb.uart_imp);
    apb.mon.ap.connect(sb.apb_imp);
  endfunction
endclass

`endif