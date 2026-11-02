`ifndef __GUARD_APB_AGENT_SV__
`define __GUARD_APB_AGENT_SV__ 0

class apb_agent extends uvm_agent;

  `uvm_component_utils(apb_agent)

  apb_sequencer sequencer;
  apb_driver    driver;
  apb_monitor   monitor;

  virtual apb_if vif;

  function new(string name = "apb_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "APB virtual interface was not configured")
    end

    monitor = apb_monitor::type_id::create("monitor", this);

    if (get_is_active() == UVM_ACTIVE) begin
      sequencer = apb_sequencer::type_id::create("sequencer", this);
      driver    = apb_driver::type_id::create("driver", this);
    end

  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (get_is_active() == UVM_ACTIVE) driver.seq_item_port.connect(sequencer.seq_item_export);

  endfunction : connect_phase

endclass : apb_agent

`endif
