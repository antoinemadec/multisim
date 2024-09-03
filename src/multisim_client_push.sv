`include "multisim_client_common_header.svh"

module multisim_client_push #(
    parameter string SERVER_RUNTIME_DIRECTORY = "../output_top",
    parameter int DATA_WIDTH = 64
) (
    input bit clk,
    input string server_name,
    output bit data_rdy,
    input bit data_vld,
    input bit [DATA_WIDTH-1:0] data
);

  `include "multisim_client_common.svh"

  initial begin
    data_rdy = 0;
    wait (server_name != "");
    connnect_to_server(SERVER_RUNTIME_DIRECTORY, server_name);
    data_rdy = 1;
  end

  bit [DATA_WIDTH-1:0] data_q;

  always @(posedge clk) begin
    if (data_vld && data_rdy) begin
      int data_rdy_dpi;
      data_rdy_dpi = multisim_client_send_data(server_name, data, DATA_WIDTH);
      data_rdy <= data_rdy_dpi[0];
      data_q   <= data;
    end
    if (!data_rdy) begin
      int data_rdy_dpi;
      data_rdy_dpi = multisim_client_send_data(server_name, data_q, DATA_WIDTH);
      data_rdy <= data_rdy_dpi[0];
    end
  end

endmodule
