module cpu #(
    parameter int TRANSACTION_NB = 1000,
    parameter int COMPUTATION_COMPLEXITY = 20
) (
    input bit clk,
    input bit [31:0] cpu_index,
    // cpu -> noc
    input bit data_cpu_to_noc_rdy,
    output bit data_cpu_to_noc_vld,
    output bit [63:0] data_cpu_to_noc,
    // noc -> cpu
    output bit data_noc_to_cpu_rdy,
    input bit data_noc_to_cpu_vld,
    input bit [63:0] data_noc_to_cpu,
    output bit transactions_done
);

  bit transaction_cpu_to_noc_done;
  bit transaction_noc_to_cpu_done;
  assign transactions_done = transaction_cpu_to_noc_done && transaction_noc_to_cpu_done;

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

  //-----------------------------------------------------------
  // cpu -> noc
  //-----------------------------------------------------------
  int transaction_cpu_to_noc_idx = 0;

  bit [63:0] x;
  initial begin
    #1;
    x = 64'hdeadbeefdeadbeef + longint'(cpu_index);
  end

  always_ff @(posedge clk) begin
    while (data_cpu_to_noc_vld && !data_cpu_to_noc_rdy) begin
      wait_n_cycles(1);
    end
    data_cpu_to_noc_vld <= 0;
    if (transaction_cpu_to_noc_idx == TRANSACTION_NB) begin
      transaction_cpu_to_noc_done <= 1;
    end else begin
      x <= xorshift64star(x, COMPUTATION_COMPLEXITY * 1000000);
      wait_n_cycles(int'(x[15:0]));
      data_cpu_to_noc_vld <= 1;
      data_cpu_to_noc <= x;
      $display("[cpu_%0d] CPU sent 0x%016x (transaction_cpu_to_noc %0d/%0d)", cpu_index, x,
               transaction_cpu_to_noc_idx, TRANSACTION_NB);
      transaction_cpu_to_noc_idx <= transaction_cpu_to_noc_idx + 1;
    end
  end

  //-----------------------------------------------------------
  // noc -> cpu
  //-----------------------------------------------------------
  int transaction_noc_to_cpu_idx = 0;

  always_ff @(posedge clk) begin
    data_noc_to_cpu_rdy <= bit'($urandom);
  end

  always_ff @(posedge clk) begin
    if (data_noc_to_cpu_vld && data_noc_to_cpu_rdy) begin
      if (transaction_noc_to_cpu_idx == (TRANSACTION_NB-1)) begin
        transaction_noc_to_cpu_done <= 1;
      end else begin
        $display("[cpu_%0d] CPU received 0x%016x (transaction_noc_to_cpu %0d/%0d)", cpu_index,
                 data_noc_to_cpu, transaction_noc_to_cpu_idx, TRANSACTION_NB);
        transaction_noc_to_cpu_idx <= transaction_noc_to_cpu_idx + 1;
      end
    end
  end

endmodule
