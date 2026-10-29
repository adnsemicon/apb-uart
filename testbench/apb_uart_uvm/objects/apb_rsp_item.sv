// Represent an APB response with returned data and slave-error status.
`ifndef __GUARD_APB_RSP_ITEM_SV__
`define __GUARD_APB_RSP_ITEM_SV__ 0

class apb_rsp_item extends uvm_sequence_item;

  `uvm_object_utils(apb_rsp_item)

  // APB response
  bit [31:0] prdata;
  bit        pslverr;
  // Indicates whether the responder completed the APB access.
  bit        pready;

  // Constructor
  function new(string name = "apb_rsp_item");
    super.new(name);
  endfunction

endclass

`endif
