`ifndef __GUARD_RANDOM_APB_RDATA_SEQ_SV__
`define __GUARD_RANDOM_APB_RDATA_SEQ_SV__ 0

`include "apb_uart_uvm_tb/sequence/apb_uart_base_seq.sv"

class random_apb_rdata_seq extends apb_uart_base_seq;

  `uvm_object_utils(random_apb_rdata_seq)

  rand int unsigned num_transactions;

  constraint num_transactions_c {num_transactions inside {[10 : 50]};}

  function new(string name = "random_apb_rdata_seq");
    super.new(name);
    num_transactions = 10;
  endfunction

  virtual task body();

    logic [31:0] rdata;
    logic [5:0] addr;

    logic [5:0] readable_addrs[8] = '{
        6'h00,  // CTRL
        6'h04,  // CFG
        6'h08,  // STATUS
        6'h14,  // TXGP
        6'h18,  // TXG
        6'h24,  // RXGP
        6'h28,  // RXG
        6'h30  // INTR
    };

    // Randomize the transaction count.
    if (!this.randomize()) begin
      `uvm_fatal(get_type_name(), "Failed to randomize transaction count")
    end

    // Validate the randomized result.
    if (num_transactions < 10 || num_transactions > 50) begin
      `uvm_fatal(get_type_name(), $sformatf("Invalid transaction count: %0d", num_transactions))
    end

    `uvm_info(get_type_name(), $sformatf("Starting random APB reads: %0d transactions",
                                         num_transactions), UVM_LOW)

    for (int unsigned i = 0; i < num_transactions; i++) begin

      addr = readable_addrs[$urandom_range(0, 7)];

      `uvm_info(get_type_name(), $sformatf(
                "Read transaction %0d/%0d: addr=0x%02h", i + 1, num_transactions, addr), UVM_MEDIUM)

      apb_read(addr, rdata);

    end

    `uvm_info(get_type_name(), $sformatf("Random APB reads completed: %0d transactions",
                                         num_transactions), UVM_LOW)

  endtask : body

endclass : random_apb_rdata_seq

`endif
