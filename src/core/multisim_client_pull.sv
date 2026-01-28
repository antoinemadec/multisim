module multisim_client_pull #(
    parameter int DATA_WIDTH = 64,
    parameter bit DATA_IS_4STATE = 0  // set to 1 to use 4-state data
) (
    input bit clk,
    input string server_runtime_directory,
    input string server_name,
    input bit data_rdy,
    output bit data_vld,
    output logic [DATA_WIDTH-1:0] data
);

  localparam PULL_DATA_WIDTH = DATA_WIDTH;
  localparam PUSH_DATA_WIDTH = DATA_WIDTH;
  `include "multisim_client_common.svh"

  initial begin
    data_vld = 0;
`ifndef MULTISIM_EMULATION
    /* verilator lint_off WAITCONST */
    wait (server_runtime_directory != "");
    wait (server_name != "");
`endif
    multisim_client_start(server_runtime_directory, server_name);
  end

  always @(posedge clk) begin
    logic [DATA_WIDTH-1:0] data_dpi;
    if (!data_vld || data_rdy) begin
      int data_vld_dpi;
      data_vld_dpi = multisim_client_pull_packed(server_name, data_dpi, DATA_WIDTH);
      data_vld <= data_vld_dpi[0];
      data <= data_dpi;
    end
  end

endmodule
