// Bundle the UART sequencer, stimulus driver, and receive monitor.
`ifndef __GUARD_UART_AGENT_SV__
`define __GUARD_UART_AGENT_SV__ 0

class uart_agent extends uvm_agent;
  `uvm_component_utils(uart_agent)

  uart_sequencer sequencer;
  uart_driver driver;
  uart_monitor mon;

  function new(string name="uart_agent", uvm_component parent=null);
    super.new(name,parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon=uart_monitor::type_id::create("mon",this);
    // Passive agents monitor UART output only; active agents also drive RX stimulus.
    if (get_is_active()==UVM_ACTIVE) begin
      sequencer=uart_sequencer::type_id::create("sequencer",this);
      driver=uart_driver::type_id::create("driver",this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Connect sequence-generated frames to the serial-line driver.
    if (get_is_active()==UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass

`endif
