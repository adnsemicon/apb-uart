// Observe completed APB transfers and publish transaction items to analysis ports.
`ifndef __GUARD_APB_MONITOR_SV__
`define __GUARD_APB_MONITOR_SV__ 0

class apb_monitor extends uvm_component;
  `uvm_component_utils(apb_monitor)
  virtual apb_uart_if vif;
  uvm_analysis_port #(apb_seq_item) ap;

  function new(string name="apb_monitor", uvm_component parent=null);
    super.new(name,parent); 
    ap=new("ap",this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_uart_if)::get(this,"","vif",vif))
      `uvm_fatal("NOVIF","apb_monitor: virtual interface not set")
  endfunction

  task run_phase(uvm_phase phase);
    apb_seq_item tr;
    forever begin
      @(posedge vif.PCLK);
      // Sample only the handshake cycle, so wait states do not create duplicates.
      if (vif.PRESETn && vif.psel && vif.penable && vif.pready) begin
        tr=apb_seq_item::type_id::create("tr");
        tr.paddr=vif.paddr; tr.pwrite=vif.pwrite; tr.pwdata=vif.pwdata;
        tr.prdata=vif.prdata; tr.pslverr=vif.pslverr;
        ap.write(tr);
      end
    end
  endtask
  
endclass

`endif