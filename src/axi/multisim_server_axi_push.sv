module multisim_server_axi_push #(
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

    // subordinate AXI interface

    input  axi_aw_t i_axi_s_aw,
    output bit      o_axi_s_awready,
    input  bit      i_axi_s_awvalid,

    input  axi_w_t i_axi_s_w,
    output bit     o_axi_s_wready,
    input  bit     i_axi_s_wvalid,

    output axi_b_t o_axi_s_b,
    input  bit     i_axi_s_bready,
    output bit     o_axi_s_bvalid,

    input  axi_ar_t i_axi_s_ar,
    output bit      o_axi_s_arready,
    input  bit      i_axi_s_arvalid,

    output axi_r_t o_axi_s_r,
    input  bit     i_axi_s_rready,
    output bit     o_axi_s_rvalid
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
  multisim_server_push #(
      .DATA_WIDTH($bits(axi_aw_t)),
      .DATA_IS_4STATE(DATA_IS_4STATE)
  ) i_multisim_server_push_axi_aw (
      .clk        (clk_gated),
      .server_name(server_name_axi_aw),
      .data_rdy   (o_axi_s_awready),
      .data_vld   (i_axi_s_awvalid),
      .data       (i_axi_s_aw)
  );

  // W
  multisim_server_push #(
      .DATA_WIDTH($bits(axi_w_t)),
      .DATA_IS_4STATE(DATA_IS_4STATE)
  ) i_multisim_server_push_axi_w (
      .clk        (clk_gated),
      .server_name(server_name_axi_w),
      .data_rdy   (o_axi_s_wready),
      .data_vld   (i_axi_s_wvalid),
      .data       (i_axi_s_w)
  );

  // B
  multisim_server_pull #(
      .DATA_WIDTH($bits(axi_b_t)),
      .DATA_IS_4STATE(DATA_IS_4STATE)
  ) i_multisim_server_pull_axi_b (
      .clk        (clk_gated),
      .server_name(server_name_axi_b),
      .data_rdy   (i_axi_s_bready),
      .data_vld   (o_axi_s_bvalid),
      .data       (o_axi_s_b)
  );

  // AR
  multisim_server_push #(
      .DATA_WIDTH($bits(axi_ar_t)),
      .DATA_IS_4STATE(DATA_IS_4STATE)
  ) i_multisim_server_push_axi_ar (
      .clk        (clk_gated),
      .server_name(server_name_axi_ar),
      .data_rdy   (o_axi_s_arready),
      .data_vld   (i_axi_s_arvalid),
      .data       (i_axi_s_ar)
  );

  // R
  multisim_server_pull #(
      .DATA_WIDTH($bits(axi_r_t)),
      .DATA_IS_4STATE(DATA_IS_4STATE)
  ) i_multisim_server_pull_axi_r (
      .clk        (clk_gated),
      .server_name(server_name_axi_r),
      .data_rdy   (i_axi_s_rready),
      .data_vld   (o_axi_s_rvalid),
      .data       (o_axi_s_r)
  );

endmodule
