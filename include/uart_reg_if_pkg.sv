package uart_reg_if_pkg;

    // ---------------- Register byte-address offsets ----------------
    localparam int ADDR_CTRL   = 12'h000;
    localparam int ADDR_CFG    = 12'h004;
    localparam int ADDR_STATUS = 12'h008;
    localparam int ADDR_TXR    = 12'h010;
    localparam int ADDR_TXGP   = 12'h014;
    localparam int ADDR_TXG    = 12'h018;
    localparam int ADDR_TXD    = 12'h01C;
    localparam int ADDR_RXR    = 12'h020;
    localparam int ADDR_RXGP   = 12'h024;
    localparam int ADDR_RXG    = 12'h028;
    localparam int ADDR_RXD    = 12'h02C;
    localparam int ADDR_INTR   = 12'h030;


    // ---------------- UART_CTRL (0x00) : RW ----------------
    typedef struct packed {
        logic [26:0] reserved; // [31:5]
        logic        rx_en;    // [4]
        logic        tx_en;    // [3]
        logic        rx_flush; // [2] (pulse: write 1 to flush)
        logic        tx_flush; // [1] (pulse: write 1 to flush)
        logic        sw_rst;   // [0]
    } uart_ctrl_t;


    // ---------------- UART_CFG (0x04) : RW ----------------
    typedef struct packed {
        logic [10:0] reserved;    // [31:21]
        logic        stop_bits;   // [20]
        logic        parity_type; // [19]
        logic        parity_en;   // [18]
        logic [1:0]  data_bits;   // [17:16]
        logic [3:0]  prescaler;   // [15:12]
        logic [11:0] clk_div;     // [11:0]
    } uart_cfg_t;


    // ---------------- UART_STATUS (0x08) : RO ----------------
    typedef struct packed {
        logic [7:0]  reserved;      // [31:24]
        logic        rx_fifo_full;  // [23]
        logic        rx_fifo_empty; // [22]
        logic        tx_fifo_full;  // [21]
        logic        tx_fifo_empty; // [20]
        logic [9:0]  rx_data_cnt;   // [19:10]
        logic [9:0]  tx_data_cnt;   // [9:0]
    } uart_status_t;


    // ---------------- UART_TXR (0x10) : WO ----------------
    typedef struct packed {
        logic [23:0] reserved;  // [31:8]
        logic [7:0]  req_id;    // [7:0]
    } uart_txr_t;


    // ---------------- UART_TXGP (0x14) : RO ----------------
    typedef struct packed {
        logic [23:0] reserved;  // [31:8]
        logic [7:0]  grant_id;  // [7:0]
    } uart_txgp_t;


    // ---------------- UART_TXG (0x18) : RO ----------------
    typedef struct packed {
        logic        grant_valid; // [31]
        logic [23:0] reserved;    // [30:8]
        logic [7:0]  grant_id;    // [7:0]
    } uart_txg_t;


    // ---------------- UART_TXD (0x1C) : WO ----------------
    typedef struct packed {
        logic [23:8] reserved; // [31:8]
        logic [7:0]  data;     // [7:0]
    } uart_txd_t;


    // ---------------- UART_RXR (0x20) : WO ----------------
    typedef struct packed {
        logic [23:0] reserved;  // [31:8]
        logic [7:0]  req_id;    // [7:0]
    } uart_rxr_t;


    // ---------------- UART_RXGP (0x24) : RO ----------------
    typedef struct packed {
        logic [23:0] reserved;  // [31:8]
        logic [7:0]  grant_id;  // [7:0]
    } uart_rxgp_t;


    // ---------------- UART_RXG (0x28) : RO ----------------
    typedef struct packed {
        logic        grant_valid; // [31]
        logic [22:0] reserved;   // invalid
        logic [7:0]  grant_id;    // [7:0]
    } uart_rxg_t;


    // ---------------- UART_RXD (0x2C) : RO ----------------
    typedef struct packed {
        logic [23:8] reserved; // [31:8]
        logic [7:0]  data;     // [7:0]
    } uart_rxd_t;


    // ---------------- UART_INTR (0x30) : RW ----------------
    typedef struct packed {
        logic [27:4] reserved;   // [31:4]
        logic        rx_full;    // [3]
        logic        rx_empty;   // [2]
        logic        tx_full;    // [1]
        logic        tx_empty;   // [0]
    } uart_intr_t;


    // ---------------- Reset values ----------------

    localparam uart_ctrl_t CTRL_RST = '{
        reserved : '0,
        rx_en    : 1'b0,
        tx_en    : 1'b0,
        rx_flush : 1'b0,
        tx_flush : 1'b0,
        sw_rst   : 1'b0
    };


    localparam uart_cfg_t CFG_RST = '{
        reserved    : '0,
        stop_bits   : 1'b0,
        parity_type : 1'b0,
        parity_en   : 1'b0,
        data_bits   : 2'h3,
        prescaler   : 4'h4,
        clk_div     : 12'h05B
    };


    localparam uart_intr_t INTR_RST = '{
        reserved : '0,
        rx_full  : 1'b0,
        rx_empty : 1'b0,
        tx_full  : 1'b0,
        tx_empty : 1'b0
    };

endpackage : uart_reg_if_pkg