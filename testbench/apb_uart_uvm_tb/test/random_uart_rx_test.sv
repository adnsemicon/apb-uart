`ifndef __GUARD_RANDOM_UART_RX_TEST_SV__
`define __GUARD_RANDOM_UART_RX_TEST_SV__ 0

class random_uart_rx_test extends apb_uart_base_test;

  `uvm_component_utils(random_uart_rx_test)

  function new(string name = "random_uart_rx_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_uart_init_seq init_seq;
    random_uart_rx_seq uart_seq;
    time tx_window;

    phase.raise_objection(this);

    init_seq = apb_uart_init_seq::type_id::create("init_seq");
    init_seq.start(env.apb.sequencer);

    uart_seq = random_uart_rx_seq::type_id::create("uart_seq");
    uart_seq.start(env.apb.sequencer);

    tx_window = uart_seq.num_transactions * 10 * (1s / 108695) + 10us; // must match the real DUT UART baud
    #(tx_window);

    `uvm_info(get_type_name(), "UART TX observation window completed", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass

`endif
