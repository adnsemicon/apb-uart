// Verify the initialization sequence through control/configuration readback.
`ifndef __GUARD_APB_UART_INIT_TEST_SV__
`define __GUARD_APB_UART_INIT_TEST_SV__ 0

class apb_uart_init_test extends apb_uart_base_test;

    `uvm_component_utils(apb_uart_init_test)

    localparam bit [31:0] UART_CTRL_ADDR = 32'h00000000;
    localparam bit [31:0] UART_CFG_ADDR = 32'h00000004;
    localparam bit [31:0] UART_CFG_MASK = 32'h001F_FFFF;
    localparam bit [31:0] UART_ENABLED = 32'h00000018;

    function new(string name = "apb_uart_init_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_uart_init_seq init_seq;
        apb_access_seq read_seq;
        bit [31:0] read_data;
        int unsigned initial_pass_count;
        int unsigned initial_fail_count;

        phase.raise_objection(this);
        wait (env.apb.driver.vif.PRESETn === 1'b1);
        initial_pass_count = env.sb.pass_count;
        initial_fail_count = env.sb.fail_count;

        init_seq = apb_uart_init_seq::type_id::create("init_seq");
        init_seq.start(env.apb.sequencer);

        read_seq = apb_access_seq::type_id::create("read_ctrl_seq");
        read_seq.is_write = 1'b0;
        read_seq.addr = UART_CTRL_ADDR;
        read_seq.start(env.apb.sequencer);
        read_data = read_seq.read_data;
        if ((read_data & 32'h0000001F) !== UART_ENABLED) begin
            env.sb.fail_count++;
            `uvm_error(get_type_name(),
                       $sformatf("UART control readback mismatch: expected 0x%08h, got 0x%08h",
                                 UART_ENABLED, read_data))
        end else begin
            env.sb.pass_count++;
            `uvm_info(get_type_name(), "UART control readback PASS", UVM_LOW)
        end

        read_seq = apb_access_seq::type_id::create("read_cfg_seq");
        read_seq.is_write = 1'b0;
        read_seq.addr = UART_CFG_ADDR;
        read_seq.start(env.apb.sequencer);
        read_data = read_seq.read_data;
        if ((read_data & UART_CFG_MASK) !==
            (init_seq.cfg_value & UART_CFG_MASK)) begin
            env.sb.fail_count++;
            `uvm_error(get_type_name(),
                       $sformatf("UART configuration readback mismatch: expected 0x%08h, got 0x%08h",
                                 init_seq.cfg_value & UART_CFG_MASK, read_data & UART_CFG_MASK))
        end else begin
            env.sb.pass_count++;
            `uvm_info(get_type_name(), "UART configuration readback PASS", UVM_LOW)
        end

        `uvm_info(get_type_name(),
                  $sformatf("TEST COMPLETE: init checks PASS=%0d FAIL=%0d",
                            env.sb.pass_count - initial_pass_count,
                            env.sb.fail_count - initial_fail_count),
                  UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

`endif
