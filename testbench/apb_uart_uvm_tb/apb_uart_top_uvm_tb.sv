`ifndef __GUARD_APB_UART_TOP_UVM_TB_SV__
`define __GUARD_APB_UART_TOP_UVM_TB_SV__ 0

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "uart_reg_if_pkg.sv"

// ------------------------------------------------------------
// Transaction objects
// ------------------------------------------------------------
`include "apb_uart_uvm_tb/obj/apb/apb_seq_item.sv"
`include "apb_uart_uvm_tb/obj/apb/apb_rsp_item.sv"
`include "apb_uart_uvm_tb/obj/uart/uart_seq_item.sv"
`include "apb_uart_uvm_tb/obj/uart/uart_rsp_item.sv"

// ------------------------------------------------------------
// Sequences
// ------------------------------------------------------------
`include "apb_uart_uvm_tb/sequence/apb_uart_base_seq.sv"
`include "apb_uart_uvm_tb/sequence/all_reg_access_seq.sv"
`include "apb_uart_uvm_tb/sequence/apb_uart_init_seq.sv"
`include "apb_uart_uvm_tb/sequence/random_apb_rdata_seq.sv"
`include "apb_uart_uvm_tb/sequence/random_apb_wdata_seq.sv"
`include "apb_uart_uvm_tb/sequence/random_uart_tx_seq.sv"
`include "apb_uart_uvm_tb/sequence/random_uart_rx_seq.sv"

// ------------------------------------------------------------
// APB agent
// ------------------------------------------------------------
`include "apb_uart_uvm_tb/cmp/apb/apb_sequencer.sv"
`include "apb_uart_uvm_tb/cmp/apb/apb_agent.sv"

// ------------------------------------------------------------
// UART agents
// ------------------------------------------------------------
`include "apb_uart_uvm_tb/cmp/uart/uart_driver.sv"
`include "apb_uart_uvm_tb/cmp/uart/uart_monitor.sv"
`include "apb_uart_uvm_tb/cmp/uart/uart_agent.sv"

// ------------------------------------------------------------
// Environment and scoreboard
// ------------------------------------------------------------
`include "apb_uart_uvm_tb/cmp/apb_uart_scbd.sv"
`include "apb_uart_uvm_tb/cmp/apb_uart_env.sv"

// ------------------------------------------------------------
// Tests
// ------------------------------------------------------------
`include "apb_uart_uvm_tb/test/apb_uart_base_test.sv"
`include "apb_uart_uvm_tb/test/all_reg_access_test.sv"
`include "apb_uart_uvm_tb/test/apb_uart_init_test.sv"
`include "apb_uart_uvm_tb/test/random_apb_rdata_test.sv"
`include "apb_uart_uvm_tb/test/random_apb_wdata_test.sv"
`include "apb_uart_uvm_tb/test/random_uart_tx_test.sv"
`include "apb_uart_uvm_tb/test/random_uart_rx_test.sv"

module apb_uart_top_uvm_tb;

  // Use the standard UART bit rate expected by the interface/default sequences.
  // The DUT divider is configured as {prescaler=4, clk_div=0x05B}; with a 100 MHz
  // APB clock this yields the common 115200 baud rate used by the UART helper code.
  localparam int UART_BAUD = 108695;
  localparam int PARITY_EN = 0;
  localparam int PARITY_TYPE = 0;
  localparam int EXTRA_STOP = 0;
  localparam int DATA_BITS = 8;

  // ------------------------------------------------------------
  // Control interface
  // ------------------------------------------------------------
  ctrl_if ctrl_intf ();

  // ------------------------------------------------------------
  // APB interface
  // ------------------------------------------------------------
  apb_if apb_intf (
      .pclk   (ctrl_intf.PCLK),
      .presetn(ctrl_intf.PRESETn)
  );

  // ------------------------------------------------------------
  // UART interfaces
  //
  // tx_intf: DUT UART_TX -> testbench monitor
  // rx_intf: testbench driver -> DUT UART_RX
  // ------------------------------------------------------------
  uart_if tx_intf ();
  uart_if rx_intf ();

  // Interrupt output from the DUT.
  logic uart_intr;

  // ------------------------------------------------------------
  // DUT
  // ------------------------------------------------------------
  apb_uart_top #(
      .ADDR_WIDTH(32),
      .DATA_WIDTH(32),
      .FIFO_SIZE (4)
  ) DUT (
      // Clock and reset
      .PCLK   (ctrl_intf.PCLK),
      .PRESETn(ctrl_intf.PRESETn),

      // APB request and response structures
      .apb_req_i (apb_intf.req),
      .apb_resp_o(apb_intf.rsp),

      // UART serial interface
      .UART_TX(tx_intf.rx),
      .UART_RX(rx_intf.tx),

      // Interrupt output
      .UART_IRQ(uart_intr)
  );


  // ------------------------------------------------------------
  // Start clock and release reset independently of run_test().
  // ------------------------------------------------------------
  initial begin : clock_reset_start
    ctrl_intf.start_clock(100.0);
    ctrl_intf.apply_reset(5);
  end

  // ------------------------------------------------------------
  // UVM configuration and test launch
  // ------------------------------------------------------------
  initial begin : uvm_test_start

    string test_name;

    $timeformat(-9, 0, "ns");

    $dumpfile("apb_uart_top_uvm_tb.vcd");
    $dumpvars(0, apb_uart_top_uvm_tb);

    // Virtual interfaces.
    //
    // These paths assume apb_uart_env creates components named
    // apb, tx, and rx, as shown in apb_uart_env.sv.
    uvm_config_db#(virtual ctrl_if)::set(uvm_root::get(), "*.env.ctrl.*", "vif", ctrl_intf);

    // APB agent itself
    uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top.env.apb", "vif", apb_intf);

    // APB agent's driver and monitor
    uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top.env.apb.*", "vif", apb_intf);

    uvm_config_db#(virtual uart_if)::set(uvm_root::get(), "*.env.tx.*", "intf", tx_intf);

    uvm_config_db#(virtual uart_if)::set(uvm_root::get(), "*.env.rx.*", "intf", rx_intf);

    // UART TX agent configuration.
    uvm_config_db#(int)::set(uvm_root::get(), "*.env.tx.*", "baud_rate", UART_BAUD);

    uvm_config_db#(int)::set(uvm_root::get(), "*.env.tx.*", "parity_en", PARITY_EN);

    uvm_config_db#(int)::set(uvm_root::get(), "*.env.tx.*", "parity_type", PARITY_TYPE);

    uvm_config_db#(int)::set(uvm_root::get(), "*.env.tx.*", "extra_stop", EXTRA_STOP);

    uvm_config_db#(int)::set(uvm_root::get(), "*.env.tx.*", "data_bits", DATA_BITS);

    // UART RX agent configuration.
    uvm_config_db#(int)::set(uvm_root::get(), "*.env.rx.*", "baud_rate", UART_BAUD);

    uvm_config_db#(int)::set(uvm_root::get(), "*.env.rx.*", "parity_en", PARITY_EN);

    uvm_config_db#(int)::set(uvm_root::get(), "*.env.rx.*", "parity_type", PARITY_TYPE);

    uvm_config_db#(int)::set(uvm_root::get(), "*.env.rx.*", "extra_stop", EXTRA_STOP);

    uvm_config_db#(int)::set(uvm_root::get(), "*.env.rx.*", "data_bits", DATA_BITS);

    // General baud-rate configuration, if used by sequences.
    uvm_config_db#(int)::set(uvm_root::get(), "*", "baud_rate", UART_BAUD);

    // Choose the test.
    // The project passes `TN=<test_name>` through xsim, so honor that first.
    if ($value$plusargs("TN=%s", test_name) && (test_name != "default")) begin

      run_test(test_name);

    end else if ($value$plusargs("UVM_TESTNAME=%s", test_name)) begin

      run_test(test_name);

    end else if ($value$plusargs("CLI_TEST_NAME=%s", test_name) && (test_name != "default")) begin

      run_test(test_name);

    end else begin

      run_test("apb_uart_base_test");

    end

  end

  initial begin : debug_uart_tx
    wait (ctrl_intf.PRESETn === 1'b1);

    $display("[TX DEBUG] Reset released at %0t; UART_TX=%b", $time, tx_intf.rx);

    forever begin
      @(tx_intf.rx);
      $display("[TX DEBUG] UART_TX changed to %b at %0t", tx_intf.rx, $time);
    end
  end

endmodule

`endif
