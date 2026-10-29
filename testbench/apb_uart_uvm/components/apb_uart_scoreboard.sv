// Correlate APB-side expectations with observed UART frames and report totals.
`ifndef __GUARD_APB_UART_SCOREBOARD_SV__
`define __GUARD_APB_UART_SCOREBOARD_SV__ 0

`uvm_analysis_imp_decl(_apb)

class apb_uart_scoreboard extends uvm_component;
  `uvm_component_utils(apb_uart_scoreboard)
  uvm_analysis_imp #(uart_rsp_item,apb_uart_scoreboard) uart_imp;
  uvm_analysis_imp_apb #(apb_seq_item,apb_uart_scoreboard) apb_imp;
  bit [7:0] expected_tx[$];
  bit [7:0] actual_tx[$];
  bit actual_framing_error[$];
  int unsigned tx_expected_count;
  int unsigned tx_observed_count;
  int unsigned apb_transactions_checked;
  int unsigned pass_count;
  int unsigned fail_count;
  bit count_apb_reads;
  bit count_apb_transactions;
  bit apb_read_check_pending;
  bit [31:0] expected_apb_read_addr;
  bit [31:0] expected_apb_read_data;
  bit [31:0] expected_apb_read_mask;

  function new(string name="apb_uart_scoreboard", uvm_component parent=null);
    super.new(name,parent);
    uart_imp=new("uart_imp",this);
    apb_imp=new("apb_imp",this);
  endfunction

  virtual function void write_apb(apb_seq_item tr);
    // Count enabled APB checks and compare a read when the test registered one.
    if (count_apb_transactions || (count_apb_reads && !tr.pwrite)) begin
      apb_transactions_checked++;
      if (tr.pslverr) begin
        fail_count++;
        `uvm_error("APB_SB",
                   $sformatf("APB %s FAIL address=0x%08h slave_error=1",
                             tr.pwrite ? "WRITE" : "READ", tr.paddr))
      end else if (!tr.pwrite && apb_read_check_pending &&
                   tr.paddr == expected_apb_read_addr) begin
        apb_read_check_pending = 1'b0;
        if ((tr.prdata & expected_apb_read_mask) ==
            (expected_apb_read_data & expected_apb_read_mask)) begin
          pass_count++;
          `uvm_info("APB_SB",
                    $sformatf("APB READ PASS address=0x%08h expected=0x%08h got=0x%08h",
                              tr.paddr, expected_apb_read_data & expected_apb_read_mask,
                              tr.prdata & expected_apb_read_mask),
                    UVM_LOW)
        end else begin
          fail_count++;
          `uvm_error("APB_SB",
                     $sformatf("APB READ FAIL address=0x%08h expected=0x%08h got=0x%08h",
                               tr.paddr, expected_apb_read_data & expected_apb_read_mask,
                               tr.prdata & expected_apb_read_mask))
        end
      end else begin
        pass_count++;
      end
    end

    if (tr.pwrite && tr.paddr == 32'h0000001C) begin
      // UART_TXD writes are matched in order with decoded UART output frames.
      expected_tx.push_back(tr.pwdata[7:0]);
      tx_expected_count++;
      compare_pending();
    end
  endfunction

  virtual function void enable_apb_read_counting();
    count_apb_reads = 1'b1;
  endfunction

  virtual function void enable_apb_transaction_counting();
    count_apb_transactions = 1'b1;
  endfunction

  virtual function void expect_apb_read(bit [31:0] addr,
                                        bit [31:0] data,
                                        bit [31:0] mask = 32'hFFFF_FFFF);
    // The next matching read is checked only on the selected mask bits.
    expected_apb_read_addr = addr;
    expected_apb_read_data = data;
    expected_apb_read_mask = mask;
    apb_read_check_pending = 1'b1;
  endfunction

  virtual function void write(uart_rsp_item tr);
    actual_tx.push_back(tr.data);
    actual_framing_error.push_back(tr.framing_error);
    tx_observed_count++;
    compare_pending();
  endfunction

  virtual function void compare_pending();
    bit [7:0] expected;
    bit [7:0] actual;
    bit framing_error;

    // Compare as many ordered write/frame pairs as are available.
    while (expected_tx.size() != 0 && actual_tx.size() != 0) begin
      expected = expected_tx.pop_front();
      actual = actual_tx.pop_front();
      framing_error = actual_framing_error.pop_front();

      if (expected == actual && !framing_error) begin
        pass_count++;
        `uvm_info("UART_SB",
                  $sformatf("TX PASS expected=0x%02h got=0x%02h", expected, actual),
                  UVM_LOW)
      end else begin
        fail_count++;
        `uvm_error("UART_SB",
                   $sformatf("TX FAIL expected=0x%02h got=0x%02h framing_error=%0b",
                             expected, actual, framing_error))
      end
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    // Any unmatched expected or observed frames indicate missing or extra traffic.
    while (expected_tx.size() != 0) begin
      fail_count++;
      `uvm_error("UART_SB",
                 $sformatf("TX FAIL expected=0x%02h got=<no frame>",
                           expected_tx.pop_front()))
    end

    while (actual_tx.size() != 0) begin
      fail_count++;
      `uvm_error("UART_SB",
                 $sformatf("TX FAIL expected=<no write> got=0x%02h framing_error=%0b",
                           actual_tx.pop_front(), actual_framing_error.pop_front()))
    end

    `uvm_info("UART_SB",
              $sformatf("\n\033[1m||||| SCOREBOARD TOTALS |||||\033[0m\n\033[1mTOTAL PASS COUNT: %0d\033[0m\n\033[1mTOTAL FAIL COUNT: %0d\033[0m\nAPB transactions checked: %0d | TX expected frames: %0d | TX observed frames: %0d",
                        pass_count, fail_count, apb_transactions_checked,
                        tx_expected_count, tx_observed_count),
              UVM_NONE)
  endfunction
endclass

`endif