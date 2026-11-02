`ifndef __GUARD_APB_DRIVER_SV__
`define __GUARD_APB_DRIVER_SV__ 0

`include "apb_uart_uvm_tb/obj/apb/apb_seq_item.sv"
`include "apb_uart_uvm_tb/obj/apb/apb_rsp_item.sv"

class apb_driver extends uvm_driver #(apb_seq_item, apb_rsp_item);

  `uvm_component_utils(apb_driver)

  virtual apb_if vif;

  function new(string name = "apb_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Could not retrieve APB virtual interface from config_db")
    end

    if (vif == null) begin
      `uvm_fatal(get_type_name(), "APB virtual interface handle is null after config_db get")
    end

    `uvm_info(get_type_name(), "APB virtual interface successfully configured", UVM_LOW)
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    apb_seq_item req;
    apb_rsp_item rsp;

    drive_idle();

    wait (vif.presetn === 1'b1);

    forever begin
      seq_item_port.get_next_item(req);

      `uvm_info(get_type_name(), $sformatf("Starting APB transaction: %s", req.to_string()),
                UVM_MEDIUM)

      rsp = apb_rsp_item::type_id::create("rsp");

      drive_transfer(req, rsp);

      rsp.set_id_info(req);
      seq_item_port.item_done(rsp);

      `uvm_info(get_type_name(), $sformatf("Completed APB transaction: %s", rsp.to_string()),
                UVM_MEDIUM)
    end

  endtask : run_phase

  virtual task drive_idle();
    @(negedge vif.pclk);

    vif.req.psel    = 1'b0;
    vif.req.penable = 1'b0;
    vif.req.paddr   = '0;
    vif.req.pprot   = '0;
    vif.req.pwrite  = 1'b0;
    vif.req.pwdata  = '0;
    vif.req.pstrb   = '0;

  endtask : drive_idle

  virtual task drive_transfer(input apb_seq_item req, input apb_rsp_item rsp);

    rsp.we     = req.we;
    rsp.addr   = req.addr;
    rsp.data   = '0;
    rsp.slverr = 1'b0;

    // APB setup phase.
    @(negedge vif.pclk);

    vif.req.psel    = 1'b1;
    vif.req.penable = 1'b0;
    vif.req.paddr   = req.addr;
    vif.req.pwrite  = req.we;
    vif.req.pwdata  = req.we ? req.data : '0;
    vif.req.pprot   = '0;
    vif.req.pstrb   = req.we ? '1 : '0;

    // APB access phase.
    @(negedge vif.pclk);
    vif.req.penable = 1'b1;

    // Wait for a completed access. Keep signals stable until PREADY.
    forever begin
      @(posedge vif.pclk);

      if (vif.req.psel === 1'b1 && vif.req.penable === 1'b1 && vif.rsp.pready === 1'b1) begin

        rsp.slverr = vif.rsp.pslverr;

        if (!req.we) rsp.data = vif.rsp.prdata;

        break;
      end
    end

    // Return to idle after the completion edge.
    @(negedge vif.pclk);

    vif.req.psel    = 1'b0;
    vif.req.penable = 1'b0;
    vif.req.pwrite  = 1'b0;
    vif.req.paddr   = '0;
    vif.req.pwdata  = '0;
    vif.req.pprot   = '0;
    vif.req.pstrb   = '0;

  endtask : drive_transfer

endclass : apb_driver

`endif
