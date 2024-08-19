import "DPI-C" function int multisim_client_start(
  string server_name,
  string server_address, // FIXME: get this from server_name's file
  int server_port // FIXME: get this from server_name's file
);
import "DPI-C" function int multisim_client_send_data(input bit [63:0] data);


module multisim_client (
    input bit clk,
    input string server_name,
    input [31:0] server_port, // FIXME: get this from server_name's file
    output bit data_rdy,
    input bit data_vld,
    input bit [63:0] data
);

  bit [63:0] data_q;

  initial begin
    data_rdy = 1;
    wait (server_name != "");
    wait (server_port != 0);
    while (multisim_client_start(
        server_name, "127.0.0.1", server_port
    ) != 1) begin
      ;
    end
  end

  always @(posedge clk) begin
    if (data_vld && data_rdy) begin
      int data_rdy_dpi;
      data_rdy_dpi = multisim_client_send_data(data);
      data_rdy <= data_rdy_dpi[0];
      data_q   <= data;
    end
    if (!data_rdy) begin
      int data_rdy_dpi;
      data_rdy_dpi = multisim_client_send_data(data_q);
      data_rdy <= data_rdy_dpi[0];
    end
  end

endmodule
