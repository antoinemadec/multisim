module cpu_multisim_server (
    input bit clk,
    input bit [31:0] cpu_index,

    input bit [31:0] i_irq,
    output bit [31:0] o_irq,
    output bit o_finish
);

  string server_name_cpu_to_loopback;
  string server_name_loopback_to_cpu;
  string server_name_finish;

  initial begin
    $sformat(server_name_cpu_to_loopback, "cpu_to_loopback_%0d", cpu_index);
    $sformat(server_name_loopback_to_cpu, "loopback_to_cpu_%0d", cpu_index);
    $sformat(server_name_finish, "finish_cpu_%0d", cpu_index);
  end

  multisim_server_quasi_static_pull #(
      .DATA_WIDTH(32)
  ) i_multisim_server_quasi_static_pull (
      .clk        (clk),
      .server_name(server_name_cpu_to_loopback),
      .data       (o_irq)
  );

  multisim_server_quasi_static_push #(
      .DATA_WIDTH(32)
  ) i_multisim_server_quasi_static_push (
      .clk        (clk),
      .server_name(server_name_loopback_to_cpu),
      .data       (i_irq)
  );

  multisim_server_quasi_static_pull #(
      .DATA_WIDTH(1)
  ) i_multisim_server_quasi_static_pull_finish (
      .clk        (clk),
      .server_name(server_name_finish),
      .data       (o_finish)
  );

endmodule
