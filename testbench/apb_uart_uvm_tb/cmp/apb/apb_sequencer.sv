`ifndef __GUARD_APB_SEQUENCER_SV__
`define __GUARD_APB_SEQUENCER_SV__ 0

`include "apb_uart_uvm_tb/obj/apb/apb_seq_item.sv"
`include "apb_uart_uvm_tb/obj/apb/apb_rsp_item.sv"

class apb_sequencer extends uvm_sequencer #(
apb_seq_item,
apb_rsp_item
);

`uvm_component_utils(apb_sequencer)

function new(
string name = "apb_sequencer",
uvm_component parent = null
);
super.new(name, parent);
endfunction : new

endclass : apb_sequencer

`endif