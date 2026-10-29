// Represent one UART byte and the framing parameters used to transmit it.
`ifndef __GUARD_UART_SEQ_ITEM_SV__
`define __GUARD_UART_SEQ_ITEM_SV__ 0

class uart_seq_item extends uvm_sequence_item;

  `uvm_object_utils(uart_seq_item)

  // UART transaction fields
  rand bit [7:0] data;
  rand bit [1:0] data_bits;
  rand bit       parity_en;
  rand bit       parity_type;
  rand bit       stop_bits;

  // Encode the number of data bits as 5 + data_bits (5 through 8 bits).
  constraint c_data_bits {
    data_bits inside {[0:3]};
  }

  // Constructor
  function new(string name = "uart_seq_item");
    super.new(name);
  endfunction

endclass

`endif