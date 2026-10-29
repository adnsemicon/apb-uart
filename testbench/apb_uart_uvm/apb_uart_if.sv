interface apb_uart_if(input logic PCLK);
  logic PRESETn;
  logic psel, penable, pwrite;
  logic [31:0] paddr, pwdata;
  logic [31:0] prdata;
  logic pready, pslverr;
  logic UART_TX, UART_RX, UART_IRQ;

  task automatic drive_idle();
    psel=0; penable=0; pwrite=0; paddr='0; pwdata='0;
  endtask
endinterface

