`ifndef __GUARD_RANDOM_APB_WDATA_SEQ_SV__
`define __GUARD_RANDOM_APB_WDATA_SEQ_SV__ 0

`include "apb_uart_uvm_tb/sequence/apb_uart_base_seq.sv"

class random_apb_wdata_seq extends apb_uart_base_seq;

  `uvm_object_utils(random_apb_wdata_seq)

  int unsigned num_transactions;

  function new(string name = "random_apb_wdata_seq");
    super.new(name);
  endfunction

  virtual task body();

    logic [31:0] data;
    logic [5:0] addr;

    logic [5:0] writable_addrs[3] = '{
        6'h00,  // CTRL
        6'h04,  // CFG
        6'h30   // INTR
    };

    num_transactions = $urandom_range(10, 50);

    `uvm_info(get_type_name(), $sformatf("Starting random APB writes: %0d transactions",
                                         num_transactions), UVM_LOW)

    for (int unsigned i = 0; i < num_transactions; i++) begin

      addr = writable_addrs[$urandom_range(0, 2)];

      case (addr)

        6'h00: begin
          // CTRL: randomize only RX/TX enable bits [4:3].
          data = $urandom_range(0, 3) << 3;
        end
      
        6'h04: begin
          // CFG: randomize the documented configuration fields.
          data = $urandom() & 32'h001F_FFFF;
        end
      
        6'h30: begin
          // INTR: randomize the writable fields [3:0].
          data = $urandom_range(0, 15);
        end
      
        default: begin
          `uvm_error(
            get_type_name(),
            $sformatf("Unexpected writable address: 0x%02h", addr)
          )
          data = '0;
        end

      endcase

      `uvm_info(
          get_type_name(), $sformatf(
          "Write transaction %0d/%0d: addr=0x%02h data=0x%08h", i + 1, num_transactions, addr, data
          ), UVM_MEDIUM)

      apb_write(addr, data);

    end

    `uvm_info(get_type_name(), "Random APB writes completed", UVM_LOW)

  endtask : body

endclass : random_apb_wdata_seq

`endif
