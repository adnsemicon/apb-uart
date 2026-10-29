// Send randomized APB writes to UART_TXD and verify each resulting UART frame.
`ifndef __GUARD_APB_UART_WRITE_TEST_SV__
`define __GUARD_APB_UART_WRITE_TEST_SV__ 0

class apb_uart_write_test extends apb_uart_base_test;

    `uvm_component_utils(apb_uart_write_test)

    function new(string name = "apb_uart_write_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        localparam int unsigned EXPECTED_TX_FRAMES = 21;
        apb_access_seq cfg_seq;
        apb_access_seq ctrl_seq;
        apb_access_seq ctrl_read_seq;
        random_apb_wdata_seq write_seq;

        phase.raise_objection(this);

        `uvm_info(get_type_name(),
                  "TEST START: 20 randomized APB writes to UART_TXD",
                  UVM_LOW)

            wait (env.apb.driver.vif.PRESETn === 1'b1);

        uvm_config_db#(int)::set(uvm_root::get(), "parameter",
                                 "RANDOM_APB_WDATA_SEQ_LENGTH", 21);

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

        ctrl_read_seq = apb_access_seq::type_id::create("ctrl_read_seq");
        ctrl_read_seq.is_write = 1'b0;
        ctrl_read_seq.addr = 32'h00000000;
        ctrl_read_seq.start(env.apb.sequencer);
        if (!ctrl_read_seq.read_data[3])
            `uvm_fatal(get_type_name(), "UART TX enable did not latch")

        write_seq = random_apb_wdata_seq::type_id::create("write_seq");
        write_seq.start(env.apb.sequencer);

        fork : wait_for_tx_checks
            begin
                wait (env.sb.pass_count + env.sb.fail_count >= EXPECTED_TX_FRAMES);
            end
            begin
                #40000;
            end
        join_any
        disable wait_for_tx_checks;

        if (env.sb.pass_count + env.sb.fail_count < EXPECTED_TX_FRAMES)
            `uvm_error(get_type_name(),
                       $sformatf("Timed out waiting for TX checks: expected=%0d completed=%0d",
                                 EXPECTED_TX_FRAMES,
                                 env.sb.pass_count + env.sb.fail_count))

        `uvm_info(get_type_name(),
                  "TEST COMPLETE: randomized APB UART_TXD writes finished",
                  UVM_LOW)

        phase.drop_objection(this);
    endtask

endclass

`endif