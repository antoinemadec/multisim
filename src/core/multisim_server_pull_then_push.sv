`include "multisim_common.svh"

// This module waits DPI_DELAY_CYCLES in between a server(pull, push) sequence only.
// It enables better throughput when client sends read commands for instance.
//
// E.g.:
//    1. wait DPI_DELAY_CYCLES_INACTIVE cycles
//    2. pull command (DPI call)
//    3. push response (DPI call)
//    4. back to 2. with DPI_DELAY_CYCLES_ACTIVE cycles, see get_dpi_delay()

module multisim_server_pull_then_push #(
    parameter int PULL_DATA_WIDTH = 64,
    parameter int PUSH_DATA_WIDTH = 64,
    parameter bit DATA_IS_4STATE = 0,  // set to 1 to use 4-state data
    // in emulation, calling DPI at every cycle impacts performance,
    // adding delays in between calls improves that a lot
    parameter int DPI_DELAY_CYCLES_INACTIVE = 1000,
    parameter int DPI_DELAY_CYCLES_ACTIVE = 10,
    // empty pulls at DPI_DELAY_CYCLES_ACTIVE after a transaction, before the ramp to
    // DPI_DELAY_CYCLES_INACTIVE: low latency for a client sending its next command
    parameter int DPI_GRACE_PULLS = 8
) (
    input bit clk,
    // pull
    input `MULTISIM_SERVER_NAME_T pull_server_name,
    input bit pull_data_rdy,
    output bit pull_data_vld,
    output logic [PULL_DATA_WIDTH-1:0] pull_data,
    // push
    input `MULTISIM_SERVER_NAME_T push_server_name,
    output bit push_data_rdy,
    input bit push_data_vld,
    input logic [PUSH_DATA_WIDTH-1:0] push_data
);

  `include "multisim_server_common.svh"
  `MULTISIM_SERVER_PULL_DPI(pull_server_name)
  `MULTISIM_SERVER_PUSH_DPI(push_server_name)

  bit server_has_started = 0;
  initial begin
`ifndef MULTISIM_EMULATION
    /* verilator lint_off WAITCONST */
    wait (pull_server_name != "");
    wait (push_server_name != "");
`endif
    multisim_server_start(pull_server_name);
    multisim_server_start(push_server_name);
    server_has_started = 1;
  end

  // delay before the next pull, after empty_pulls empty pulls in a row (0: after a transaction):
  //  - DPI_DELAY_CYCLES_ACTIVE for the first DPI_GRACE_PULLS empty pulls
  //  - then gradually go back to DPI_DELAY_CYCLES_INACTIVE (x4 per empty pull),
  //    this gives time to client to push next transaction after previous one was finished
  localparam int RampMaxSteps = 16;  // 4**16 = 2**32: any int delay has reached the cap
  function static int get_dpi_delay(input int empty_pulls);
    int ramp_steps;
    longint next_delay;
    ramp_steps = empty_pulls - DPI_GRACE_PULLS;
    if (ramp_steps <= 0) begin
      return DPI_DELAY_CYCLES_ACTIVE;
    end
    if (ramp_steps > RampMaxSteps) begin
      return DPI_DELAY_CYCLES_INACTIVE;
    end
    if (DPI_DELAY_CYCLES_ACTIVE <= 0) begin
      next_delay = longint'(1) << (2 * (ramp_steps - 1));
    end else begin
      next_delay = longint'(DPI_DELAY_CYCLES_ACTIVE) << (2 * ramp_steps);
    end
    return (next_delay < DPI_DELAY_CYCLES_INACTIVE) ? int'(next_delay) : DPI_DELAY_CYCLES_INACTIVE;
  endfunction

  int empty_pulls = DPI_GRACE_PULLS;
  always @(posedge clk) begin
    logic [PULL_DATA_WIDTH-1:0] pull_data_dpi;
    if (server_has_started && (!pull_data_vld || pull_data_rdy)) begin
      // pull
      int pull_data_vld_dpi;
      repeat (get_dpi_delay(empty_pulls)) begin
        pull_data_vld <= 0;
        @(posedge clk);
      end
      `MULTISIM_SERVER_PULL(pull_data_vld_dpi, pull_server_name, pull_data_dpi, PULL_DATA_WIDTH);
      pull_data_vld <= pull_data_vld_dpi[0];
      pull_data <= pull_data_dpi;
      if (pull_data_vld_dpi[0]) begin
        empty_pulls <= 0;
      end else if (empty_pulls <= DPI_GRACE_PULLS + RampMaxSteps) begin
        empty_pulls <= empty_pulls + 1;
      end

      // DEBUG: performance
      // if (pull_data_vld_dpi[0] && get_dpi_delay(empty_pulls) != DPI_DELAY_CYCLES_INACTIVE) begin
      //   $display("BACK TO BACK: empty_pulls=%0d", empty_pulls);
      // end

      // push
      if (pull_data_vld_dpi[0]) begin
        int push_data_accepted;
        @(posedge clk);
        pull_data_vld <= 0;
        push_data_rdy <= 1;
        @(posedge clk);
        while (!push_data_vld) begin
          @(posedge clk);
        end
        push_data_rdy <= 0;  // the call can take cycles (ZEBU)
        `MULTISIM_SERVER_PUSH(push_data_accepted, push_server_name, push_data, PUSH_DATA_WIDTH);
        if (!push_data_accepted[0]) begin
          $display("WARNING: push_data wasn't accepted in %m");
        end
      end
    end
  end

endmodule
