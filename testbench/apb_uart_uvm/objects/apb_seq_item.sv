// Carry APB request fields and the response captured by the driver.
`ifndef __GUARD_APB_SEQ_ITEM_SV__
`define __GUARD_APB_SEQ_ITEM_SV__ 0

class apb_seq_item extends uvm_sequence_item;

  `uvm_object_utils(apb_seq_item)

  // APB transaction fields
  rand bit [31:0] paddr;
  rand bit        pwrite;
  rand bit [31:0] pwdata;

  // Response fields
  bit [31:0] prdata;
  bit        pslverr;

  // APB word accesses must be aligned to a four-byte boundary.
  constraint c_addr_aligned {
    paddr[1:0] == 2'b00;
  }

  // Constructor
  function new(string name = "apb_seq_item");
    super.new(name);
  endfunction

endclass

`endif