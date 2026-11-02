`ifndef __GUARD_ALL_REG_ACCESS_TEST_SV__
`define __GUARD_ALL_REG_ACCESS_TEST_SV__ 0

class all_reg_access_test extends apb_uart_base_test;

  `uvm_component_utils(all_reg_access_test)

  function new(string name = "all_reg_access_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_uart_init_seq init_seq;
    all_reg_access_seq seq;

    phase.raise_objection(this);

    `uvm_info(get_type_name(), "Starting register access test", UVM_LOW)

    init_seq = apb_uart_init_seq::type_id::create("init_seq");
    init_seq.start(env.apb.sequencer);

    seq = all_reg_access_seq::type_id::create("seq");
    seq.start(env.apb.sequencer);

    `uvm_info(get_type_name(), "Register access sequence completed; waiting for UART TX", UVM_LOW)

    // Temporary wait: allow the 8N1 UART frame to finish.
    #100us;

    `uvm_info(get_type_name(), "UART TX wait completed", UVM_LOW)

    phase.drop_objection(this);
  endtask

endclass

`endif
