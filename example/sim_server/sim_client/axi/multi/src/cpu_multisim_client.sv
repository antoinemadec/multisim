`include "axi_pkg.sv"

module cpu_multisim_client ();
  import axi_pkg::*;

  bit clk = 0;
  always #1ns clk <= ~clk;

  axi_aw_t        axi_aw;
  bit             axi_awready;
  bit             axi_awvalid;
  axi_w_t         axi_w;
  bit             axi_wready;
  bit             axi_wvalid;
  axi_b_t         axi_b;
  bit             axi_bready;
  bit             axi_bvalid;
  axi_ar_t        axi_ar;
  bit             axi_arready;
  bit             axi_arvalid;
  axi_r_t         axi_r;
  bit             axi_rready;
  bit             axi_rvalid;

  bit      [31:0] cpu_index;
  string          server_name;

  initial begin
    if (!$value$plusargs("CPU_INDEX=%d", cpu_index)) begin
      $fatal("+CPU_INDEX not set");
    end
    $sformat(server_name, "cpu_%0d", cpu_index);
  end

  cpu i_cpu (
      .clk            (clk),
      .cpu_index      (cpu_index),
      .o_axi_m_aw     (axi_aw),
      .i_axi_m_awready(axi_awready),
      .o_axi_m_awvalid(axi_awvalid),
      .o_axi_m_w      (axi_w),
      .i_axi_m_wready (axi_wready),
      .o_axi_m_wvalid (axi_wvalid),
      .i_axi_m_b      (axi_b),
      .o_axi_m_bready (axi_bready),
      .i_axi_m_bvalid (axi_bvalid),
      .o_axi_m_ar     (axi_ar),
      .i_axi_m_arready(axi_arready),
      .o_axi_m_arvalid(axi_arvalid),
      .i_axi_m_r      (axi_r),
      .o_axi_m_rready (axi_rready),
      .i_axi_m_rvalid (axi_rvalid)
  );

  multisim_client_axi_push #(
`ifdef MULTISIM_4STATE
      .DATA_IS_4STATE(1),
`endif
      .axi_aw_t(axi_aw_t),
      .axi_w_t(axi_w_t),
      .axi_b_t(axi_b_t),
      .axi_ar_t(axi_ar_t),
      .axi_r_t(axi_r_t)
  ) i_multisim_client_axi_push (
      .clk                     (clk),
      .rst_n                   (1),
      .server_runtime_directory("../output_top"),
      .server_name             (server_name),
      .i_axi_s_aw              (axi_aw),
      .o_axi_s_awready         (axi_awready),
      .i_axi_s_awvalid         (axi_awvalid),
      .i_axi_s_w               (axi_w),
      .o_axi_s_wready          (axi_wready),
      .i_axi_s_wvalid          (axi_wvalid),
      .o_axi_s_b               (axi_b),
      .i_axi_s_bready          (axi_bready),
      .o_axi_s_bvalid          (axi_bvalid),
      .i_axi_s_ar              (axi_ar),
      .o_axi_s_arready         (axi_arready),
      .i_axi_s_arvalid         (axi_arvalid),
      .o_axi_s_r               (axi_r),
      .i_axi_s_rready          (axi_rready),
      .o_axi_s_rvalid          (axi_rvalid)
  );

  //initial begin
  //  $dumpfile("dump.vcd");
  //  $dumpvars();
  //end

endmodule
