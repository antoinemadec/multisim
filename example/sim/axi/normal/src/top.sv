`include "axi_pkg.sv"

module top
  import axi_pkg::*;
#(
    parameter int CPU_NB = 4
);

  bit clk = 0;
  always #1ns clk <= ~clk;

  axi_aw_t axi_aw     [CPU_NB];
  bit      axi_awready[CPU_NB];
  bit      axi_awvalid[CPU_NB];
  axi_w_t  axi_w      [CPU_NB];
  bit      axi_wready [CPU_NB];
  bit      axi_wvalid [CPU_NB];
  axi_b_t  axi_b      [CPU_NB];
  bit      axi_bready [CPU_NB];
  bit      axi_bvalid [CPU_NB];
  axi_ar_t axi_ar     [CPU_NB];
  bit      axi_arready[CPU_NB];
  bit      axi_arvalid[CPU_NB];
  axi_r_t  axi_r      [CPU_NB];
  bit      axi_rready [CPU_NB];
  bit      axi_rvalid [CPU_NB];

  memory #(
      .CPU_NB(CPU_NB)
  ) i_memory (
      .clk            (clk),
      .i_axi_s_aw     (axi_aw),
      .o_axi_s_awready(axi_awready),
      .i_axi_s_awvalid(axi_awvalid),

      .i_axi_s_w     (axi_w),
      .o_axi_s_wready(axi_wready),
      .i_axi_s_wvalid(axi_wvalid),

      .o_axi_s_b     (axi_b),
      .i_axi_s_bready(axi_bready),
      .o_axi_s_bvalid(axi_bvalid),

      .i_axi_s_ar     (axi_ar),
      .o_axi_s_arready(axi_arready),
      .i_axi_s_arvalid(axi_arvalid),

      .o_axi_s_r     (axi_r),
      .i_axi_s_rready(axi_rready),
      .o_axi_s_rvalid(axi_rvalid)
  );

  for (genvar cpu_idx = 0; cpu_idx < CPU_NB; cpu_idx++) begin : gen_cpu
`ifndef MULTISIM
    cpu i_cpu (
`else
    cpu_multisim_server i_cpu_multisim_server (
`endif
        .clk      (clk),
        .cpu_index(cpu_idx),

        // manager AXI interface

        .o_axi_m_aw     (axi_aw[cpu_idx]),
        .i_axi_m_awready(axi_awready[cpu_idx]),
        .o_axi_m_awvalid(axi_awvalid[cpu_idx]),

        .o_axi_m_w     (axi_w[cpu_idx]),
        .i_axi_m_wready(axi_wready[cpu_idx]),
        .o_axi_m_wvalid(axi_wvalid[cpu_idx]),

        .i_axi_m_b     (axi_b[cpu_idx]),
        .o_axi_m_bready(axi_bready[cpu_idx]),
        .i_axi_m_bvalid(axi_bvalid[cpu_idx]),

        .o_axi_m_ar     (axi_ar[cpu_idx]),
        .i_axi_m_arready(axi_arready[cpu_idx]),
        .o_axi_m_arvalid(axi_arvalid[cpu_idx]),

        .i_axi_m_r     (axi_r[cpu_idx]),
        .o_axi_m_rready(axi_rready[cpu_idx]),
        .i_axi_m_rvalid(axi_rvalid[cpu_idx])
    );
  end

  //initial begin
  //  $dumpfile("dump.vcd");
  //  $dumpvars();
  //end

endmodule
