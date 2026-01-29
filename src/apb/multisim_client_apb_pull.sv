`include "multisim_apb_fsm.sv"

module multisim_client_apb_pull #(
    parameter type apb_req_t,
    parameter type apb_resp_t,
    parameter bit  DATA_IS_4STATE = 0  // set to 1 to use 4-state data
) (
    input bit clk,
    input bit rst_n,
    input string server_runtime_directory,
    input string server_name,

    // manager APB interface

    output apb_req_t o_apb_m_req,
    input apb_resp_t i_apb_m_resp,
    output bit o_apb_m_psel,
    output bit o_apb_m_penable,
    input bit i_apb_m_pready
);

  string server_name_apb_req;
  string server_name_apb_resp;
  initial begin
`ifndef MULTISIM_EMULATION
    /* verilator lint_off WAITCONST */
    wait (server_runtime_directory != "");
    wait (server_name != "");
`endif
    $sformat(server_name_apb_req, "%0s_apb_req", server_name);
    $sformat(server_name_apb_resp, "%0s_apb_resp", server_name);
  end

  wire clk_gated;
  assign clk_gated = clk & rst_n;

  multisim_apb_state_t state;

  multisim_apb_fsm i_multisim_apb_fsm (
      .clk         (clk),
      .rst_n       (rst_n),
      .i_apb_pready(i_apb_m_pready),
      .i_apb_psel  (request_vld),
      .state       (state)
  );

  bit request_rdy;
  wire request_vld;
  apb_req_t request_data;
  wire response_rdy;
  wire response_vld = i_apb_m_pready && (state == ACCESS);

  always_comb begin
    case (state)
      IDLE: request_rdy = 1'b1;
      SETUP: begin
        request_rdy = 1'b1;
        o_apb_m_req = request_data;
      end
      ACCESS: request_rdy = 1'b0;
      default: request_rdy = 1'b0;
    endcase
  end

  assign o_apb_m_psel = state != IDLE;
  assign o_apb_m_penable = state == ACCESS;

  // request
  multisim_client_pull #(
      .DATA_WIDTH($bits(apb_req_t)),
      .DATA_IS_4STATE(DATA_IS_4STATE)
  ) i_multisim_client_pull_apb_req (
      .clk                     (clk_gated),
      .server_runtime_directory(server_runtime_directory),
      .server_name             (server_name_apb_req),
      .data_rdy                (request_rdy),
      .data_vld                (request_vld),
      .data                    (request_data)
  );

  // response
  multisim_client_push #(
      .DATA_WIDTH($bits(apb_resp_t)),
      .DATA_IS_4STATE(DATA_IS_4STATE)
  ) i_multisim_client_push_apb_resp (
      .clk                     (clk_gated),
      .server_runtime_directory(server_runtime_directory),
      .server_name             (server_name_apb_resp),
      .data_rdy                (response_rdy),
      .data_vld                (response_vld),
      .data                    (i_apb_m_resp)
  );

endmodule
