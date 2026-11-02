`ifndef __GUARD_APB_SEQ_ITEM_SV__
`define __GUARD_APB_SEQ_ITEM_SV__ 0

// Import UVM package.
import uvm_pkg::*;

// Include UVM macros.
`include "uvm_macros.svh"

import uart_reg_if_pkg::ADDR_CTRL;
import uart_reg_if_pkg::ADDR_CFG;
import uart_reg_if_pkg::ADDR_STATUS;
import uart_reg_if_pkg::ADDR_TXR;
import uart_reg_if_pkg::ADDR_TXGP;
import uart_reg_if_pkg::ADDR_TXG;
import uart_reg_if_pkg::ADDR_TXD;
import uart_reg_if_pkg::ADDR_RXR;
import uart_reg_if_pkg::ADDR_RXGP;
import uart_reg_if_pkg::ADDR_RXG;
import uart_reg_if_pkg::ADDR_RXD;
import uart_reg_if_pkg::ADDR_INTR;

class apb_seq_item extends uvm_sequence_item;

  rand logic        we;
  rand logic [11:0] addr;
  rand logic [31:0] data;

  bit               allow_random_addr = 0;
  bit               allow_random_data = 0;

  `uvm_object_utils_begin(apb_seq_item)
    `uvm_field_int(we, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(allow_random_addr, UVM_ALL_ON)
    `uvm_field_int(allow_random_data, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "apb_seq_item");
    super.new(name);
  endfunction

  // ------------------------------------------------------------
  // Address constraints
  //
  // Writable:
  //   CTRL, CFG, TXR, TXD, RXR, INTR
  //
  // Readable:
  //   CTRL, CFG, STATUS, TXGP, TXG, RXGP, RXG, RXD, INTR
  // ------------------------------------------------------------

  constraint addr_c {
    if (!allow_random_addr) {
      if (we) {
        addr inside {ADDR_CTRL, ADDR_CFG, ADDR_TXR, ADDR_TXD, ADDR_RXR, ADDR_INTR};
      } else {
        addr inside {
          ADDR_CTRL,
          ADDR_CFG,
          ADDR_STATUS,
          ADDR_TXGP,
          ADDR_TXG,
          ADDR_RXGP,
          ADDR_RXG,
          ADDR_RXD,
          ADDR_INTR
        };
      }
    }
  }

  // ------------------------------------------------------------
  // Mask unused bits when random data is disabled.
  //
  // This preserves the style of your previous testbench.
  // ------------------------------------------------------------

  function void post_randomize();

    if (!allow_random_data) begin

      case (addr)

        ADDR_CTRL: begin
          data[31:5] = '0;
        end

        ADDR_CFG: begin
          data[31:21] = '0;
        end

        ADDR_TXR, ADDR_RXR: begin
          data[31:8] = '0;
        end

        ADDR_TXD: begin
          data[31:8] = '0;
        end

        ADDR_INTR: begin
          data[31:4] = '0;
        end

        default: begin
          // No additional masking.
        end

      endcase

    end

  endfunction

  virtual function string to_string();
    return $sformatf("we=%0b addr=0x%02h data=0x%08h", we, addr, data);
  endfunction

  virtual function void display();
    $display("%s", to_string());
  endfunction

endclass : apb_seq_item

`endif
