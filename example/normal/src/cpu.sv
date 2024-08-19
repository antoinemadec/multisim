module cpu #(
    parameter int TRANSACTION_NB = 1000,
    parameter int COMPUTATION_COMPLEXITY = 20
) (
    input bit clk,
    input bit [31:0] cpu_index,
    input bit data_rdy,
    output bit data_vld,
    output bit [63:0] data,
    output bit transactions_done
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

  int transaction_idx = 0;

  bit [63:0] x;
  initial begin
    #1;
    x = 64'hdeadbeefdeadbeef + longint'(cpu_index);
  end

  always_ff @(posedge clk) begin
    while (data_vld && !data_rdy) begin
      wait_n_cycles(1);
    end
    data_vld <= 0;
    if (transaction_idx == TRANSACTION_NB) begin
      transactions_done <= 1;
    end else begin
      x <= xorshift64star(x, COMPUTATION_COMPLEXITY*1000000);
      wait_n_cycles(int'(x[15:0]));
      data_vld <= 1;
      data <= x;
      $display("[cpu_%0d] CPU sent 0x%016x (transaction %0d/%0d)", cpu_index, x, transaction_idx,
               TRANSACTION_NB);
      transaction_idx <= transaction_idx + 1;
    end
  end

endmodule
