`include "apb/typedef.svh"

interface apb_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
) (
    input logic pclk,
    input logic presetn
);

  `APB_T(apb, ADDR_WIDTH, DATA_WIDTH)

  apb_req_t  req;
  apb_resp_t rsp;

  modport master(input pclk, input presetn, output req, input rsp);

  modport slave(input pclk, input presetn, input req, output rsp);

  modport monitor(input pclk, input presetn, input req, input rsp);

  bit is_clock_edge_aligned;

  always @(posedge pclk) begin
    is_clock_edge_aligned <= 1'b1;
    #1step;
    is_clock_edge_aligned <= 1'b0;
  end

  task automatic apply_reset(bit mode = 1);
    if (mode) begin
      req <= '0;
    end else begin
      rsp <= '0;
    end
  endtask

  task automatic do_transaction(input logic [ADDR_WIDTH-1:0] addr, input logic write,
                                input logic [DATA_WIDTH-1:0] wdata,
                                output logic [DATA_WIDTH-1:0] rdata, output logic slverr);

    wait (is_clock_edge_aligned);

    req.psel    <= 1'b1;
    req.penable <= 1'b0;
    req.paddr   <= addr;
    req.pprot   <= '0;
    req.pwrite  <= write;
    req.pwdata  <= wdata;
    req.pstrb   <= '1;

    @(posedge pclk);
    req.penable <= 1'b1;

    do @(posedge pclk); while (rsp.pready !== 1'b1);

    rdata  = rsp.prdata;
    slverr = rsp.pslverr;
    req.psel    <= 1'b0;

  endtask

  task automatic get_transaction(output logic [ADDR_WIDTH-1:0] addr, output logic write,
                                 output logic [DATA_WIDTH-1:0] data, output logic slverr);

    do
      @(posedge pclk);
    while (!(presetn === 1'b1 && req.psel === 1'b1 && req.penable === 1'b1 && rsp.pready === 1'b1));

    addr   = req.paddr;
    write  = req.pwrite;
    data   = write ? req.pwdata : rsp.prdata;
    slverr = rsp.pslverr;

  endtask

  task automatic write(input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] wdata);

    logic [DATA_WIDTH-1:0] dummy_rdata;
    logic                  dummy_slverr;

    do_transaction(addr, 1'b1, wdata, dummy_rdata, dummy_slverr);

  endtask

  task automatic read(input logic [ADDR_WIDTH-1:0] addr, output logic [DATA_WIDTH-1:0] rdata);

    logic dummy_slverr;

    do_transaction(addr, 1'b0, '0, rdata, dummy_slverr);

  endtask

  task automatic wait_till_idle(input int x = 10);

    int i = 0;

    while (i < x) begin
      @(posedge pclk);

      if (req.psel === 1'b1) i = 0;
      else i++;
    end

  endtask

endinterface
