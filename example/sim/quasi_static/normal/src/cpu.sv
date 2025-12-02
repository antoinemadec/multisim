// Description: Simple fake CPU sending and receiving IRQs

module cpu #(
    parameter int TRANSACTION_NB = 1000,
    parameter int COMPUTATION_COMPLEXITY = 20
) (
    input bit clk,
    input bit [31:0] cpu_index,

    input bit [31:0] i_irq,
    output bit [31:0] o_irq,
    output bit o_finish
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

  int received_irq_nb = 0;
  bit [31:0] i_irq_prev = 0;

  bit [63:0] x;
  initial begin
    #1;
    x = 64'hdeadbeefdeadbeef + longint'(cpu_index);
  end

  always_ff @(posedge clk) begin : i_irq_process
    i_irq_prev <= i_irq;
    if (received_irq_nb < TRANSACTION_NB) begin
      if (i_irq != i_irq_prev) begin
        $display("[cpu_%0d] CPU i_irq = 0x%08x (%0d/%0d)", cpu_index, i_irq, received_irq_nb,
                 TRANSACTION_NB);
        received_irq_nb++;
      end
    end else begin
      o_finish <= 1;
    end
  end

  always_ff @(posedge clk) begin : o_irq_process
    if (received_irq_nb < TRANSACTION_NB) begin
      bit [ 3:0] wait_cycles = x[3:0];
      bit [31:0] o_irq_next = x[31:0];

      x <= xorshift64star(x, COMPUTATION_COMPLEXITY * 1000000);
      wait_n_cycles(int'(wait_cycles));  // 0 to 7 cycles extra delay
      o_irq <= o_irq_next;

      $display("[cpu_%0d] CPU o_irq = 0x%08x", cpu_index, o_irq_next);
    end
  end

endmodule
