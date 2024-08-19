import "DPI-C" function void dpi_cpu_server_start(int idx);
import "DPI-C" function int dpi_cpu_server_get_data(
  int idx,
  output bit [63:0] data
);

module cpu_dpi_server (
    input bit clk,
    input bit [31:0] cpu_index,
    input bit data_rdy,
    output bit data_vld,
    output bit [63:0] data
);

  bit server_has_started = 0;
  initial begin
    dpi_cpu_server_start(cpu_index);
    server_has_started = 1;
  end

  always @(posedge clk) begin
    bit [63:0] data_dpi;
    if (server_has_started && (!data_vld || data_rdy)) begin
      int data_vld_dpi;
      data_vld_dpi = dpi_cpu_server_get_data(cpu_index, data_dpi);
      data_vld <= data_vld_dpi[0];
      data <= data_dpi;
    end
  end

endmodule
