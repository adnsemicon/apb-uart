// Exercise the UART register map and check readable fields against masks.
`ifndef __GUARD_APB_UART_REG_TEST_SV__
`define __GUARD_APB_UART_REG_TEST_SV__ 0

class apb_uart_reg_test extends apb_uart_base_test;

    `uvm_component_utils(apb_uart_reg_test)

    localparam int unsigned REGISTER_COUNT = 12;
    localparam bit [31:0] UART_CTRL_ADDR = 32'h00000000;
    localparam bit [31:0] REGISTER_ADDRS [REGISTER_COUNT] = '{
        32'h00000000, 32'h00000004, 32'h00000008,
        32'h00000010, 32'h00000014, 32'h00000018,
        32'h0000001C, 32'h00000020, 32'h00000024,
        32'h00000028, 32'h0000002C, 32'h00000030
    };
    localparam bit [31:0] WRITE_VALUES [REGISTER_COUNT] = '{
        32'h00000008, 32'h00030010, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000,
        32'h000000A5, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000005
    };
    localparam bit [31:0] READ_VALUES [REGISTER_COUNT] = '{
        32'h00000000, 32'h00030010, 32'h00500000,
        32'h00000000, 32'h80000001, 32'h80000001,
        32'h00000000, 32'h00000000, 32'h80000001,
        32'h80000001, 32'h00000000, 32'h00000005
    };
    localparam bit [31:0] READ_MASKS [REGISTER_COUNT] = '{
        32'h0000001F, 32'h001FFFFF, 32'h00FFFFFF,
        32'hFFFFFFFF, 32'h800000FF, 32'h800000FF,
        32'hFFFFFFFF, 32'hFFFFFFFF, 32'h800000FF,
        32'h800000FF, 32'h00000000, 32'h0000000F
    };

    function new(string name = "apb_uart_reg_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task automatic access_register(
        input string sequence_name,
        input bit is_write,
        input bit [31:0] addr,
        input bit [31:0] data,
        input bit check_read = 1'b0,
        input bit [31:0] expected_data = '0,
        input bit [31:0] expected_mask = '1
    );
        apb_access_seq seq;

        if (!is_write && check_read)
            env.sb.expect_apb_read(addr, expected_data, expected_mask);

        seq = apb_access_seq::type_id::create(sequence_name);
        seq.is_write = is_write;
        seq.addr = addr;
        seq.data = data;
        seq.start(env.apb.sequencer);
    endtask

    virtual task run_phase(uvm_phase phase);
        int unsigned initial_tx_count;

        phase.raise_objection(this);
        `uvm_info(get_type_name(),
                  "TEST START: write and read all UART registers",
                  UVM_LOW)

        wait (env.apb.driver.vif.PRESETn === 1'b1);
        env.sb.enable_apb_transaction_counting();
        initial_tx_count = env.sb.tx_observed_count;

        foreach (REGISTER_ADDRS[i]) begin
            access_register($sformatf("write_reg_%0d", i), 1'b1,
                            REGISTER_ADDRS[i], WRITE_VALUES[i]);
        end

        fork : wait_for_tx_register_check
            begin
                wait (env.sb.tx_observed_count >= initial_tx_count + 1);
            end
            begin
                #50000;
            end
        join_any
        disable wait_for_tx_register_check;

        if (env.sb.tx_observed_count < initial_tx_count + 1)
            `uvm_error(get_type_name(),
                       "Timed out waiting for UART_TXD register test byte")

        access_register("disable_uart_tx", 1'b1, UART_CTRL_ADDR, '0);

        foreach (REGISTER_ADDRS[i]) begin
            access_register($sformatf("read_reg_%0d", i), 1'b0,
                            REGISTER_ADDRS[i], '0, 1'b1,
                            READ_VALUES[i], READ_MASKS[i]);
        end

        `uvm_info(get_type_name(),
                  "TEST COMPLETE: all UART registers were written and read",
                  UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

`endif
