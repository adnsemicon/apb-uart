interface uart_if;

  // ------------------------------------------------------------
  // UART serial pin
  //
  // Connect tx_o to tx and rx_i to rx at the testbench top.
  // ------------------------------------------------------------

  logic tx;
  logic rx;

  // ------------------------------------------------------------
  // UART configuration
  // ------------------------------------------------------------

  int unsigned baud_rate = 115200;
  int unsigned data_bits = 8;

  bit parity_en = 0;
  bit parity_type = 0;
  bit extra_stop = 0;

  // ------------------------------------------------------------
  // Derived timing
  // ------------------------------------------------------------

  function automatic time bit_period();

    if (baud_rate == 0) return 0ns;

    return 1s / baud_rate;

  endfunction

  // ------------------------------------------------------------
  // Initialize UART signals
  // ------------------------------------------------------------

  initial begin
    tx = 1'b1;
    rx = 1'b1;
  end

  // ------------------------------------------------------------
  // Reset serial pins
  // ------------------------------------------------------------

  task automatic apply_reset();

    tx = 1'b1;
    rx = 1'b1;

  endtask

  // ------------------------------------------------------------
  // UART transmit task
  //
  // Frame:
  //   Start bit: 0
  //   Data bits: LSB first
  //   Optional parity
  //   Stop bit(s): 1
  //
  // parity_type:
  //   0 = even parity
  //   1 = odd parity
  // ------------------------------------------------------------

  task automatic send(input logic [7:0] data);

    time bt;
    bit  parity_bit;

    bt = bit_period();

    if (bt == 0ns) begin
      $error("[UART_IF] Invalid baud rate: %0d", baud_rate);
      return;
    end

    if (data_bits < 5 || data_bits > 8) begin
      $error("[UART_IF] Unsupported data width: %0d", data_bits);
      return;
    end

    // Start bit.
    tx = 1'b0;
    #(bt);

    // Data bits, LSB first.
    for (int i = 0; i < data_bits; i++) begin
      tx = data[i];
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

      tx = parity_bit;
      #(bt);
    end

    // Stop bit.
    tx = 1'b1;
    #(bt);

    // Optional additional stop bit.
    if (extra_stop) begin
      tx = 1'b1;
      #(bt);
    end

    // Ensure idle state.
    tx = 1'b1;

  endtask

  // ------------------------------------------------------------
  // UART receive task
  //
  // Samples near the center of each bit.
  // Returns the received data and whether the frame was valid.
  // ------------------------------------------------------------

  task automatic recv(output logic [7:0] data, output bit frame_error);

    time bt;
    bit  parity_bit;
    bit  expected_parity;

    data        = '0;
    frame_error = 1'b0;

    bt          = bit_period();

    if (bt == 0ns) begin
      $error("[UART_IF] Invalid baud rate: %0d", baud_rate);
      frame_error = 1'b1;
      return;
    end

    if (data_bits < 5 || data_bits > 8) begin
      $error("[UART_IF] Unsupported data width: %0d", data_bits);
      frame_error = 1'b1;
      return;
    end

    // --------------------------------------------------------
    // Detect start bit
    // --------------------------------------------------------

    @(negedge rx);

    // Confirm start bit at its center.
    #(bt / 2);

    if (rx !== 1'b0) begin
      frame_error = 1'b1;
      return;
    end

    // --------------------------------------------------------
    // Sample data bits at their centers
    // --------------------------------------------------------

    for (int i = 0; i < data_bits; i++) begin

      #(bt);

      data[i] = rx;

    end

    // --------------------------------------------------------
    // Sample parity bit
    // --------------------------------------------------------

    if (parity_en) begin

      #(bt);

      parity_bit = rx;

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

    #(bt);

    if (rx !== 1'b1) frame_error = 1'b1;

    // Additional stop bit, if configured.
    if (extra_stop) begin

      #(bt);

      if (rx !== 1'b1) frame_error = 1'b1;

    end

  endtask

  // ------------------------------------------------------------
  // Wait until the transmitter is idle
  // ------------------------------------------------------------

  task automatic wait_till_idle(input int unsigned timeout_bits = 100);

    time bt;
    int unsigned cycles;

    bt = bit_period();
    cycles = 0;

    if (bt == 0ns) begin
      $error("[UART_IF] Cannot wait for idle with baud_rate=0");
      return;
    end

    while (tx !== 1'b1) begin
      #(bt);
      cycles++;

      if (cycles >= timeout_bits) begin
        $error("[UART_IF] Timeout waiting for TX idle");
        return;
      end
    end

  endtask

endinterface
