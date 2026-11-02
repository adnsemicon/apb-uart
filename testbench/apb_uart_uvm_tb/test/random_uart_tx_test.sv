`ifndef __GUARD_RANDOM_UART_TX_TEST_SV__
`define __GUARD_RANDOM_UART_TX_TEST_SV__ 0

class random_uart_tx_test extends apb_uart_base_test;

  `uvm_component_utils(random_uart_tx_test)

  function new(string name = "random_uart_tx_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_uart_init_seq  init_seq;
    random_uart_tx_seq uart_seq;

    phase.raise_objection(this);

    `uvm_info(get_type_name(), "Starting UART RX stimulus test", UVM_LOW)

    // Configure the DUT before sending UART frames.
    init_seq = apb_uart_init_seq::type_id::create("init_seq");

    init_seq.start(env.apb.sequencer);

    // Drive serial frames into DUT UART_RX.
    uart_seq = random_uart_tx_seq::type_id::create("uart_seq");

    uart_seq.start(env.rx.sequencer);

    `uvm_info(get_type_name(), "UART RX stimulus test completed", UVM_LOW)

    phase.drop_objection(this);
  endtask

endclass

`endif
