// Inject randomized UART frames and verify the received bytes over APB.
`ifndef __GUARD_APB_UART_RX_TEST_SV__
`define __GUARD_APB_UART_RX_TEST_SV__ 0

class apb_uart_rx_test extends apb_uart_base_test;

    `uvm_component_utils(apb_uart_rx_test)

    function new(string name = "apb_uart_rx_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        localparam int unsigned RX_BYTE_COUNT = 15;
        localparam bit [31:0] UART_CTRL_ADDR = 32'h00000000;
        localparam bit [31:0] UART_CFG_ADDR = 32'h00000004;
        localparam bit [31:0] UART_STAT_ADDR = 32'h00000008;
        localparam bit [31:0] UART_RXD_ADDR = 32'h0000002C;
        localparam bit [31:0] UART_RX_COUNT_MASK = 32'h000FFC00;
        apb_access_seq apb_seq;
        random_uart_rx_seq seq;
        bit [7:0] expected_byte;
        int unsigned observed_byte_count;

        phase.raise_objection(this);

        `uvm_info(get_type_name(),
                  $sformatf("TEST START: UART RX test; inject and verify %0d randomized bytes using 8-N-1 framing",
                            RX_BYTE_COUNT),
                  UVM_LOW)

        wait (env.apb.driver.vif.PRESETn === 1'b1);

        apb_seq = apb_access_seq::type_id::create("reset_seq");
        apb_seq.is_write = 1'b1;
        apb_seq.addr = UART_CTRL_ADDR;
        apb_seq.data = 32'h00000001;
        apb_seq.start(env.apb.sequencer);

        apb_seq = apb_access_seq::type_id::create("cfg_seq");
        apb_seq.is_write = 1'b1;
        apb_seq.addr = UART_CFG_ADDR;
        apb_seq.data = 32'h00030002;
        apb_seq.start(env.apb.sequencer);

        apb_seq = apb_access_seq::type_id::create("enable_seq");
        apb_seq.is_write = 1'b1;
        apb_seq.addr = UART_CTRL_ADDR;
        apb_seq.data = 32'h00000010;
        apb_seq.start(env.apb.sequencer);

        uvm_config_db#(int)::set(uvm_root::get(), "parameter",
                                 "RANDOM_UART_RX_SEQ_LENGTH", RX_BYTE_COUNT);
        seq = random_uart_rx_seq::type_id::create("rx_seq");
        seq.start(env.uart.sequencer);

        apb_seq = apb_access_seq::type_id::create("status_seq");
        apb_seq.is_write = 1'b0;
        apb_seq.addr = UART_STAT_ADDR;
        apb_seq.start(env.apb.sequencer);

        observed_byte_count = (apb_seq.read_data & UART_RX_COUNT_MASK) >> 10;
        if (observed_byte_count != RX_BYTE_COUNT) begin
            env.sb.fail_count++;
            `uvm_error("UART_RX_SB",
                       $sformatf("RX BYTE COUNT FAIL: expected %0d bytes, observed %0d",
                                 RX_BYTE_COUNT, observed_byte_count))
        end

        for (int unsigned i = 0; i < RX_BYTE_COUNT; i++) begin
            expected_byte = 8'hxx;
            if (i < seq.driven_data.size())
                expected_byte = seq.driven_data[i];

            apb_seq = apb_access_seq::type_id::create(
                $sformatf("read_rx_byte_%0d", i)
            );
            apb_seq.is_write = 1'b0;
            apb_seq.addr = UART_RXD_ADDR;
            apb_seq.start(env.apb.sequencer);

            if (apb_seq.read_data[7:0] == expected_byte) begin
                env.sb.pass_count++;
                `uvm_info("UART_RX_SB",
                          $sformatf("RX BYTE PASS: byte %0d expected=0x%02h received=0x%02h",
                                    i + 1, expected_byte,
                                    apb_seq.read_data[7:0]),
                          UVM_LOW)
            end else begin
                env.sb.fail_count++;
                `uvm_error("UART_RX_SB",
                           $sformatf("RX BYTE FAIL: byte %0d expected=0x%02h received=0x%02h",
                                     i + 1, expected_byte,
                                     apb_seq.read_data[7:0]))
            end
        end

        `uvm_info(get_type_name(),
                  $sformatf("TEST COMPLETE: UART RX received %0d/%0d bytes",
                            observed_byte_count, RX_BYTE_COUNT),
                  UVM_LOW)

        phase.drop_objection(this);
    endtask

endclass

`endif
