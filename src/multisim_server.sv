import "DPI-C" function void multisim_server_start(string name);
import "DPI-C" function int multisim_server_get_data(
  input string name,
  output bit [63:0] data
);

module multisim_server (
    input bit clk,
    input string server_name,
    input bit data_rdy,
    output bit data_vld,
    output bit [63:0] data
);

  bit server_has_started = 0;
  initial begin
    wait (server_name != "");
    multisim_server_start(server_name);
    server_has_started = 1;
  end

  always @(posedge clk) begin
    bit [63:0] data_dpi;
    if (server_has_started && (!data_vld || data_rdy)) begin
      int data_vld_dpi;
      data_vld_dpi = multisim_server_get_data(server_name, data_dpi);
      data_vld <= data_vld_dpi[0];
      data <= data_dpi;
    end
  end

endmodule
