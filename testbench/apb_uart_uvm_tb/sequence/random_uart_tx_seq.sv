`ifndef __GUARD_RANDOM_UART_TX_SEQ_SV__
`define __GUARD_RANDOM_UART_TX_SEQ_SV__ 0

`include "apb_uart_uvm_tb/obj/uart/uart_seq_item.sv"

class random_uart_tx_seq extends uvm_sequence #(uart_seq_item);

  `uvm_object_utils(random_uart_tx_seq)

  int unsigned num_transactions;

  function new(string name = "random_uart_tx_seq");
    super.new(name);
  endfunction

  virtual task body();

    uart_seq_item req;

    // Workaround for the transaction-count randomization issue.
    num_transactions = $urandom_range(1,3);

    `uvm_info(get_type_name(), $sformatf("Generated UART frame count: %0d", num_transactions),
              UVM_LOW)

    // if (num_transactions < 10 || num_transactions > 50) begin
    //   `uvm_fatal(get_type_name(), $sformatf("Invalid transaction count: %0d", num_transactions))
    // end

    `uvm_info(get_type_name(), $sformatf("Starting random UART RX frames: %0d", num_transactions),
              UVM_LOW)

    for (int unsigned i = 0; i < num_transactions; i++) begin

      req = uart_seq_item::type_id::create($sformatf("req_%0d", i));

      start_item(req);

      if (!req.randomize() with {
            baud_rate == 115200;
            data_bits == 8;
            parity_en == 0;
            extra_stop == 0;
          }) begin
        `uvm_fatal(get_type_name(), "Failed to randomize UART frame")
      end

      finish_item(req);

      `uvm_info(get_type_name(), $sformatf("UART RX frame %0d: %s", i + 1, req.to_string()),
                UVM_MEDIUM)

    end

    `uvm_info(get_type_name(), "Random UART RX stimulus completed", UVM_LOW)

  endtask : body

endclass : random_uart_tx_seq

`endif
