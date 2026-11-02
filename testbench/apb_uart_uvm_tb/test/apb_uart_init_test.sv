`ifndef __GUARD_APB_UART_INIT_TEST_SV__
`define __GUARD_APB_UART_INIT_TEST_SV__ 0

class apb_uart_init_test extends apb_uart_base_test;

  `uvm_component_utils(apb_uart_init_test)

  function new(string name = "apb_uart_init_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_uart_init_seq seq;

    phase.raise_objection(this);

    `uvm_info(get_type_name(), "Starting UART initialization test", UVM_LOW)

    seq = apb_uart_init_seq::type_id::create("seq");

    seq.start(env.apb.sequencer);

    `uvm_info(get_type_name(), "UART initialization sequence completed", UVM_LOW)

    phase.drop_objection(this);
  endtask

endclass

`endif
