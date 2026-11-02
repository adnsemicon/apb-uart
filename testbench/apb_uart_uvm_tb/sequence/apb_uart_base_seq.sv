`ifndef __GUARD_APB_UART_BASE_SEQ_SV__
`define __GUARD_APB_UART_BASE_SEQ_SV__ 0

`include "apb_uart_uvm_tb/obj/apb/apb_seq_item.sv"
`include "apb_uart_uvm_tb/obj/apb/apb_rsp_item.sv"

class apb_uart_base_seq extends uvm_sequence #(apb_seq_item, apb_rsp_item);

  `uvm_object_utils(apb_uart_base_seq)

  function new(string name = "apb_uart_base_seq");
    super.new(name);
  endfunction

  // ------------------------------------------------------------
  // APB WRITE
  // ------------------------------------------------------------

  virtual task apb_write(input logic [5:0] addr, input logic [31:0] data);

    apb_seq_item req;
    apb_rsp_item rsp;

    req = apb_seq_item::type_id::create("req");

    start_item(req);

    req.we   = 1'b1;
    req.addr = addr;
    req.data = data;

    finish_item(req);

    get_response(rsp);

    if (rsp.slverr !== 1'b0) begin
      `uvm_error(get_type_name(), $sformatf("APB WRITE error: addr=0x%02h data=0x%08h slverr=%b",
                                            addr, data, rsp.slverr))
    end

    `uvm_info(get_type_name(), $sformatf("APB WRITE: addr=0x%02h data=0x%08h", addr, data),
              UVM_MEDIUM)

  endtask : apb_write

  // ------------------------------------------------------------
  // APB READ
  // ------------------------------------------------------------

  virtual task apb_read(input logic [5:0] addr, output logic [31:0] data);

    apb_seq_item req;
    apb_rsp_item rsp;

    req = apb_seq_item::type_id::create("req");

    start_item(req);

    req.we   = 1'b0;
    req.addr = addr;
    req.data = '0;

    finish_item(req);

    get_response(rsp);

    data = rsp.data;

    if (rsp.slverr !== 1'b0) begin
      `uvm_error(get_type_name(), $sformatf("APB READ error: addr=0x%02h slverr=%b", addr,
                                            rsp.slverr))
    end

    `uvm_info(get_type_name(), $sformatf("APB READ: addr=0x%02h data=0x%08h", addr, data),
              UVM_MEDIUM)

  endtask : apb_read

endclass : apb_uart_base_seq

`endif
