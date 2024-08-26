module noc #(
    parameter int CPU_NB = 4,
    parameter int TRANSACTION_NB = 1000
) (
    input bit clk,
    // cpu -> noc
    output bit data_cpu_to_noc_rdy[CPU_NB],
    input bit data_cpu_to_noc_vld[CPU_NB],
    input bit [63:0] data_cpu_to_noc[CPU_NB],
    // noc -> cpu
    input bit data_noc_to_cpu_rdy[CPU_NB],
    output bit data_noc_to_cpu_vld[CPU_NB],
    output bit [63:0] data_noc_to_cpu[CPU_NB]
);

  bit [CPU_NB-1:0] transaction_cpu_to_noc_done;
  bit [CPU_NB-1:0] transaction_noc_to_cpu_done;

  for (genvar cpu_idx = 0; cpu_idx < CPU_NB; cpu_idx++) begin : gen_cpu
    bit [63:0] data_q[$];

    //---------------------------------------------------------
    // cpu -> noc
    //---------------------------------------------------------
    always @(posedge clk) begin
      data_cpu_to_noc_rdy[cpu_idx] <= bit'($urandom);
    end

    int transaction_cpu_to_noc_idx = 0;
    always @(posedge clk) begin
      if (data_cpu_to_noc_vld[cpu_idx] && data_cpu_to_noc_rdy[cpu_idx]) begin
        data_q.push_back(data_cpu_to_noc[cpu_idx]);
        $display("[cpu_%0d] NOC received 0x%016x (transaction_cpu_to_noc %0d/%0d)", cpu_idx,
                 data_cpu_to_noc[cpu_idx], transaction_cpu_to_noc_idx, TRANSACTION_NB);
        transaction_cpu_to_noc_idx <= transaction_cpu_to_noc_idx + 1;
        if (transaction_cpu_to_noc_idx == (TRANSACTION_NB - 1)) begin
          transaction_cpu_to_noc_done[cpu_idx] <= 1;
        end
      end
    end

    //---------------------------------------------------------
    // noc -> cpu
    //---------------------------------------------------------
    assign data_noc_to_cpu_vld[cpu_idx] = (data_q.size() >= 1);
    assign data_noc_to_cpu[cpu_idx] = data_noc_to_cpu_vld[cpu_idx] ? data_q[0] : 'h0;

    int transaction_noc_to_cpu_idx = 0;
    always @(posedge clk) begin
      if (data_noc_to_cpu_vld[cpu_idx] && data_noc_to_cpu_rdy[cpu_idx]) begin
        $display("[cpu_%0d] NOC sent 0x%016x (transaction_noc_to_cpu %0d/%0d)", cpu_idx,
                 data_noc_to_cpu[cpu_idx], transaction_noc_to_cpu_idx, TRANSACTION_NB);
        data_q.pop_front();
        transaction_noc_to_cpu_idx <= transaction_noc_to_cpu_idx + 1;
        if (transaction_noc_to_cpu_idx == (TRANSACTION_NB - 1)) begin
          transaction_noc_to_cpu_done[cpu_idx] <= 1;
        end
      end
    end
  end

  initial begin
    wait (transaction_cpu_to_noc_done == {CPU_NB{1'b1}});
    wait (transaction_noc_to_cpu_done == {CPU_NB{1'b1}});
    repeat (2) @(posedge clk);
    $finish;
  end

endmodule
