module multisim_server_axi_pull #(
    parameter type axi_aw_t,
    parameter type axi_w_t,
    parameter type axi_b_t,
    parameter type axi_ar_t,
    parameter type axi_r_t,
    parameter bit  DATA_IS_4STATE = 0  // set to 1 to use 4-state data
) (
    input bit clk,
    input bit rst_n,
    input string server_name,

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

  string server_name_axi_aw;
  string server_name_axi_w;
  string server_name_axi_b;
  string server_name_axi_ar;
  string server_name_axi_r;
  initial begin
`ifndef MULTISIM_EMULATION
    /* verilator lint_off WAITCONST */
    wait (server_name != "");
`endif
    $sformat(server_name_axi_aw, "%0s_axi_aw", server_name);
    $sformat(server_name_axi_w, "%0s_axi_w", server_name);
    $sformat(server_name_axi_b, "%0s_axi_b", server_name);
    $sformat(server_name_axi_ar, "%0s_axi_ar", server_name);
    $sformat(server_name_axi_r, "%0s_axi_r", server_name);
  end

  wire clk_gated;
  assign clk_gated = clk & rst_n;

  // AW
  multisim_server_pull #(
      .DATA_WIDTH($bits(axi_aw_t)),
      .DATA_IS_4STATE(DATA_IS_4STATE)
  ) i_multisim_server_pull_axi_aw (
      .clk        (clk_gated),
      .server_name(server_name_axi_aw),
      .data_rdy   (i_axi_m_awready),
      .data_vld   (o_axi_m_awvalid),
      .data       (o_axi_m_aw)
  );

  // W
  multisim_server_pull #(
      .DATA_WIDTH($bits(axi_w_t)),
      .DATA_IS_4STATE(DATA_IS_4STATE)
  ) i_multisim_server_pull_axi_w (
      .clk        (clk_gated),
      .server_name(server_name_axi_w),
      .data_rdy   (i_axi_m_wready),
      .data_vld   (o_axi_m_wvalid),
      .data       (o_axi_m_w)
  );

  // B
  multisim_server_push #(
      .DATA_WIDTH($bits(axi_b_t)),
      .DATA_IS_4STATE(DATA_IS_4STATE)
  ) i_multisim_server_push_axi_b (
      .clk        (clk_gated),
      .server_name(server_name_axi_b),
      .data_rdy   (o_axi_m_bready),
      .data_vld   (i_axi_m_bvalid),
      .data       (i_axi_m_b)
  );

  // AR
  multisim_server_pull #(
      .DATA_WIDTH($bits(axi_ar_t)),
      .DATA_IS_4STATE(DATA_IS_4STATE)
  ) i_multisim_server_pull_axi_ar (
      .clk        (clk_gated),
      .server_name(server_name_axi_ar),
      .data_rdy   (i_axi_m_arready),
      .data_vld   (o_axi_m_arvalid),
      .data       (o_axi_m_ar)
  );

  // R
  multisim_server_push #(
      .DATA_WIDTH($bits(axi_r_t)),
      .DATA_IS_4STATE(DATA_IS_4STATE)
  ) i_multisim_server_push_axi_r (
      .clk        (clk_gated),
      .server_name(server_name_axi_r),
      .data_rdy   (o_axi_m_rready),
      .data_vld   (i_axi_m_rvalid),
      .data       (i_axi_m_r)
  );

endmodule
