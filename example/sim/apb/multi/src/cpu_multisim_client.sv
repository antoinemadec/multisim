`include "apb_pkg.sv"

module cpu_multisim_client ();
  import apb_pkg::*;

  bit clk = 0;
  always #1ns clk <= ~clk;

  apb_req_t         apb_req;
  apb_resp_t        apb_resp;
  bit               apb_psel;
  bit               apb_penable;
  bit               apb_pready;

  bit        [31:0] cpu_index;
  string            server_name;

  initial begin
    if (!$value$plusargs("CPU_INDEX=%d", cpu_index)) begin
      $fatal("+CPU_INDEX not set");
    end
    $sformat(server_name, "cpu_%0d", cpu_index);
  end

  cpu i_cpu (
      .clk            (clk),
      .cpu_index      (cpu_index),
      .o_apb_m_req    (apb_req),
      .i_apb_m_resp   (apb_resp),
      .o_apb_m_psel   (apb_psel),
      .o_apb_m_penable(apb_penable),
      .i_apb_m_pready (apb_pready)
  );

  multisim_client_apb_push #(
      .SERVER_RUNTIME_DIRECTORY("../output_top"),
      .apb_req_t(apb_req_t),
      .apb_resp_t(apb_resp_t)
  ) i_multisim_client_apb_push (
      .clk            (clk),
      .rst_n          (1),
      .server_name    (server_name),
      .i_apb_s_req    (apb_req),
      .o_apb_s_resp   (apb_resp),
      .i_apb_s_psel   (apb_psel),
      .i_apb_s_penable(apb_penable),
      .o_apb_s_pready (apb_pready)
  );

  //initial begin
  //  $dumpfile("dump.vcd");
  //  $dumpvars();
  //end

endmodule
