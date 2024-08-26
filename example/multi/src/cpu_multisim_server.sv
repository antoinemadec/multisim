module cpu_multisim_server (
    input bit clk,
    input bit [31:0] cpu_index,
    // cpu -> noc
    input bit data_cpu_to_noc_rdy,
    output bit data_cpu_to_noc_vld,
    output bit [63:0] data_cpu_to_noc,
    // noc -> cpu
    output bit data_noc_to_cpu_rdy,
    input bit data_noc_to_cpu_vld,
    input bit [63:0] data_noc_to_cpu,
    output bit transactions_done // TODO: always 0
);

  string server_name_cpu_to_noc;
  string server_name_noc_to_cpu;
  initial begin
    $sformat(server_name_cpu_to_noc, "cpu_to_noc_%0d", cpu_index);
    $sformat(server_name_noc_to_cpu, "noc_to_cpu_%0d", cpu_index);
  end

  // TODO: always 0
  assign transactions_done = 0;

  multisim_server_pull #(
      .DATA_WIDTH(64)
  ) i_multisim_server_pull (
      .clk        (clk),
      .server_name(server_name_cpu_to_noc),
      .data_rdy   (data_cpu_to_noc_rdy),
      .data_vld   (data_cpu_to_noc_vld),
      .data       (data_cpu_to_noc)
  );

  multisim_server_push #(
      .DATA_WIDTH(64)
  ) i_multisim_server_push (
      .clk        (clk),
      .server_name(server_name_noc_to_cpu),
      .data_rdy   (data_noc_to_cpu_rdy),
      .data_vld   (data_noc_to_cpu_vld),
      .data       (data_noc_to_cpu)
  );

endmodule
