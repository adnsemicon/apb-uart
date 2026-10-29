// Include guard to prevent multiple inclusions of this file
`ifndef __GUARD_RANDOM_UART_TX_SEQ_SV__
`define __GUARD_RANDOM_UART_TX_SEQ_SV__ 0

// Random UART TX Sequence
// This sequence generates random UART transmit (TX) transactions.
// The sequence length can be configured via the "RANDOM_UART_TX_SEQ_LENGTH" parameter.
class random_uart_tx_seq extends uvm_sequence #(uart_seq_item);

  // UVM object utilities for factory registration
  `uvm_object_utils(random_uart_tx_seq)

  // Constructor for the random UART TX sequence
  function new(string name = "random_uart_tx_seq");
    super.new(name);
  endfunction : new

  // Main sequence body: generates TX transactions
  virtual task body();
    int seq_length;

    // Get sequence length from configuration database, default to 1
    if (!uvm_config_db#(int)::get(
            uvm_root::get(), "parameter", "RANDOM_UART_TX_SEQ_LENGTH", seq_length
        ))
      seq_length = 1;

    // Each item randomizes its data and frame settings using the item constraints.
    // Repeat for the specified sequence length
    repeat (seq_length) begin
      // Generate a random UART TX transaction
      `uvm_do(req)
    end
  endtask : body

endclass

`endif
