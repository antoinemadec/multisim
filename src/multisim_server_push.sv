module multisim_server_push #(
    parameter int DATA_WIDTH = 64
) (
    input bit clk,
    input string server_name,
    output bit data_rdy,
    input bit data_vld,
    input bit [DATA_WIDTH-1:0] data
);

  `include "multisim_server_common.svh"

  bit server_has_started = 0;
  initial begin
    wait (server_name != "");
    multisim_server_start(server_name);
    server_has_started = 1;
    data_rdy = 1;
  end

  bit [DATA_WIDTH-1:0] data_q;

  always @(posedge clk) begin
    if (server_has_started) begin
      if (data_vld && data_rdy) begin
        int data_rdy_dpi;
        data_rdy_dpi = multisim_server_send_data(server_name, data, DATA_WIDTH);
        data_rdy <= data_rdy_dpi[0];
        data_q   <= data;
      end
      if (!data_rdy) begin
        int data_rdy_dpi;
        data_rdy_dpi = multisim_server_send_data(server_name, data_q, DATA_WIDTH);
        data_rdy <= data_rdy_dpi[0];
      end
    end
  end

endmodule
