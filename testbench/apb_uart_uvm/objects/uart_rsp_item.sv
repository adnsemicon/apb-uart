// Carry one decoded UART byte and its framing-error indication.
`ifndef __GUARD_UART_RSP_ITEM_SV__
`define __GUARD_UART_RSP_ITEM_SV__ 0

class uart_rsp_item extends uvm_sequence_item;

  `uvm_object_utils(uart_rsp_item)

  // Received UART data
  bit [7:0] data;

  // Error/status information
  // The current monitor reports framing status; parity is reserved for parity-aware decoding.
  bit parity_error;
  bit framing_error;

  // Constructor
  function new(string name = "uart_rsp_item");
    super.new(name);
  endfunction

endclass

`endif