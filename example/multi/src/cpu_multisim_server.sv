module cpu_multisim_server #(
    // generate dummy client/server channels to see impact on performance
    parameter int EXTRA_DUMMY_CHANNELS = 0
) (
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
    output bit transactions_done  // TODO: always 0
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

  // generate dummy client/server channels to see impact on performance
  for (
      genvar dummy_channel_idx = 0; dummy_channel_idx < EXTRA_DUMMY_CHANNELS; dummy_channel_idx++
  ) begin : gen_dummy_channels
    string server_name_cpu_to_noc_dummy;
    string server_name_noc_to_cpu_dummy;
    initial begin
      wait (server_name_cpu_to_noc != "");
      wait (server_name_noc_to_cpu != "");
      $sformat(server_name_cpu_to_noc_dummy, "%0s_dummy_channel_%0d", server_name_cpu_to_noc,
               dummy_channel_idx);
      $sformat(server_name_noc_to_cpu_dummy, "%0s_dummy_channel_%0d", server_name_noc_to_cpu,
               dummy_channel_idx);
    end

    bit dummy_cpu_to_noc_vld;
    bit [63:0] dummy_cpu_to_noc;

    multisim_server_pull #(
        .DATA_WIDTH(64)
    ) i_multisim_server_pull (
        .clk        (clk),
        .server_name(server_name_cpu_to_noc_dummy),
        .data_rdy   (1),
        .data_vld   (dummy_cpu_to_noc_vld),
        .data       (dummy_cpu_to_noc)
    );

    multisim_server_push #(
        .DATA_WIDTH(64)
    ) i_multisim_server_push (
        .clk        (clk),
        .server_name(server_name_noc_to_cpu_dummy),
        .data_rdy   (  /*unused*/),
        .data_vld   (1),
        .data       (64'hcafedeca_deadbeef)
    );
  end

endmodule
