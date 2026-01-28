// This module waits DPI_DELAY_CYCLES in between a server(pull, push) sequence only.
// It enables better throughput when client sends read commands for instance.
//
// E.g.:
//    1. wait DPI_DELAY_CYCLES_INACTIVE cycles
//    2. pull command (DPI call)
//    3. push response (DPI call)
//    4. back to 2. with DPI_DELAY_CYCLES_ACTIVE cycles

module multisim_server_pull_then_push #(
    parameter int PULL_DATA_WIDTH = 64,
    parameter int PUSH_DATA_WIDTH = 64,
    parameter bit DATA_IS_4STATE = 0,  // set to 1 to use 4-state data
    // in emulation, calling DPI at every cycle impacts performance,
    // adding delays in between calls improves that a lot
    parameter int DPI_DELAY_CYCLES_INACTIVE = 1000,
    parameter int DPI_DELAY_CYCLES_ACTIVE = 10
) (
    input bit clk,
    // pull
    input string pull_server_name,
    input bit pull_data_rdy,
    output bit pull_data_vld,
    output logic [PULL_DATA_WIDTH-1:0] pull_data,
    // push
    input string push_server_name,
    output bit push_data_rdy,
    input bit push_data_vld,
    input logic [PUSH_DATA_WIDTH-1:0] push_data
);

  `include "multisim_server_common.svh"

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
    push_data_rdy = 0;
  end

  // gradually go back from active to inactive delay,
  // this gives time to client to push next transaction after previous one was finished
  function static int get_inactive_dpi_delay(input int current_delay);
    int next_delay;
    if (current_delay <= 0) begin
      next_delay = 1;
    end else begin
      next_delay = current_delay << 2;
    end
    return (next_delay < DPI_DELAY_CYCLES_INACTIVE) ? next_delay : DPI_DELAY_CYCLES_INACTIVE;
  endfunction

  int dpi_delay;
  always @(posedge clk) begin
    logic [PULL_DATA_WIDTH-1:0] pull_data_dpi;
    if (server_has_started && (!pull_data_vld || pull_data_rdy)) begin
      // pull
      int pull_data_vld_dpi;
      repeat (dpi_delay) begin
        pull_data_vld <= 0;
        @(posedge clk);
      end
      pull_data_vld_dpi =
          multisim_server_pull_packed(pull_server_name, pull_data_dpi, PULL_DATA_WIDTH);
      pull_data_vld <= pull_data_vld_dpi[0];
      pull_data <= pull_data_dpi;
      dpi_delay <= pull_data_vld_dpi[0] ? DPI_DELAY_CYCLES_ACTIVE : get_inactive_dpi_delay(
          dpi_delay
      );

      // DEBUG: performance
      // if (pull_data_vld_dpi[0] && dpi_delay != DPI_DELAY_CYCLES_INACTIVE) begin
      //   $display("BACK TO BACK: dpi_delay=%0d", dpi_delay);
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
        push_data_accepted =
            multisim_server_push_packed(push_server_name, push_data, PUSH_DATA_WIDTH);
        if (!push_data_accepted[0]) begin
          $display("WARNING: push_data wasn't accepted in %m");
        end
        push_data_rdy <= 0;
      end
    end
  end

endmodule
