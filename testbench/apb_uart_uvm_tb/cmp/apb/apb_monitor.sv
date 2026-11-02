`ifndef __GUARD_APB_MONITOR_SV__
`define __GUARD_APB_MONITOR_SV__ 0

`include "apb_uart_uvm_tb/obj/apb/apb_rsp_item.sv"

class apb_monitor extends uvm_monitor;

  `uvm_component_utils(apb_monitor)

  virtual apb_if vif;

  uvm_analysis_port #(apb_rsp_item) ap;

  function new(string name = "apb_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "APB virtual interface was not configured")
    end

  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    apb_rsp_item tr;

    forever begin
      @(posedge vif.pclk);

      if (vif.presetn !== 1'b1) continue;

      if ((vif.req.psel === 1'b1) && (vif.req.penable === 1'b1) && (vif.rsp.pready === 1'b1)) begin

        tr        = apb_rsp_item::type_id::create("tr");

        tr.we     = vif.req.pwrite;
        tr.addr   = vif.req.paddr;
        tr.slverr = vif.rsp.pslverr;

        if (vif.req.pwrite === 1'b1) tr.data = vif.req.pwdata;
        else tr.data = vif.rsp.prdata;

        `uvm_info(get_type_name(), $sformatf("Observed APB transaction: %s", tr.to_string()),
                  UVM_MEDIUM)

        ap.write(tr);
      end
    end

  endtask : run_phase

endclass : apb_monitor

`endif
