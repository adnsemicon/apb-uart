// Check the UART configuration reset value and run randomized APB reads.
`ifndef __GUARD_APB_UART_READ_TEST_SV__
`define __GUARD_APB_UART_READ_TEST_SV__ 0

class apb_uart_read_test extends apb_uart_base_test;

    `uvm_component_utils(apb_uart_read_test)

    function new(string name = "apb_uart_read_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        localparam int unsigned EXPECTED_APB_READS = 25;
        localparam bit [31:0] UART_CFG_ADDR = 32'h00000004;
        localparam bit [31:0] UART_CFG_RESET = 32'h0003405B;
        apb_access_seq read_seq;
        apb_random_seq random_read_seq;
        int unsigned initial_read_count;

        phase.raise_objection(this);

        `uvm_info(get_type_name(),
                  "TEST START: read the UART configuration register over APB",
                  UVM_LOW)

        `uvm_info(get_type_name(),
                  $sformatf("STEP 1: read register=UART_CFG address=0x%08h (expected reset value=0x%08h)",
                            UART_CFG_ADDR, UART_CFG_RESET),
                  UVM_LOW)

        read_seq = apb_access_seq::type_id::create("read_seq");
        read_seq.is_write = 1'b0;
        read_seq.addr = UART_CFG_ADDR;
        read_seq.start(env.apb.sequencer);

        `uvm_info(get_type_name(),
                  $sformatf("RESULT: register=UART_CFG address=0x%08h read_data=0x%08h expected=0x%08h",
                            UART_CFG_ADDR, read_seq.read_data, UART_CFG_RESET),
                  UVM_LOW)

        if (read_seq.read_data !== UART_CFG_RESET)
            `uvm_error(get_type_name(),
                       $sformatf("UART_CFG reset value mismatch: expected 0x%08h, got 0x%08h",
                                 UART_CFG_RESET, read_seq.read_data))

        `uvm_info(get_type_name(),
                  $sformatf("STEP 2: perform %0d randomized APB reads",
                            EXPECTED_APB_READS),
                  UVM_LOW)

        env.sb.enable_apb_read_counting();
        initial_read_count = env.sb.apb_transactions_checked;
        uvm_config_db#(int)::set(uvm_root::get(), "parameter",
                                 "RANDOM_APB_SEQ_LENGTH", EXPECTED_APB_READS);
        random_read_seq = apb_random_seq::type_id::create("random_read_seq");
        random_read_seq.start(env.apb.sequencer);

        fork : wait_for_apb_reads
            begin
                wait (env.sb.apb_transactions_checked >=
                      initial_read_count + EXPECTED_APB_READS);
            end
            begin
                #40000;
            end
        join_any
        disable wait_for_apb_reads;

        if (env.sb.apb_transactions_checked <
            initial_read_count + EXPECTED_APB_READS)
            `uvm_error(get_type_name(),
                       $sformatf("Timed out waiting for APB reads: expected=%0d completed=%0d",
                                 EXPECTED_APB_READS,
                                 env.sb.apb_transactions_checked - initial_read_count))

        `uvm_info(get_type_name(),
                  $sformatf("TEST COMPLETE: APB reads completed: %0d/%0d",
                            env.sb.apb_transactions_checked - initial_read_count,
                            EXPECTED_APB_READS),
                  UVM_LOW)

        phase.drop_objection(this);
    endtask

endclass

`endif