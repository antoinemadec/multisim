module top;

  reg clk;
  // tbx clkgen
  initial begin
    clk = 0;
    forever #1 clk = ~clk;
  end

  //-----------------------------------------------------------
  // loopback 1: 32b data
  //-----------------------------------------------------------
  bit [31:0] rx32_data;
  bit [31:0] rx32_data_vld;

  multisim_server_pull #(
      .DATA_WIDTH(32)
  ) i_multisim_server_pull32 (
      .clk        (clk),
      .server_name("rx32"),
      .data_rdy   (1),
      .data_vld   (rx32_data_vld),
      .data       (rx32_data)
  );

  multisim_server_push #(
      .DATA_WIDTH(32)
  ) i_multisim_server_push32 (
      .clk        (clk),
      .server_name("tx32"),
      .data_rdy   (/*unused*/),
      .data_vld   (rx32_data_vld),
      .data       (rx32_data)
  );

  //-----------------------------------------------------------
  // loopback 2: 64b data
  //-----------------------------------------------------------
  bit [63:0] rx64_data;
  bit [63:0] rx64_data_vld;

  multisim_server_pull #(
      .DATA_WIDTH(64)
  ) i_multisim_server_pull64 (
      .clk        (clk),
      .server_name("rx64"),
      .data_rdy   (1),
      .data_vld   (rx64_data_vld),
      .data       (rx64_data)
  );

  multisim_server_push #(
      .DATA_WIDTH(64)
  ) i_multisim_server_push64 (
      .clk        (clk),
      .server_name("tx64"),
      .data_rdy   (/*unused*/),
      .data_vld   (rx64_data_vld),
      .data       (rx64_data)
  );

endmodule
