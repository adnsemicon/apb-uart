interface ctrl_if;

  logic PCLK;
  logic PRESETn;

  bit clock_running = 0;

  // Default clock period: 10 ns = 100 MHz.
  realtime clock_period = 10ns;

  // ------------------------------------------------------------
  // Start clock
  // ------------------------------------------------------------

  task automatic start_clock(input real frequency_mhz = 100.0);

    if (frequency_mhz <= 0.0) begin
      $fatal(1, "[CTRL_IF] Invalid clock frequency: %0f MHz", frequency_mhz);
    end

    clock_period = 1us / frequency_mhz;

    if (clock_running) begin
      $display("[CTRL_IF] Clock is already running with period %0t", clock_period);
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

  task automatic apply_reset(input realtime duration = 100ns, input realtime post_reset = duration,
                             input realtime pre_reset = post_reset);
    #(pre_reset);
    PRESETn <= 1'b0;
    PCLK    <= 1'b0;
    #(duration);
    PRESETn <= 1'b1;
    #(post_reset);
  endtask

endinterface
