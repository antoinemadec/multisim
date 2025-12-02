module cpu_multisim_server
  import apb_pkg::*;
(
    input bit clk,
    input bit [31:0] cpu_index,

    // manager APB interface

    output apb_req_t o_apb_m_req,
    input apb_resp_t i_apb_m_resp,
    output bit o_apb_m_psel,
    output bit o_apb_m_penable,
    input bit i_apb_m_pready
);

  string server_name;
  initial begin
    $sformat(server_name, "cpu_%0d", cpu_index);
  end

  multisim_server_apb_pull #(
      .apb_req_t (apb_req_t),
      .apb_resp_t(apb_resp_t)
  ) i_multisim_server_apb_pull (
      .clk            (clk),
      .rst_n          (1),
      .server_name    (server_name),
      .o_apb_m_req    (o_apb_m_req),
      .i_apb_m_resp   (i_apb_m_resp),
      .o_apb_m_psel   (o_apb_m_psel),
      .o_apb_m_penable(o_apb_m_penable),
      .i_apb_m_pready (i_apb_m_pready)
  );

endmodule
