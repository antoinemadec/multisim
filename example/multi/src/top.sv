module top #(
    parameter int CPU_NB = 4
);

  bit clk = 0;
  always #1ns clk <= ~clk;

  bit data_rdy[CPU_NB];
  bit data_vld[CPU_NB];
  bit [63:0] data[CPU_NB];

  noc #(
      .CPU_NB(CPU_NB)
  ) i_noc (
      .clk     (clk),
      .data_rdy(data_rdy),
      .data_vld(data_vld),
      .data    (data)
  );

  for (genvar cpu_idx = 0; cpu_idx < CPU_NB; cpu_idx++) begin : gen_cpu
    bit cpu_data_rdy;
    bit cpu_data_vld;
    bit [63:0] cpu_data;

    assign cpu_data_rdy = data_rdy[cpu_idx];
    assign data_vld[cpu_idx] = cpu_data_vld;
    assign data[cpu_idx] = cpu_data;

    cpu_multisim_server i_cpu (
        .clk      (clk),
        .cpu_index(cpu_idx),
        .data_rdy (cpu_data_rdy),
        .data_vld (cpu_data_vld),
        .data     (cpu_data)
    );
  end

endmodule
