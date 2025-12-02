// Description: Loopback irqs

module irq_loopback #(
    parameter int CPU_NB = 4,
    parameter int TRANSACTION_NB = 1000
) (
    input bit clk,

    input  bit [31:0] i_irq[CPU_NB],
    output bit [31:0] o_irq[CPU_NB],
    output bit [CPU_NB-1:0] i_finish
);

  for (genvar cpu_idx = 0; cpu_idx < CPU_NB; cpu_idx++) begin : gen_cpu
    bit [31:0] i_irq_prev = 0;
    int received_irq_nb = 0;

    always_ff @(posedge clk) begin
      i_irq_prev <= i_irq[cpu_idx];
      if (received_irq_nb < TRANSACTION_NB) begin
        if (i_irq[cpu_idx] != i_irq_prev) begin
          o_irq[cpu_idx] <= i_irq[cpu_idx];
          $display("[cpu_%0d] IRQ_LOOPBACK irq = 0x%08x (%0d/%0d)", cpu_idx, i_irq[cpu_idx],
                   received_irq_nb, TRANSACTION_NB);
          received_irq_nb++;
        end
      end
    end
  end

  initial begin
    wait (i_finish == {CPU_NB{1'b1}});
    repeat (2) @(posedge clk);
    $finish;
  end

endmodule
