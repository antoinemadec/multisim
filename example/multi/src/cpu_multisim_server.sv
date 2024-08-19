module cpu_multisim_server (
    input bit clk,
    input bit [31:0] cpu_index,
    input bit data_rdy,
    output bit data_vld,
    output bit [63:0] data
);

  string server_name;
  initial begin
    $sformat(server_name, "cpu_%0d", cpu_index);
  end

  multisim_server i_multisim_server (
      .clk        (clk),
      .server_name(server_name),
      .data_rdy   (data_rdy),
      .data_vld   (data_vld),
      .data       (data)
  );

endmodule
