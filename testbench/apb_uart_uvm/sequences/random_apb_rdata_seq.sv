// Generate randomized APB reads constrained to supported UART registers.
`ifndef __GUARD_RANDOM_APB_RDATA_SEQ_SV__
`define __GUARD_RANDOM_APB_RDATA_SEQ_SV__ 0

class apb_random_seq extends apb_base_seq;

  `uvm_object_utils(apb_random_seq)

  function new(string name = "apb_random_seq");
    super.new(name);
  endfunction

  virtual task body();

    apb_seq_item req;
    int seq_length;

    if (!uvm_config_db#(int)::get(
          uvm_root::get(), "parameter", "RANDOM_APB_SEQ_LENGTH", seq_length
        ))
      seq_length = 20;

    // Constrain randomized reads to known register addresses and clear write data.
    repeat (seq_length) begin

      req = apb_seq_item::type_id::create("req");

      start_item(req);

      if (!req.randomize() with {
        pwrite == 1'b0;
        pwdata == 32'h00000000;
        paddr inside {
          32'h0000_0000,
          32'h0000_0004,
          32'h0000_0008,
          32'h0000_001C,
          32'h0000_002C,
          32'h0000_0030
        };
      }) begin

        `uvm_fatal("RAND_FAIL",
                   "APB transaction randomization failed")

      end

      finish_item(req);

      `uvm_info("APB_RANDOM_READ",
            $sformatf("Read address=0x%08h data=0x%08h",
              req.paddr, req.prdata),
            UVM_MEDIUM)

      if (req.pslverr) begin

        `uvm_warning("APB_RANDOM",
                     $sformatf(
                       "APB error at address 0x%08h",
                       req.paddr
                     ))

      end

    end

  endtask

endclass

`endif