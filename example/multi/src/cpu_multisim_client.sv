module cpu_multisim_client;

  // generate dummy client/server channels to see impact on performance
  parameter int EXTRA_DUMMY_CHANNELS = 0;

  bit clk = 0;
  always #1ns clk <= ~clk;

  // cpu -> noc
  bit data_cpu_to_noc_rdy;
  bit data_cpu_to_noc_vld;
  bit [63:0] data_cpu_to_noc;
  // noc -> cpu
  bit data_noc_to_cpu_rdy;
  bit data_noc_to_cpu_vld;
  bit [63:0] data_noc_to_cpu;
  bit transactions_done;

  bit [31:0] cpu_index;
  string server_name_cpu_to_noc;
  string server_name_noc_to_cpu;

  initial begin
    if (!$value$plusargs("CPU_INDEX=%d", cpu_index)) begin
      $fatal("+CPU_INDEX not set");
    end
    $sformat(server_name_cpu_to_noc, "cpu_to_noc_%0d", cpu_index);
    $sformat(server_name_noc_to_cpu, "noc_to_cpu_%0d", cpu_index);
  end

  cpu i_cpu (
      .clk                (clk),
      .cpu_index          (cpu_index),
      // cpu -> noc
      .data_cpu_to_noc_rdy(data_cpu_to_noc_rdy),
      .data_cpu_to_noc_vld(data_cpu_to_noc_vld),
      .data_cpu_to_noc    (data_cpu_to_noc),
      // noc -> cpu
      .data_noc_to_cpu_rdy(data_noc_to_cpu_rdy),
      .data_noc_to_cpu_vld(data_noc_to_cpu_vld),
      .data_noc_to_cpu    (data_noc_to_cpu),
      .transactions_done  (transactions_done)
  );

  multisim_client_push #(
      .SERVER_RUNTIME_DIRECTORY("../output_top"),
      .DATA_WIDTH(64)
  ) i_multisim_server_push (
      .clk        (clk),
      .server_name(server_name_cpu_to_noc),
      .data_rdy   (data_cpu_to_noc_rdy),
      .data_vld   (data_cpu_to_noc_vld),
      .data       (data_cpu_to_noc)
  );

  multisim_client_pull #(
      .SERVER_RUNTIME_DIRECTORY("../output_top"),
      .DATA_WIDTH(64)
  ) i_multisim_server_pull (
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

    multisim_client_push #(
        .SERVER_RUNTIME_DIRECTORY("../output_top"),
        .DATA_WIDTH(64)
    ) i_multisim_server_push (
        .clk(clk),
        .server_name(server_name_cpu_to_noc_dummy),
        .data_rdy(  /*unused*/),
        .data_vld(1),
        .data(64'hdeadbeef_cafedeca)
    );

    bit dummy_noc_to_cpu_vld;
    bit [63:0] dummy_noc_to_cpu;

    multisim_client_pull #(
        .SERVER_RUNTIME_DIRECTORY("../output_top"),
        .DATA_WIDTH(64)
    ) i_multisim_server_pull (
        .clk(clk),
        .server_name(server_name_noc_to_cpu_dummy),
        .data_rdy(1),
        .data_vld(dummy_noc_to_cpu_vld),
        .data(dummy_noc_to_cpu)
    );
  end

endmodule
