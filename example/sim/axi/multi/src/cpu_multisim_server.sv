module cpu_multisim_server
  import axi_pkg::*;
(
    input bit clk,
    input bit [31:0] cpu_index,

    // manager AXI interface

    output axi_aw_t o_axi_m_aw,
    input  bit      i_axi_m_awready,
    output bit      o_axi_m_awvalid,

    output axi_w_t o_axi_m_w,
    input  bit     i_axi_m_wready,
    output bit     o_axi_m_wvalid,

    input  axi_b_t i_axi_m_b,
    output bit     o_axi_m_bready,
    input  bit     i_axi_m_bvalid,

    output axi_ar_t o_axi_m_ar,
    input  bit      i_axi_m_arready,
    output bit      o_axi_m_arvalid,

    input  axi_r_t i_axi_m_r,
    output bit     o_axi_m_rready,
    input  bit     i_axi_m_rvalid
);

  string server_name;
  initial begin
    $sformat(server_name, "cpu_%0d", cpu_index);
  end

  multisim_server_axi_pull #(
      .axi_aw_t(axi_aw_t),
      .axi_w_t (axi_w_t),
      .axi_b_t (axi_b_t),
      .axi_ar_t(axi_ar_t),
      .axi_r_t (axi_r_t)
  ) i_multisim_server_axi_pull (
      .clk            (clk),
      .rst_n          (1),
      .server_name    (server_name),
      .o_axi_m_aw     (o_axi_m_aw),
      .i_axi_m_awready(i_axi_m_awready),
      .o_axi_m_awvalid(o_axi_m_awvalid),
      .o_axi_m_w      (o_axi_m_w),
      .i_axi_m_wready (i_axi_m_wready),
      .o_axi_m_wvalid (o_axi_m_wvalid),
      .i_axi_m_b      (i_axi_m_b),
      .o_axi_m_bready (o_axi_m_bready),
      .i_axi_m_bvalid (i_axi_m_bvalid),
      .o_axi_m_ar     (o_axi_m_ar),
      .i_axi_m_arready(i_axi_m_arready),
      .o_axi_m_arvalid(o_axi_m_arvalid),
      .i_axi_m_r      (i_axi_m_r),
      .o_axi_m_rready (o_axi_m_rready),
      .i_axi_m_rvalid (i_axi_m_rvalid)
  );

endmodule
