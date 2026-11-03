/*

| TEST CASE | DATE       | AUTHOR          |
|-----------|------------|-----------------|
| RST_0     | 2026-11-03 | Foez Ahmed      |
| RST_1     | 2026-11-03 | Foez Ahmed      |
| CLK       | 2026-11-03 | Foez Ahmed      |
| RGT       | 2026-11-03 | Foez Ahmed      | Request Grant Test (RGT). Verify that the request and grant mechanism.          |
| INTR      | 2026-11-03 | Foez Ahmed      | Interrupt Test (INTR). Verify that the interrupt mechanism works correctly.     |
| DATA      | 2026-11-03 | Foez Ahmed      | Data Transfer Test (DATA). Verify that data transfer works correctly.           |

## Test Cases

### RST_0
- Revert Registers to know valuse as per the datasheet.
- The TX & RX FIFOs should be cleared to their default states.
- UART TX floats back to pull-up state.
- All interrupt flags should be cleared.

### RST_1
- ALL conditions from RST_0 should be met.
- [Probe] CLK Generation Returns to default baud rate. 
- Outgoing TX is halted and waits for UART_CTRL::TX_EN.
- Incoming RX is ignored and awaits clock UART_CTRL::RX_EN.
- [Probe] TX return to IDLE state. 
- [Probe] RX return to IDLE state. 

### CLK
- [Probe] Verify that the clock divider generates the desired clock frequency for different clock divider settings for both TX and RX.
- [Not planned for this scope] Clk glitch
- [Not planned for this scope] CDC


| REVISION | DATE       | AUTHOR          | DESCRIPTION                                            |
|----------|------------|-----------------|--------------------------------------------------------|
| 0.1      | 2026-11-03 | Foez Ahmed      | Initial version                                        |
| 1.0      | 2026-11-03 | Foez Ahmed      | Stable release                                         |

Author : Foez Ahmed (foez.official@gmail.com)
This file is part of ADN-VLSI/apb_uart
Copyright (c) 2026 ADN Semiconductors
Licensed under the MIT License
See LICENSE file in the project root for full license information

*/

module apb_uart_top_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/adn_common_tb_headers.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int ADDR_WIDTH = 32;
  localparam int DATA_WIDTH = 32;
  localparam int FIFO_SIZE  = 4;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic uart_intr;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // INTERFACES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  ctrl_if ctrl_intf ();

  apb_if #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) apb_intf (
      .pclk   (ctrl_intf.PCLK),
      .presetn(ctrl_intf.PRESETn)
  );

  uart_if tx_intf ();
  uart_if rx_intf ();

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  apb_uart_top #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .FIFO_SIZE (FIFO_SIZE)
  ) DUT (
      .PCLK   (ctrl_intf.PCLK),
      .PRESETn(ctrl_intf.PRESETn),
      .apb_req_i (apb_intf.req),
      .apb_resp_o(apb_intf.rsp),
      .UART_TX(tx_intf.rx),
      .UART_RX(rx_intf.tx),
      .UART_IRQ(uart_intr)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin

    ctrl_intf.apply_reset();
    ctrl_intf.start_clock();

    #100ns;

    note_case(1);
    note_case(0);

    $finish;

  end

endmodule
