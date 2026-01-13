module multisim_server_pull #(
    parameter int DATA_WIDTH = 64,
    // in emulation, calling DPI at every cycle impacts performance,
    // adding delays in between calls improves that a lot
    parameter int DPI_DELAY_CYCLES_INACTIVE = `ifdef MULTISIM_EMULATION 1000 `else 0 `endif,
    parameter int DPI_DELAY_CYCLES_ACTIVE = 0
) (
    input bit clk,
    input string server_name,
    input bit data_rdy,
    output bit data_vld,
    output bit [DATA_WIDTH-1:0] data
);

  localparam PULL_DATA_WIDTH = DATA_WIDTH;
  localparam PUSH_DATA_WIDTH = DATA_WIDTH;
  `include "multisim_server_common.svh"

  bit server_has_started = 0;
  initial begin
    multisim_server_start(server_name);
    server_has_started = 1;
  end

  int dpi_delay;
  always @(posedge clk) begin
    bit [DATA_WIDTH-1:0] data_dpi;
    if (server_has_started && (!data_vld || data_rdy)) begin
      int data_vld_dpi;
      repeat (dpi_delay) begin
        data_vld <= 0;
        @(posedge clk);
      end
      data_vld_dpi = multisim_server_pull_packed(server_name, data_dpi, DATA_WIDTH);
      data_vld <= data_vld_dpi[0];
      data <= data_dpi;
      dpi_delay <= data_vld_dpi[0] ? DPI_DELAY_CYCLES_ACTIVE : DPI_DELAY_CYCLES_INACTIVE;
    end
  end

endmodule
