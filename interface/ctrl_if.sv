interface ctrl_if;

    logic PCLK;
    logic PRESETn;

    bit clock_running = 0;

    // Default clock period: 10 ns = 100 MHz.
    time clock_period = 10ns;

    // ------------------------------------------------------------
    // Initialize control signals
    // ------------------------------------------------------------

    initial begin
        PCLK   = 1'b0;
        PRESETn = 1'b0;
    end

    // ------------------------------------------------------------
    // Start clock
    // ------------------------------------------------------------

    task automatic start_clock(
        input real frequency_mhz = 100.0
    );

        if (frequency_mhz <= 0.0) begin
            $fatal(
                1,
                "[CTRL_IF] Invalid clock frequency: %0f MHz",
                frequency_mhz
            );
        end

        clock_period = (1000.0 / frequency_mhz) * 1ns;

        if (clock_running) begin
            $display(
                "[CTRL_IF] Clock is already running"
            );
            return;
        end

        clock_running = 1'b1;

        fork
            begin
                forever begin
                    #(clock_period / 2);
                    PCLK = ~PCLK;
                end
            end
        join_none

    endtask

    // ------------------------------------------------------------
    // Apply active-low reset
    // ------------------------------------------------------------

    task automatic apply_reset(
        input int unsigned reset_cycles = 5
    );

        PRESETn = 1'b0;

        repeat (reset_cycles) begin
            @(posedge PCLK);
        end

        @(negedge PCLK);
        PRESETn = 1'b1;

        $display(
            "[CTRL_IF] Reset released at time %0t",
            $time
        );

    endtask

endinterface
