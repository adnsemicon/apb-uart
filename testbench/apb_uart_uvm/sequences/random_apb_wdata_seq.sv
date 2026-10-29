// Generate randomized APB writes to the UART transmit-data register.
`ifndef __GUARD_RANDOM_APB_WDATA_SEQ_SV__
`define __GUARD_RANDOM_APB_WDATA_SEQ_SV__ 0

class random_apb_wdata_seq extends apb_base_seq;

  `uvm_object_utils(random_apb_wdata_seq)

  function new(string name = "random_apb_wdata_seq");
    super.new(name);
  endfunction

  virtual task body();
    int seq_length;

    if (!uvm_config_db#(int)::get(
          uvm_root::get(), "parameter", "RANDOM_APB_WDATA_SEQ_LENGTH", seq_length
        ))
      seq_length = 1;

    // Write randomized byte values to UART_TXD, spacing consecutive frames apart.
    for (int i = 0; i < seq_length; i++) begin
      `uvm_do_with(req, {
        pwrite == 1;
        paddr == 32'h0000001C;
        pwdata inside {[32'h00000000:32'h000000FF]};
      })

      `uvm_info("APB_RANDOM_WRITE",
            $sformatf("Write address=0x%08h data=0x%08h",
              req.paddr, req.pwdata),
                UVM_MEDIUM)

      if (i + 1 < seq_length)
        #2000;
    end
  endtask : body

endclass : random_apb_wdata_seq

`endif