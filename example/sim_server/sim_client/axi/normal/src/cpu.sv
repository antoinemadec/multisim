// Description: Simple fake CPU sending AXI read and write transactions
// This code has a lot of simplifications and assumptions for illustrative purposes.
//
// Self checking: check read data against reference array

module cpu
  import axi_pkg::*;
#(
    parameter int TRANSACTION_NB = 1000,
    parameter int COMPUTATION_COMPLEXITY = 20
) (
    input bit clk,
    input bit [31:0] cpu_index,

    // manager AXI interface

    output axi_aw_t o_axi_m_aw,
    input  bit      i_axi_m_awready,
    output bit      o_axi_m_awvalid,

    output axi_w_t o_axi_m_w,
    input  bit     i_axi_m_wready,
    output bit     o_axi_m_wvalid,

    input  axi_b_t i_axi_m_b,
    output bit     o_axi_m_bready,
    input  bit     i_axi_m_bvalid,

    output axi_ar_t o_axi_m_ar,
    input  bit      i_axi_m_arready,
    output bit      o_axi_m_arvalid,

    input  axi_r_t i_axi_m_r,
    output bit     o_axi_m_rready,
    input  bit     i_axi_m_rvalid
);

  function automatic bit [63:0] xorshift64star(input bit [63:0] x, input bit [31:0] iterations = 1);
    if (x == 64'h0) begin
      x = 64'hdeadbeefdeadbeef + longint'(cpu_index);
    end
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

  logic [AXI_DATA_WIDTH-1:0] memory_array[1024];  // 1024 entries per CPU

  task static axi_read(input bit [AXI_ADDR_WIDTH-1:0] address,
                       output logic [AXI_DATA_WIDTH-1:0] rdata);
    logic [AXI_DATA_WIDTH-1:0] expected_rdata;

    // AR
    o_axi_m_ar.id    <= cpu_index[AXI_ID_WIDTH-1:0];
    o_axi_m_ar.addr  <= address;
    o_axi_m_ar.len   <= 0;
    o_axi_m_ar.size  <= 3; // 8 bytes
    o_axi_m_ar.burst <= 1; // INCR
    o_axi_m_ar.lock  <= 0;
    o_axi_m_ar.cache <= 0;
    o_axi_m_ar.prot  <= 0;
    o_axi_m_ar.qos   <= 0;
    o_axi_m_ar.region <= 0;

    o_axi_m_arvalid <= 1;
    @(posedge clk);
    while (!i_axi_m_arready) @(posedge clk);
    o_axi_m_arvalid <= 0;

    // R
    o_axi_m_rready  <= 1;
    @(posedge clk);
    while (!i_axi_m_rvalid) @(posedge clk);
    rdata = i_axi_m_r.data;
    o_axi_m_rready <= 0;

    // check against reference array
    expected_rdata = memory_array[address[9:0]];
    if (expected_rdata !== rdata) begin
      $fatal(1, "at [0x%x]: expected 0x%x, got 0x%x", address, expected_rdata, rdata);
    end
  endtask

  task static axi_write(input bit [AXI_ADDR_WIDTH-1:0] address,
                        input logic [AXI_DATA_WIDTH-1:0] wdata,
                        input bit [31:0] aw_w_wait_cycles = 0);
    // AW
    o_axi_m_aw.id    <= cpu_index[AXI_ID_WIDTH-1:0];
    o_axi_m_aw.addr  <= address;
    o_axi_m_aw.len   <= 0;
    o_axi_m_aw.size  <= 3; // 8 bytes
    o_axi_m_aw.burst <= 1; // INCR
    o_axi_m_aw.lock  <= 0;
    o_axi_m_aw.cache <= 0;
    o_axi_m_aw.prot  <= 0;
    o_axi_m_aw.qos   <= 0;
    o_axi_m_aw.region <= 0;

    o_axi_m_awvalid <= 1;
    @(posedge clk);
    while (!i_axi_m_awready) @(posedge clk);
    o_axi_m_awvalid <= 0;

    wait_n_cycles(aw_w_wait_cycles);

    // W
    o_axi_m_w.id   <= cpu_index[AXI_ID_WIDTH-1:0];
    o_axi_m_w.data <= wdata;
    o_axi_m_w.strb <= '1;  // all bytes valid
    o_axi_m_w.last <= 1;

    o_axi_m_wvalid <= 1;
    @(posedge clk);
    while (!i_axi_m_wready) @(posedge clk);
    o_axi_m_wvalid <= 0;

    // B
    o_axi_m_bready <= 1;
    @(posedge clk);
    while (!i_axi_m_bvalid) @(posedge clk);
    o_axi_m_bready <= 0;

    // update reference array
    memory_array[address[9:0]] = wdata;
  endtask

  int read_transaction_nb = 0;

  bit [63:0] x;

  always_ff @(posedge clk) begin
    o_axi_m_awvalid <= 0;
    o_axi_m_wvalid  <= 0;
    o_axi_m_bready  <= 0;
    o_axi_m_arvalid <= 0;
    o_axi_m_rready  <= 0;

    if (read_transaction_nb < TRANSACTION_NB) begin
      automatic bit rwb = x[4];
      automatic bit [3:0] cmd_wait_cycles = x[3:0];
      automatic bit [3:0] aw_w_wait_cycles = x[8:5];
      automatic int address = int'({cpu_index, x[9+:7], 3'b0});

      x <= xorshift64star(x, COMPUTATION_COMPLEXITY * 1000000);
      wait_n_cycles(int'(cmd_wait_cycles));  // 0 to 7 cycles extra delay

      if (rwb) begin
        logic [63:0] rdata;
        axi_read(address, rdata);
        $display("[cpu_%0d] CPU 0x%016x <- [0x%016x] (%0d/%0d)", cpu_index, rdata, address,
                 read_transaction_nb, TRANSACTION_NB);
        read_transaction_nb++;
      end else begin
        $display("[cpu_%0d] CPU 0x%016x -> [0x%016x]", cpu_index, x, address);
        axi_write(address, x, int'(aw_w_wait_cycles));
      end
    end
  end

endmodule
