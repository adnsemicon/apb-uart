`ifndef __GUARD_UART_MONITOR_SV__
`define __GUARD_UART_MONITOR_SV__ 0

`include "apb_uart_uvm_tb/obj/uart/uart_rsp_item.sv"

class uart_monitor extends uvm_monitor;

  `uvm_component_utils(uart_monitor)

  virtual uart_if intf;

  uvm_analysis_port #(uart_rsp_item) ap;


  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------

  function new(string name = "uart_monitor", uvm_component parent = null);

    super.new(name, parent);
    ap = new("ap", this);

  endfunction : new


  // ------------------------------------------------------------
  // Build phase
  // ------------------------------------------------------------

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

      `uvm_info(get_type_name(), "UART parity enable not configured; using interface default",
                UVM_LOW)

    end


    if (!uvm_config_db#(bit)::get(this, "", "parity_type", intf.parity_type)) begin

      `uvm_info(get_type_name(), "UART parity type not configured; using interface default",
                UVM_LOW)

    end


    if (!uvm_config_db#(bit)::get(this, "", "extra_stop", intf.extra_stop)) begin

      `uvm_info(get_type_name(), "UART extra stop not configured; using interface default", UVM_LOW)

    end

  endfunction : build_phase


  // ------------------------------------------------------------
  // Run phase
  // ------------------------------------------------------------

  virtual task run_phase(uvm_phase phase);

    uart_rsp_item item;
    bit frame_error;

    `uvm_info(get_type_name(),
              $sformatf(
                  "UART monitor started: baud_rate=%0d data_bits=%0d parity_en=%0b extra_stop=%0b",
                  intf.baud_rate, intf.data_bits, intf.parity_en, intf.extra_stop), UVM_LOW)


    forever begin

      item = uart_rsp_item::type_id::create("item");

      frame_error = 1'b0;

      `uvm_info(get_type_name(), $sformatf("Waiting for UART start edge at %0t", $time), UVM_MEDIUM)


      // Decode the UART frame.
      intf.recv(item.data, frame_error);


      // --------------------------------------------------------
      // Copy monitor configuration into the transaction.
      // --------------------------------------------------------

      item.baud_rate   = intf.baud_rate;
      item.parity_en   = intf.parity_en;
      item.parity_type = intf.parity_type;
      item.extra_stop  = intf.extra_stop;
      item.data_bits   = intf.data_bits;


      // IMPORTANT:
      // Store the result so the scoreboard can inspect it.
      item.frame_error = frame_error;


      `uvm_info(get_type_name(), $sformatf(
                "UART frame decoded at %0t: data=0x%02h frame_error=%0b",
                $time,
                item.data,
                item.frame_error
                ), UVM_MEDIUM)


      // --------------------------------------------------------
      // Report invalid frames.
      // --------------------------------------------------------

      if (item.frame_error) begin

        `uvm_error("UART_FRAME", $sformatf("Invalid UART frame: data=0x%02h time=%0t", item.data,
                                           $time))

      end else begin

        `uvm_info(get_type_name(), $sformatf("Valid UART frame: %s", item.to_string()), UVM_MEDIUM)

      end


      // --------------------------------------------------------
      // Publish BOTH valid and invalid frames.
      //
      // The scoreboard checks frame_error and determines whether
      // the transaction passes or fails.
      // --------------------------------------------------------

      ap.write(item);

    end

  endtask : run_phase

endclass : uart_monitor

`endif
