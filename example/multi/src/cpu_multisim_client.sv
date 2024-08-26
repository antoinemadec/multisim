module cpu_multisim_client;

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

    wait (transactions_done);
    repeat (2) @(posedge clk);
    $finish;
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
      .DATA_WIDTH(64)
  ) i_multisim_server_push (
      .clk        (clk),
      .server_name(server_name_cpu_to_noc),
      .data_rdy   (data_cpu_to_noc_rdy),
      .data_vld   (data_cpu_to_noc_vld),
      .data       (data_cpu_to_noc)
  );

  multisim_client_pull #(
      .DATA_WIDTH(64)
  ) i_multisim_server_pull (
      .clk        (clk),
      .server_name(server_name_noc_to_cpu),
      .data_rdy   (data_noc_to_cpu_rdy),
      .data_vld   (data_noc_to_cpu_vld),
      .data       (data_noc_to_cpu)
  );

endmodule
