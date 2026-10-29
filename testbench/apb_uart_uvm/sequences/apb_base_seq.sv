// Provide reusable APB read and write operations for derived sequences.
`ifndef __GUARD_APB_BASE_SEQ_SV__
`define __GUARD_APB_BASE_SEQ_SV__ 0

class apb_base_seq extends uvm_sequence #(apb_seq_item);

  `uvm_object_utils(apb_base_seq)

  function new(string name = "apb_base_seq");
    super.new(name);
  endfunction

  // APB Write Transaction
  task automatic apb_write(
    input bit [31:0] addr,
    input bit [31:0] data
  );

    apb_seq_item req;

    req = apb_seq_item::type_id::create("req");

    // Populate the request before handing it to the sequencer and driver.
    start_item(req);

    req.paddr  = addr;
    req.pwrite = 1'b1;
    req.pwdata = data;

    finish_item(req);

    if (req.pslverr)
      `uvm_error("APB_WRITE",
                 $sformatf("Write error at address 0x%08h", addr))

  endtask


  // APB Read Transaction
  task automatic apb_read(
    input  bit [31:0] addr,
    output bit [31:0] data
  );

    apb_seq_item req;

    req = apb_seq_item::type_id::create("req");

    // Read transfers clear write data and return the driver's captured PRDATA.
    start_item(req);

    req.paddr  = addr;
    req.pwrite = 1'b0;
    req.pwdata = '0;

    finish_item(req);

    data = req.prdata;

    if (req.pslverr)
      `uvm_error("APB_READ",
                 $sformatf("Read error at address 0x%08h", addr))

  endtask

endclass

`endif