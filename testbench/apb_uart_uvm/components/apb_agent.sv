// Bundle the APB sequencer, driver, and monitor into one configurable agent.
`ifndef __GUARD_APB_AGENT_SV__
`define __GUARD_APB_AGENT_SV__ 0

class apb_agent extends uvm_agent;
  `uvm_component_utils(apb_agent)
  apb_sequencer sequencer;
  apb_driver driver;
  apb_monitor mon;
  function new(string name="apb_agent", uvm_component parent=null);
    super.new(name,parent);
  endfunction
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon=apb_monitor::type_id::create("mon",this);
    // Passive agents observe only; active agents also create stimulus components.
    if (get_is_active()==UVM_ACTIVE) begin
      sequencer=apb_sequencer::type_id::create("sequencer",this);
      driver=apb_driver::type_id::create("driver",this);
    end
  endfunction
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Route sequence items from the sequencer to the driver in active mode.
    if (get_is_active()==UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass

`endif