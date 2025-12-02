// Description: Simple memory module with APB interface for multiple CPUs
// This code has a lot of simplifications and assumptions for illustrative purposes.

module memory
  import apb_pkg::*;
#(
    parameter int CPU_NB = 4,
    parameter int TRANSACTION_NB = 1000
) (
    input bit clk,

    // subordinate APB interface

    input apb_req_t i_apb_s_req[CPU_NB],
    output apb_resp_t o_apb_s_resp[CPU_NB],
    input bit i_apb_s_psel[CPU_NB],
    input bit i_apb_s_penable[CPU_NB],
    output bit o_apb_s_pready[CPU_NB]
);

  bit [CPU_NB-1:0] transaction_done;
  bit [APB_DATA_WIDTH-1:0] memory_array[1024*CPU_NB];  // 1024 entries per CPU


  for (genvar cpu_idx = 0; cpu_idx < CPU_NB; cpu_idx++) begin : gen_cpu
    int read_transaction_nb = 0;

    assign o_apb_s_resp[cpu_idx].slverr = 0;
    assign o_apb_s_resp[cpu_idx].rdata  = memory_array[i_apb_s_req[cpu_idx].addr>>2];

    always @(posedge clk) begin
      if (read_transaction_nb < TRANSACTION_NB) begin
        o_apb_s_pready[cpu_idx] <= bit'($urandom);

        if (i_apb_s_psel[cpu_idx] && i_apb_s_penable[cpu_idx] && o_apb_s_pready[cpu_idx]) begin
          if (i_apb_s_req[cpu_idx].write) begin
            memory_array[i_apb_s_req[cpu_idx].addr>>2] = i_apb_s_req[cpu_idx].wdata;
            $display("[cpu_%0d] MEM 0x%08x -> [0x%08x]", cpu_idx, i_apb_s_req[cpu_idx].wdata,
                     i_apb_s_req[cpu_idx].addr);
          end else begin
            $display("[cpu_%0d] MEM 0x%08x <- [0x%08x] (%0d/%0d)", cpu_idx,
                     o_apb_s_resp[cpu_idx].rdata, i_apb_s_req[cpu_idx].addr, read_transaction_nb,
                     TRANSACTION_NB);
            read_transaction_nb++;
          end
        end
      end else begin
        o_apb_s_pready[cpu_idx]   <= 0;
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
