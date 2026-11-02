`ifndef __GUARD_UART_AGENT_SV__
`define __GUARD_UART_AGENT_SV__ 0

`include "apb_uart_uvm_tb/obj/uart/uart_seq_item.sv"
`include "apb_uart_uvm_tb/obj/uart/uart_rsp_item.sv"
`include "apb_uart_uvm_tb/cmp/uart/uart_driver.sv"
`include "apb_uart_uvm_tb/cmp/uart/uart_monitor.sv"

class uart_agent extends uvm_agent;

  `uvm_component_utils(uart_agent)

  uvm_sequencer #(uart_seq_item)     sequencer;
  uart_driver                        driver;
  uart_monitor                       monitor;

  uvm_analysis_port #(uart_rsp_item) ap;

  function new(string name = "uart_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    ap      = new("ap", this);
    monitor = uart_monitor::type_id::create("monitor", this);

    if (get_is_active() == UVM_ACTIVE) begin
      sequencer = uvm_sequencer#(uart_seq_item)::type_id::create("sequencer", this);

      driver = uart_driver::type_id::create("driver", this);
    end

  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    monitor.ap.connect(ap);

    if (get_is_active() == UVM_ACTIVE) driver.seq_item_port.connect(sequencer.seq_item_export);

  endfunction : connect_phase

endclass : uart_agent

`endif
