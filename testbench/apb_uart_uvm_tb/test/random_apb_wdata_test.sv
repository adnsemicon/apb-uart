`ifndef __GUARD_RANDOM_APB_WDATA_TEST_SV__
`define __GUARD_RANDOM_APB_WDATA_TEST_SV__ 0

class random_apb_wdata_test extends apb_uart_base_test;

  `uvm_component_utils(random_apb_wdata_test)

  function new(string name = "random_apb_wdata_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    random_apb_wdata_seq seq;

    phase.raise_objection(this);

    `uvm_info(get_type_name(), "Starting randomized APB write test", UVM_LOW)

    seq = random_apb_wdata_seq::type_id::create("seq");

    seq.start(env.apb.sequencer);

    `uvm_info(get_type_name(), "Randomized APB write sequence completed", UVM_LOW)

    phase.drop_objection(this);
  endtask

endclass

`endif
