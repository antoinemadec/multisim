`include "apb_pkg.sv"

module top
  import apb_pkg::*;
#(
    parameter int CPU_NB = 4
);

  bit clk = 0;
  always #1ns clk <= ~clk;

  apb_req_t apb_req[CPU_NB];
  apb_resp_t apb_resp[CPU_NB];
  bit apb_psel[CPU_NB];
  bit apb_penable[CPU_NB];
  bit apb_pready[CPU_NB];

  memory #(
      .CPU_NB(CPU_NB)
  ) i_memory (
      .clk            (clk),
      // subordinate APB interface
      .i_apb_s_req    (apb_req),
      .o_apb_s_resp   (apb_resp),
      .i_apb_s_psel   (apb_psel),
      .i_apb_s_penable(apb_penable),
      .o_apb_s_pready (apb_pready)
  );

  for (genvar cpu_idx = 0; cpu_idx < CPU_NB; cpu_idx++) begin : gen_cpu
`ifndef MULTISIM
    cpu i_cpu (
`else
    cpu_multisim_server i_cpu_multisim_server (
`endif
        .clk            (clk),
        .cpu_index      (cpu_idx),
        // manager APB interface
        .o_apb_m_req    (apb_req[cpu_idx]),
        .i_apb_m_resp   (apb_resp[cpu_idx]),
        .o_apb_m_psel   (apb_psel[cpu_idx]),
        .o_apb_m_penable(apb_penable[cpu_idx]),
        .i_apb_m_pready (apb_pready[cpu_idx])
    );
  end

  //initial begin
  //  $dumpfile("dump.vcd");
  //  $dumpvars();
  //end

endmodule
