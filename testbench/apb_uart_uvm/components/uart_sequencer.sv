// Arbitrate UART frame items from sequences for the UART driver.
`ifndef __GUARD_UART_SEQUENCER_SV__
`define __GUARD_UART_SEQUENCER_SV__ 0

class uart_sequencer extends uvm_sequencer #(uart_seq_item);
  `uvm_component_utils(uart_sequencer)

  // Arbitrate UART frame items before they are sent by the active agent's driver.
  function new(string name="uart_sequencer", uvm_component parent=null);
    super.new(name,parent);
  endfunction
endclass

`endif