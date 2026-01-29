`include "multisim_apb_fsm.sv"

module multisim_server_apb_push #(
    parameter type apb_req_t,
    parameter type apb_resp_t,
    parameter bit  DATA_IS_4STATE = 0  // set to 1 to use 4-state data
) (
    input bit clk,
    input bit rst_n,
    input string server_name,

    // subordinate APB interface

    input apb_req_t i_apb_s_req,
    output apb_resp_t o_apb_s_resp,
    input bit i_apb_s_psel,
    input bit i_apb_s_penable,
    output bit o_apb_s_pready
);

  string server_name_apb_req;
  string server_name_apb_resp;
  initial begin
`ifndef MULTISIM_EMULATION
    /* verilator lint_off WAITCONST */
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
      .i_apb_pready(o_apb_s_pready),
      .i_apb_psel  (i_apb_s_psel),
      .state       (state)
  );

  wire request_rdy;
  bit  request_vld;
  wire response_rdy = 1;
  wire response_vld;
  assign o_apb_s_pready = response_vld;

  always_comb begin
    case (state)
      IDLE: request_vld = 1'b0;
      SETUP: request_vld = 1'b1;
      ACCESS: begin
        if (request_rdy) request_vld = 1'b0;
      end
      default: request_vld = 1'b0;
    endcase
  end

  // request
  multisim_server_push #(
      .DATA_WIDTH($bits(apb_req_t)),
      .DATA_IS_4STATE(DATA_IS_4STATE)
  ) i_multisim_server_push_apb_req (
      .clk        (clk_gated),
      .server_name(server_name_apb_req),
      .data_rdy   (request_rdy),
      .data_vld   (request_vld),
      .data       (i_apb_s_req)
  );

  // response
  multisim_server_pull #(
      .DATA_WIDTH($bits(apb_resp_t)),
      .DATA_IS_4STATE(DATA_IS_4STATE)
  ) i_multisim_server_pull_apb_resp (
      .clk        (clk_gated),
      .server_name(server_name_apb_resp),
      .data_rdy   (response_rdy),
      .data_vld   (response_vld),
      .data       (o_apb_s_resp)
  );

endmodule
