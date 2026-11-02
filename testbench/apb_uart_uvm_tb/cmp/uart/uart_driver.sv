`ifndef __GUARD_UART_DRIVER_SV__
`define __GUARD_UART_DRIVER_SV__ 0

`include "apb_uart_uvm_tb/obj/uart/uart_seq_item.sv"

class uart_driver extends uvm_driver #(uart_seq_item);

  `uvm_component_utils(uart_driver)

  virtual uart_if intf;

  function new(string name = "uart_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual uart_if)::get(this, "", "intf", intf)) begin
      `uvm_fatal("NOVIF", "UART virtual interface was not configured")
    end

    if (!uvm_config_db#(int)::get(this, "", "baud_rate", intf.baud_rate)) begin
      `uvm_info(get_type_name(), "UART baud rate not configured; using interface default", UVM_LOW)
    end

    if (!uvm_config_db#(int)::get(this, "", "data_bits", intf.data_bits)) begin
      `uvm_info(get_type_name(), "UART data bits not configured; using interface default", UVM_LOW)
    end

    if (!uvm_config_db#(bit)::get(this, "", "parity_en", intf.parity_en)) begin
      `uvm_info(get_type_name(), "UART parity enable not configured; using interface default", UVM_LOW)
    end

    if (!uvm_config_db#(bit)::get(this, "", "parity_type", intf.parity_type)) begin
      `uvm_info(get_type_name(), "UART parity type not configured; using interface default", UVM_LOW)
    end

    if (!uvm_config_db#(bit)::get(this, "", "extra_stop", intf.extra_stop)) begin
      `uvm_info(get_type_name(), "UART extra stop not configured; using interface default", UVM_LOW)
    end

  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    uart_seq_item req;

    forever begin
      seq_item_port.get_next_item(req);

      `uvm_info(get_type_name(), $sformatf("Driving UART transaction: %s", req.to_string()),
                UVM_MEDIUM)

      // Apply transaction configuration to the UART interface.
      intf.baud_rate   = req.baud_rate;
      intf.data_bits   = req.data_bits;
      intf.parity_en   = req.parity_en;
      intf.parity_type = req.parity_type;
      intf.extra_stop  = req.extra_stop;

      // Transmit the UART frame.
      intf.send(req.data);

      seq_item_port.item_done();
    end

  endtask : run_phase

endclass : uart_driver

`endif
