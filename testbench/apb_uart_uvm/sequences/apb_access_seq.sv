// Execute one configurable APB read or write and retain its response data.
`ifndef __GUARD_APB_ACCESS_SEQ_SV__
`define __GUARD_APB_ACCESS_SEQ_SV__ 0

class apb_access_seq extends apb_base_seq;

  `uvm_object_utils(apb_access_seq)

  rand bit is_write;
  rand bit [31:0] addr;
  rand bit [31:0] data;
  bit [31:0] read_data;

  function new(string name = "apb_access_seq");
    super.new(name);
  endfunction

  virtual task body();
    apb_seq_item req;

    // Use a single item for either direction; reads drive zero on write data.
    req = apb_seq_item::type_id::create("req");
    start_item(req);
    req.paddr = addr;
    req.pwrite = is_write;
    req.pwdata = is_write ? data : 32'h00000000;
    finish_item(req);

    read_data = req.prdata;

    // Report bus errors and log the value relevant to the selected direction.
    if (req.pslverr)
      `uvm_error("APB_ACCESS",
                 $sformatf("APB %s error at address 0x%08h",
                           is_write ? "write" : "read", addr))

    `uvm_info("APB_ACCESS",
              $sformatf("%s address=0x%08h data=0x%08h",
                        is_write ? "Write" : "Read",
                        addr, is_write ? data : read_data),
              UVM_MEDIUM)
  endtask

endclass

`endif