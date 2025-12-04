module top;

  reg clk;
  // tbx clkgen
  initial begin
    clk = 0;
    forever #1 clk = ~clk;
  end

  //-----------------------------------------------------------
  // exit
  //-----------------------------------------------------------
  bit exit;

  multisim_server_pull #(
      .DATA_WIDTH(1)
  ) i_multisim_server_pull_exit (
      .clk        (clk),
      .server_name("exit"),
      .data_rdy   (1),
      .data_vld   (exit),
      .data       (/*unused*/)
  );

  always @(posedge clk) begin
    if (exit) begin
      $display("exit");
      $finish;
    end
  end

  //-----------------------------------------------------------
  // loopback: 64b data
  //-----------------------------------------------------------
  bit [63:0] rx64_data;
  bit rx64_data_vld;

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
