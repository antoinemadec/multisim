module cpu_multisim_client;

  bit clk = 0;
  always #1ns clk <= ~clk;

  bit data_rdy;
  bit data_vld;
  bit [63:0] data;
  bit transactions_done;

  bit [31:0] cpu_index;
  string server_name;

  initial begin
    if (!$value$plusargs("CPU_INDEX=%d", cpu_index)) begin
      $fatal("+CPU_INDEX not set");
    end
    $sformat(server_name, "cpu_%0d", cpu_index);

    wait (transactions_done);
    repeat (2) @(posedge clk);
    $finish;
  end

  cpu i_cpu (
      .clk              (clk),
      .cpu_index        (cpu_index),
      .data_rdy         (data_rdy),
      .data_vld         (data_vld),
      .data             (data),
      .transactions_done(transactions_done)
  );

  multisim_client #(
      .DATA_WIDTH(64)
  ) i_multisim_client (
      .clk        (clk),
      .server_name(server_name),
      .data_rdy   (data_rdy),
      .data_vld   (data_vld),
      .data       (data)
  );

endmodule
