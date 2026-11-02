`ifndef __GUARD_APB_UART_BASE_TEST_SV__
`define __GUARD_APB_UART_BASE_TEST_SV__ 0

class apb_uart_base_test extends uvm_test;

  `uvm_component_utils(apb_uart_base_test)

  apb_uart_env env;

  function new(string name = "apb_uart_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // ------------------------------------------------------------
  // BUILD PHASE
  // ------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = apb_uart_env::type_id::create("env", this);

    `uvm_info(get_type_name(), "APB UART base test build phase", UVM_LOW)
  endfunction

  // ------------------------------------------------------------
  // END OF ELABORATION
  // ------------------------------------------------------------
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);

    `uvm_info(get_type_name(), "APB UART testbench elaboration completed", UVM_LOW)

    uvm_top.print_topology();
  endfunction

  // ------------------------------------------------------------
  // RUN PHASE
  // ------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);

    apb_uart_init_seq init_seq;

    phase.raise_objection(this, "APB UART base test started");

    `uvm_info(get_type_name(), "RUN PHASE STARTED", UVM_NONE)

    // Wait for reset to be released.
    //
    // This assumes ctrl_intf.PRESETn is accessible through the
    // virtual interface configured in your environment.
    //
    // If your environment does not expose ctrl_intf directly,
    // use the reset synchronization mechanism implemented by
    // your environment or testbench.

    #1us;

    `uvm_info(get_type_name(), "Starting APB UART initialization sequence", UVM_NONE)

    // Create and start the initialization sequence.
    init_seq = apb_uart_init_seq::type_id::create("init_seq");

    if (env.apb == null) begin
      `uvm_fatal(get_type_name(), "APB agent handle is null")
    end

    if (env.apb.sequencer == null) begin
      `uvm_fatal(get_type_name(), "APB sequencer handle is null")
    end

    init_seq.start(env.apb.sequencer);

    `uvm_info(get_type_name(), "APB UART initialization sequence completed", UVM_NONE)

    // Allow pending monitor and scoreboard activity to complete.
    #1us;

    `uvm_info(get_type_name(), "RUN PHASE COMPLETED", UVM_NONE)

    phase.drop_objection(this, "APB UART base test completed");

  endtask

endclass

`endif
