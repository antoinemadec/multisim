`include "multisim_common.svh"

module multisim_server_push #(
    parameter int DATA_WIDTH = 64,
    parameter bit DATA_IS_4STATE = 0  // set to 1 to use 4-state data
) (
    input bit clk,
    input `MULTISIM_SERVER_NAME_T server_name,
    output bit data_rdy,
    input bit data_vld,
    input logic [DATA_WIDTH-1:0] data
);

  localparam PULL_DATA_WIDTH = DATA_WIDTH;
  localparam PUSH_DATA_WIDTH = DATA_WIDTH;
  `include "multisim_server_common.svh"
  `MULTISIM_SERVER_PUSH_DPI(server_name)


  bit server_has_started = 0;
  initial begin
`ifndef MULTISIM_EMULATION
    /* verilator lint_off WAITCONST */
    wait (server_name != "");
`endif
    multisim_server_start(server_name);
    server_has_started = 1;
`ifdef MULTISIM_ZEBU
    data_rdy <= 1;  // ZEMI3: no mix of blocking and non-blocking assignments
`else
    data_rdy = 1;
`endif
  end

  logic [DATA_WIDTH-1:0] data_q;

  always @(posedge clk) begin
    if (server_has_started) begin
      if (data_vld && data_rdy) begin
        int data_rdy_dpi;
        // the call can take cycles (ZEBU)
        data_rdy <= 0;
        data_q   <= data;
        `MULTISIM_SERVER_PUSH(data_rdy_dpi, server_name, data, DATA_WIDTH);
        data_rdy <= data_rdy_dpi[0];
      end else if (!data_rdy) begin
        int data_rdy_dpi;
        `MULTISIM_SERVER_PUSH(data_rdy_dpi, server_name, data_q, DATA_WIDTH);
        data_rdy <= data_rdy_dpi[0];
      end
    end
  end

endmodule
