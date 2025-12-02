module top #(
    parameter int CPU_NB = 4
);

  bit clk = 0;
  always #1ns clk <= ~clk;

  bit [31:0] irq_rx[CPU_NB];
  bit [31:0] irq_tx[CPU_NB];
  bit [CPU_NB-1:0] finish;

  irq_loopback #(
      .CPU_NB(CPU_NB)
  ) i_irq_loopback (
      .clk(clk),
      .i_irq(irq_tx),
      .o_irq(irq_rx),
      .i_finish(finish)
  );

  for (genvar cpu_idx = 0; cpu_idx < CPU_NB; cpu_idx++) begin : gen_cpu
`ifndef MULTISIM
    cpu i_cpu (
`else
    cpu_multisim_server i_cpu_multisim_server (
`endif
        .clk      (clk),
        .cpu_index(cpu_idx),
        .i_irq    (irq_rx[cpu_idx]),
        .o_irq    (irq_tx[cpu_idx]),
        .o_finish (finish[cpu_idx])
    );
  end

  //initial begin
  //  $dumpfile("dump.vcd");
  //  $dumpvars();
  //end

endmodule
