// Description: Simple memory module with AXI interface for multiple CPUs
// This code has a lot of simplifications and assumptions for illustrative purposes.

module memory
  import axi_pkg::*;
#(
    parameter int CPU_NB = 4,
    parameter int TRANSACTION_NB = 1000
) (
    input bit clk,

    // subordinate AXI interface

    input  axi_aw_t i_axi_s_aw     [CPU_NB],
    output bit      o_axi_s_awready[CPU_NB],
    input  bit      i_axi_s_awvalid[CPU_NB],

    input  axi_w_t i_axi_s_w     [CPU_NB],
    output bit     o_axi_s_wready[CPU_NB],
    input  bit     i_axi_s_wvalid[CPU_NB],

    output axi_b_t o_axi_s_b     [CPU_NB],
    input  bit     i_axi_s_bready[CPU_NB],
    output bit     o_axi_s_bvalid[CPU_NB],

    input  axi_ar_t i_axi_s_ar     [CPU_NB],
    output bit      o_axi_s_arready[CPU_NB],
    input  bit      i_axi_s_arvalid[CPU_NB],

    output axi_r_t o_axi_s_r     [CPU_NB],
    input  bit     i_axi_s_rready[CPU_NB],
    output bit     o_axi_s_rvalid[CPU_NB]
);

  bit [CPU_NB-1:0] transaction_done;
  bit [AXI_DATA_WIDTH-1:0] memory_array[1024*CPU_NB];  // 1024 entries per CPU


  for (genvar cpu_idx = 0; cpu_idx < CPU_NB; cpu_idx++) begin : gen_cpu
    int read_transaction_nb = 0;
    axi_aw_t aw_queue[$];
    axi_w_t w_queue[$];
    axi_ar_t ar_queue[$];

    always @(posedge clk) begin
      o_axi_s_bvalid[cpu_idx] <= 0;
      o_axi_s_rvalid[cpu_idx] <= 0;

      if (read_transaction_nb < TRANSACTION_NB) begin
        o_axi_s_awready[cpu_idx] <= bit'($urandom);
        o_axi_s_wready[cpu_idx]  <= bit'($urandom);
        o_axi_s_arready[cpu_idx] <= bit'($urandom);

        // AW
        if (o_axi_s_awready[cpu_idx] && i_axi_s_awvalid[cpu_idx]) begin
          aw_queue.push_back(i_axi_s_aw[cpu_idx]);
        end

        // W
        if (o_axi_s_wready[cpu_idx] && i_axi_s_wvalid[cpu_idx]) begin
          w_queue.push_back(i_axi_s_w[cpu_idx]);
        end

        // B
        if (i_axi_s_bready[cpu_idx] && (aw_queue.size() >= 1) && (w_queue.size() >= 1)) begin
          // update memory for write transactions
          memory_array[aw_queue[0].addr>>3] = w_queue[0].data;
          $display("[cpu_%0d] MEM 0x%016x -> [0x%016x]", aw_queue[0].id, w_queue[0].data,
                   aw_queue[0].addr);
          // respond to write transactions
          o_axi_s_b[cpu_idx].id   <= aw_queue[0].id;
          o_axi_s_b[cpu_idx].resp <= 0;
          o_axi_s_bvalid[cpu_idx] <= 1;
          // remove processed transactions from queues
          aw_queue.pop_front();
          w_queue.pop_front();
        end

        // AR
        if (o_axi_s_arready[cpu_idx] && i_axi_s_arvalid[cpu_idx]) begin
          ar_queue.push_back(i_axi_s_ar[cpu_idx]);
        end

        // R
        if (i_axi_s_rready[cpu_idx] && (ar_queue.size() >= 1)) begin
          // respond to read transactions
          o_axi_s_r[cpu_idx].id   <= ar_queue[0].id;
          o_axi_s_r[cpu_idx].resp <= 0;
          o_axi_s_r[cpu_idx].data <= memory_array[ar_queue[0].addr>>3];
          o_axi_s_rvalid[cpu_idx] <= 1;
          $display("[cpu_%0d] MEM 0x%016x <- [0x%016x] (%0d/%0d)", ar_queue[0].id,
                   memory_array[ar_queue[0].addr>>3], ar_queue[0].addr, read_transaction_nb,
                   TRANSACTION_NB);
          // remove processed transactions from queues
          ar_queue.pop_front();
          // update read transaction count
          read_transaction_nb++;
        end
      end else begin
        o_axi_s_awready[cpu_idx]  <= 0;
        o_axi_s_wready[cpu_idx]   <= 0;
        o_axi_s_arready[cpu_idx]  <= 0;
        transaction_done[cpu_idx] <= 1;
      end
    end

  end

  initial begin
    wait (transaction_done == {CPU_NB{1'b1}});
    repeat (2) @(posedge clk);
    $finish;
  end

endmodule
