// Description: Simple fake CPU sending APB read and write transactions
// This code has a lot of simplifications and assumptions for illustrative purposes.

module cpu
  import apb_pkg::*;
#(
    parameter int TRANSACTION_NB = 1000,
    parameter int COMPUTATION_COMPLEXITY = 20
) (
    input bit clk,
    input bit [31:0] cpu_index,

    // manager APB interface

    output apb_req_t o_apb_m_req,
    input apb_resp_t i_apb_m_resp,
    output bit o_apb_m_psel,
    output bit o_apb_m_penable,
    input bit i_apb_m_pready
);

  function automatic bit [63:0] xorshift64star(input bit [63:0] x, input bit [31:0] iterations = 1);
    repeat (iterations) begin
      x = x ^ (x >> 12);
      x = x ^ (x << 25);
      x = x ^ (x >> 27);
      x = x * 64'h5821657736338717;
    end
    return x;
  endfunction

  task static wait_n_cycles(input bit [31:0] n);
    repeat (n) begin
      @(posedge clk);
    end
  endtask

  task static apb_read(input bit [APB_ADDR_WIDTH-1:0] address,
                       output bit [APB_DATA_WIDTH-1:0] rdata);
    // request
    o_apb_m_req.addr <= address;
    o_apb_m_req.wdata <= 0;
    o_apb_m_req.write <= 0;
    o_apb_m_req.strb <= 0;
    o_apb_m_req.prot <= 0;
    o_apb_m_psel <= 1;
    @(posedge clk);
    o_apb_m_penable <= 1;
    @(posedge clk);

    // wait for completer to be ready
    while (!i_apb_m_pready) @(posedge clk);
    rdata = i_apb_m_resp.rdata;
    o_apb_m_psel <= 0;
    o_apb_m_penable <= 0;
  endtask

  task static apb_write(input bit [APB_ADDR_WIDTH-1:0] address,
                        input bit [APB_DATA_WIDTH-1:0] wdata);
    // request
    o_apb_m_req.addr <= address;
    o_apb_m_req.wdata <= wdata;
    o_apb_m_req.write <= 1;
    o_apb_m_req.strb <= '1;  // all bytes valid
    o_apb_m_req.prot <= 0;
    o_apb_m_psel <= 1;
    @(posedge clk);
    o_apb_m_penable <= 1;
    @(posedge clk);

    // wait for completer to be ready
    while (!i_apb_m_pready) @(posedge clk);
    o_apb_m_psel <= 0;
    o_apb_m_penable <= 0;
  endtask

  int read_transaction_nb = 0;

  bit [63:0] x;
  initial begin
    #1;
    x = 64'hdeadbeefdeadbeef + longint'(cpu_index);
  end

  always_ff @(posedge clk) begin
    o_apb_m_psel <= 0;
    o_apb_m_penable <= 0;

    if (read_transaction_nb < TRANSACTION_NB) begin
      bit rwb = x[4];
      bit [3:0] cmd_wait_cycles = x[3:0];
      int address = int'({cpu_index, x[7+:5], 2'b0});
      bit [APB_DATA_WIDTH-1:0] wdata = x[APB_DATA_WIDTH-1:0];

      x <= xorshift64star(x, COMPUTATION_COMPLEXITY * 1000000);
      wait_n_cycles(int'(cmd_wait_cycles));  // 0 to 7 cycles extra delay

      if (rwb) begin
        bit [APB_DATA_WIDTH-1:0] rdata;
        apb_read(address, rdata);
        $display("[cpu_%0d] CPU 0x%08x <- [0x%08x] (%0d/%0d)", cpu_index, rdata, address,
                 read_transaction_nb, TRANSACTION_NB);
        read_transaction_nb++;
      end else begin
        $display("[cpu_%0d] CPU 0x%08x -> [0x%08x]", cpu_index, wdata, address);
        apb_write(address, wdata);
      end
    end
  end

endmodule
