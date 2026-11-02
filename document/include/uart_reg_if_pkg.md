# uart_reg_if_pkg.sv  (package)

### Source: uart_reg_if_pkg.sv

## Parameters

|Name|Type|Dimension|Default|Description|
|-|-|-|-|-|
|ADDR_CTRL|int||12'h000|---------------- Register byte-address offsets ----------------|
|ADDR_CFG|int||12'h004||
|ADDR_STATUS|int||12'h008||
|ADDR_TXR|int||12'h010||
|ADDR_TXGP|int||12'h014||
|ADDR_TXG|int||12'h018||
|ADDR_TXD|int||12'h01C||
|ADDR_RXR|int||12'h020||
|ADDR_RXGP|int||12'h024||
|ADDR_RXG|int||12'h028||
|ADDR_RXD|int||12'h02C||
|ADDR_INTR|int||12'h030||
|CTRL_RST|uart_ctrl_t||'{         reserved : '0,         rx_en    : 1'b0,         tx_en    : 1'b0,         rx_flush : 1'b0,         tx_flush : 1'b0,         sw_rst   : 1'b0     }||
|CFG_RST|uart_cfg_t||'{         reserved    : '0,         stop_bits   : 1'b0,         parity_type : 1'b0,         parity_en   : 1'b0,         data_bits   : 2'h3,         prescaler   : 4'h4,         clk_div     : 12'h05B     }||
|INTR_RST|uart_intr_t||'{         reserved : '0,         rx_full  : 1'b0,         rx_empty : 1'b0,         tx_full  : 1'b0,         tx_empty : 1'b0     }||


## Typedefs

|Name|
|-|
|uart_ctrl_t|
|uart_cfg_t|
|uart_status_t|
|uart_txr_t|
|uart_txgp_t|
|uart_txg_t|
|uart_txd_t|
|uart_rxr_t|
|uart_rxgp_t|
|uart_rxg_t|
|uart_rxd_t|
|uart_intr_t|


## Description

_No top-level description found._
