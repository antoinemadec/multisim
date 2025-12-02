module cpu_multisim_client ();
  bit clk = 0;
  always #1ns clk <= ~clk;

  bit    [31:0] irq_rx;
  bit    [31:0] irq_tx;
  bit     finish;

  bit    [31:0] cpu_index;
  string        server_name_cpu_to_loopback;
  string        server_name_loopback_to_cpu;
  string        server_name_finish;

  initial begin
    if (!$value$plusargs("CPU_INDEX=%d", cpu_index)) begin
      $fatal("+CPU_INDEX not set");
    end
    $sformat(server_name_cpu_to_loopback, "cpu_to_loopback_%0d", cpu_index);
    $sformat(server_name_loopback_to_cpu, "loopback_to_cpu_%0d", cpu_index);
    $sformat(server_name_finish, "finish_cpu_%0d", cpu_index);
  end

  cpu i_cpu (
      .clk      (clk),
      .cpu_index(cpu_index),
      .i_irq    (irq_rx),
      .o_irq    (irq_tx),
      .o_finish (finish)
  );

  multisim_client_quasi_static_push #(
      .SERVER_RUNTIME_DIRECTORY("../output_top"),
      .DATA_WIDTH(32)
  ) i_multisim_client_quasi_static_push (
      .clk        (clk),
      .server_name(server_name_cpu_to_loopback),
      .data       (irq_tx)
  );

  multisim_client_quasi_static_pull #(
      .SERVER_RUNTIME_DIRECTORY("../output_top"),
      .DATA_WIDTH(32)
  ) i_multisim_client_quasi_static_pull (
      .clk        (clk),
      .server_name(server_name_loopback_to_cpu),
      .data       (irq_rx)
  );

  multisim_client_quasi_static_push #(
      .SERVER_RUNTIME_DIRECTORY("../output_top"),
      .DATA_WIDTH(1)
  ) i_multisim_client_quasi_static_push_finish (
      .clk        (clk),
      .server_name(server_name_finish),
      .data       (finish)
  );

  //initial begin
  //  $dumpfile("dump.vcd");
  //  $dumpvars();
  //end

endmodule
