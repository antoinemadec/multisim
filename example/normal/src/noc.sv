module noc #(
    parameter int CPU_NB = 4,
    parameter int TRANSACTION_NB = 1000
) (
    input bit clk,
    output bit data_rdy[CPU_NB],
    input bit data_vld[CPU_NB],
    input bit [63:0] data[CPU_NB]
);

  bit [CPU_NB-1:0] transactions_done;

  for (genvar cpu_idx = 0; cpu_idx < CPU_NB; cpu_idx++) begin : gen_cpu
    bit cpu_data_rdy;
    bit cpu_data_vld;
    bit [63:0] cpu_data;

    assign data_rdy[cpu_idx] = cpu_data_rdy;
    assign cpu_data_vld = data_vld[cpu_idx];
    assign cpu_data = data[cpu_idx];

    always @(posedge clk) begin
      cpu_data_rdy <= bit'($urandom);
    end

    int transaction_idx = 0;
    always @(posedge clk) begin
      if (cpu_data_vld && cpu_data_rdy) begin
        $display("[cpu_%0d] NOC received 0x%016x (transaction %0d/%0d)", cpu_idx, cpu_data,
                 transaction_idx, TRANSACTION_NB);
        transaction_idx <= transaction_idx + 1;
        if (transaction_idx == (TRANSACTION_NB - 1)) begin
          transactions_done[cpu_idx] <= 1;
        end
      end
    end
  end

  initial begin
    wait (transactions_done == {CPU_NB{1'b1}});
    repeat (2) @(posedge clk);
    $finish;
  end

endmodule
