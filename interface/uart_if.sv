interface uart_if;

  // ------------------------------------------------------------
  // UART serial pin
  // Connect tx_o to tx and rx_i to rx at the testbench top.
  // ------------------------------------------------------------

  tri line;

  // ------------------------------------------------------------
  // UART configuration
  // ------------------------------------------------------------

  int unsigned baud_rate = 115200;
  int unsigned data_bits = 8;
  bit parity_en = 0;
  bit parity_type = 0;
  bit extra_stop = 0;

  // ------------------------------------------------------------
  // Initialize UART signals
  // ------------------------------------------------------------

  bit register;

  assign (highz1, strong0) line = register;

  // ------------------------------------------------------------
  // Reset serial pins
  // ------------------------------------------------------------

  task automatic apply_reset();
    register = 1'b1;
  endtask

  task automatic send(input logic [7:0] data);

    realtime bt;
    bit parity_bit;

    if (baud_rate == 0) begin
      $error("[UART_IF] Invalid baud rate: %0d", baud_rate);
      return;
    end

    bt = 1s / baud_rate;

    if (data_bits < 5 || data_bits > 8) begin
      $error("[UART_IF] Unsupported data width: %0d", data_bits);
      return;
    end

    // Start bit.
    register <= 1'b0;
    #(bt);

    // Data bits, LSB first.
    for (int i = 0; i < data_bits; i++) begin
      register <= data[i];
      #(bt);
    end

    // Optional parity bit.
    if (parity_en) begin
      parity_bit = 1'b0;

      for (int i = 0; i < data_bits; i++) begin
        parity_bit ^= data[i];
      end

      // Even parity: XOR of the configured data bits.
      // Odd parity: invert the even parity bit.
      if (parity_type) parity_bit = ~parity_bit;

      register <= parity_bit;
      #(bt);
    end

    // Stop bit.
    for (int i = 0; i <= extra_stop; i++) begin
      register <= 1'b1;
      #(bt);
    end

  endtask

  // ------------------------------------------------------------
  // UART receive task
  //
  // Samples near the center of each bit.
  // Returns the received data and whether the frame was valid.
  // ------------------------------------------------------------

  task automatic recv(output logic [7:0] data, output bit frame_error);

    realtime bt;
    bit parity_bit;
    bit expected_parity;

    data        = '0;
    frame_error = 1'b0;

    if (baud_rate == 0) begin
      $error("[UART_IF] Invalid baud rate: %0d", baud_rate);
      frame_error = 1'b1;
      return;
    end

    bt = 1s / baud_rate;

    if (data_bits < 5 || data_bits > 8) begin
      $error("[UART_IF] Unsupported data width: %0d", data_bits);
      frame_error = 1'b1;
      return;
    end

    // --------------------------------------------------------
    // Detect start bit
    // --------------------------------------------------------

    @(negedge line);

    // Confirm start bit at its center.
    #(bt / 2);

    if (line !== 1'b0) begin
      frame_error = 1'b1;
      return;
    end

    // --------------------------------------------------------
    // Sample data bits at their centers
    // --------------------------------------------------------

    for (int i = 0; i < data_bits; i++) begin
      #(bt);
      data[i] = line;
    end

    // --------------------------------------------------------
    // Sample parity bit
    // --------------------------------------------------------

    if (parity_en) begin
      #(bt);
      parity_bit = line;
      expected_parity = 1'b0;

      for (int i = 0; i < data_bits; i++) begin
        expected_parity ^= data[i];
      end

      if (parity_type) expected_parity = ~expected_parity;
      if (parity_bit !== expected_parity) frame_error = 1'b1;
    end

    // --------------------------------------------------------
    // Sample stop bit at its center
    // --------------------------------------------------------

    for (int i = 0; i <= extra_stop; i++) begin
      #(bt);
      if (line !== 1'b1) frame_error = 1'b1;
    end

  endtask

  // ------------------------------------------------------------
  // Wait until the transmitter is idle
  // ------------------------------------------------------------

  task automatic wait_till_idle(input int unsigned timeout_bits = 100);

    realtime bt;
    int unsigned cycles;

    if (baud_rate == 0ns) begin
      $error("[UART_IF] Cannot wait for idle with baud_rate=0");
      return;
    end

    bt = 1s / baud_rate;
    cycles = 0;

    while (line !== 1'b1) begin
      #(bt);
      cycles++;

      if (cycles >= timeout_bits) begin
        $error("[UART_IF] Timeout waiting for TX idle");
        return;
      end
    end

  endtask

endinterface
