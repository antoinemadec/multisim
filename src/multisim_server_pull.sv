module multisim_server_pull #(
    parameter int DATA_WIDTH = 64
) (
    input bit clk,
    input string server_name,
    input bit data_rdy,
    output bit data_vld,
    output bit [DATA_WIDTH-1:0] data
);

  `include "multisim_server_common.svh"

  bit server_has_started = 0;
  initial begin
    wait (server_name != "");
    multisim_server_start(server_name);
    server_has_started = 1;
  end

  always @(posedge clk) begin
    bit [DATA_WIDTH-1:0] data_dpi;
    if (server_has_started && (!data_vld || data_rdy)) begin
      int data_vld_dpi;
      data_vld_dpi = multisim_server_get_data(server_name, data_dpi, DATA_WIDTH);
      data_vld <= data_vld_dpi[0];
      data <= data_dpi;
    end
  end

endmodule
