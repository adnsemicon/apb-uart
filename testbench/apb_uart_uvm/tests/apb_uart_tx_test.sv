// Program UART transmit settings and verify serialized output frames.
`ifndef __GUARD_APB_UART_TX_TEST_SV__
`define __GUARD_APB_UART_TX_TEST_SV__ 0

class apb_uart_tx_test extends apb_uart_base_test;

    `uvm_component_utils(apb_uart_tx_test)

    function new(string name = "apb_uart_tx_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        localparam int unsigned TX_FRAME_COUNT = 12;
        apb_access_seq cfg_seq;
        apb_access_seq ctrl_seq;
        random_apb_wdata_seq seq;
        int unsigned initial_pass_count;
        int unsigned initial_fail_count;

        phase.raise_objection(this);

        `uvm_info(get_type_name(),
                  "TEST START: UART TX test; write and verify 10 randomized bytes",
                  UVM_LOW)

        wait (env.apb.driver.vif.PRESETn === 1'b1);

        cfg_seq = apb_access_seq::type_id::create("cfg_seq");
        cfg_seq.is_write = 1'b1;
        cfg_seq.addr = 32'h00000004;
        cfg_seq.data = 32'h00030010;
        cfg_seq.start(env.apb.sequencer);

        ctrl_seq = apb_access_seq::type_id::create("ctrl_seq");
        ctrl_seq.is_write = 1'b1;
        ctrl_seq.addr = 32'h00000000;
        ctrl_seq.data = 32'h00000008;
        ctrl_seq.start(env.apb.sequencer);

        uvm_config_db#(int)::set(uvm_root::get(), "parameter",
                     "RANDOM_APB_WDATA_SEQ_LENGTH", TX_FRAME_COUNT);
        initial_pass_count = env.sb.pass_count;
        initial_fail_count = env.sb.fail_count;

        seq = random_apb_wdata_seq::type_id::create("seq");

        seq.start(env.apb.sequencer);

        `uvm_info(get_type_name(),
              "STEP 1 COMPLETE: randomized APB writes to UART_TXD finished",
                  UVM_LOW)

        fork : wait_for_tx_check
            begin
                wait (env.sb.pass_count - initial_pass_count +
                      env.sb.fail_count - initial_fail_count >= TX_FRAME_COUNT);
            end
            begin
                #50000;
            end
        join_any
        disable wait_for_tx_check;

        if (env.sb.pass_count - initial_pass_count +
            env.sb.fail_count - initial_fail_count < TX_FRAME_COUNT)
            `uvm_error(get_type_name(),
                       "Timed out waiting for all UART TX scoreboard checks")

        `uvm_info(get_type_name(),
                  $sformatf("TEST COMPLETE: UART TX verified pass count: %0d/%0d",
                            env.sb.pass_count - initial_pass_count,
                            TX_FRAME_COUNT),
                  UVM_LOW)

        phase.drop_objection(this);
    endtask

endclass

`endif