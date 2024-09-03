module top #(
    parameter int CPU_NB = 4
);

  bit clk = 0;
  always #1ns clk <= ~clk;

  bit data_cpu_to_noc_rdy[CPU_NB];
  bit data_cpu_to_noc_vld[CPU_NB];
  bit [63:0] data_cpu_to_noc[CPU_NB];

  bit data_noc_to_cpu_rdy[CPU_NB];
  bit data_noc_to_cpu_vld[CPU_NB];
  bit [63:0] data_noc_to_cpu[CPU_NB];

  noc #(
      .CPU_NB(CPU_NB)
  ) i_noc (
      .clk                (clk),
      // cpu -> noc
      .data_cpu_to_noc_rdy(data_cpu_to_noc_rdy),
      .data_cpu_to_noc_vld(data_cpu_to_noc_vld),
      .data_cpu_to_noc    (data_cpu_to_noc),
      // noc -> cpu
      .data_noc_to_cpu_rdy(data_noc_to_cpu_rdy),
      .data_noc_to_cpu_vld(data_noc_to_cpu_vld),
      .data_noc_to_cpu    (data_noc_to_cpu)
  );

  for (genvar cpu_idx = 0; cpu_idx < CPU_NB; cpu_idx++) begin : gen_cpu
`ifndef MULTISIM
    cpu i_cpu (
`else
    cpu_multisim_server i_cpu_multisim_server (
`endif
        .clk                (clk),
        .cpu_index          (cpu_idx),
        // cpu -> noc
        .data_cpu_to_noc_rdy(data_cpu_to_noc_rdy[cpu_idx]),
        .data_cpu_to_noc_vld(data_cpu_to_noc_vld[cpu_idx]),
        .data_cpu_to_noc    (data_cpu_to_noc[cpu_idx]),
        // noc -> cpu
        .data_noc_to_cpu_rdy(data_noc_to_cpu_rdy[cpu_idx]),
        .data_noc_to_cpu_vld(data_noc_to_cpu_vld[cpu_idx]),
        .data_noc_to_cpu    (data_noc_to_cpu[cpu_idx]),
        .transactions_done  (  /* not used */)
    );
  end

  //initial begin
  //  $dumpfile("dump.vcd");
  //  $dumpvars();
  //end

endmodule
