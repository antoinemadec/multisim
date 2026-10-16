// There are 2 targets:
//  - SIMULATION (default): called from SV as DPI
//  - EMULATION: called from SV as DPI, with fixed size array (open array is not supported)
//    - ZEBU: EMULATION flavor for ZeBu, the server DPIs are ZEMI3 deferred DPIs

`ifndef MULTISIM_COMMON_SVH
`define MULTISIM_COMMON_SVH

// ZEBU implies EMULATION
`ifdef MULTISIM_ZEBU
`ifndef MULTISIM_EMULATION
`define MULTISIM_EMULATION
`endif
`endif

// default target is SIMULATION
`ifndef MULTISIM_EMULATION
`define MULTISIM_SIMULATION
`endif

// SIMULATION
//  - uses SV DPI
//  - uses open array for data handle: required by Verilator when using multiple sizes
`ifdef MULTISIM_SIMULATION
`define MULTISIM_SV_DPI
`define MULTISIM_SV_DPI_OPEN_ARRAY
`endif

// EMULATION
//  - uses SV DPI
//  - uses fixed size array for data handle: open array is not supported by Veloce
//  - does not support 4-state data
`ifdef MULTISIM_EMULATION
`define MULTISIM_SV_DPI
`define MULTISIM_4STATE_UNSUPPORTED
`endif

// Server modules: the same code for all targets, through these macros
//  - MULTISIM_SERVER_NAME_T: type of the server name ports
//  - MULTISIM_SERVER_PULL/PUSH(ret, server_name, data, data_width): call the pull/push DPI,
//    ret = MULTISIM_SUCCESS|MULTISIM_FAIL
//  - MULTISIM_SERVER_PULL/PUSH_DPI(server_name): process calling the DPI, ZEBU only
//
// ZEBU
//  - server modules are ZEMI3 transactors: ZeBu removes the DPIs with outputs from its other
//    DPI flows
//  - no string type: the server name is a packed bit [8*MULTISIM_SERVER_NAME_LEN-1:0] holding
//    the string literal
//  - pull/push are ZEMI3 deferred DPIs: the clocks keep running for MULTISIM_ZEBU_DPI_LATENCY
//    cycles while the host processes the call. ZEMI3 needs one deferred DPI per process and a
//    single data output: MULTISIM_SERVER_PULL/PUSH request the call to the MULTISIM_SERVER_*_DPI
//    process, then wait until the call count on top of its output reaches the request count
`ifdef MULTISIM_ZEBU
`ifndef MULTISIM_SERVER_NAME_LEN
`define MULTISIM_SERVER_NAME_LEN 32
`endif
`ifndef MULTISIM_ZEBU_DPI_LATENCY
`define MULTISIM_ZEBU_DPI_LATENCY 16
`endif

`define MULTISIM_SERVER_NAME_T bit [8*`MULTISIM_SERVER_NAME_LEN-1:0]

`define MULTISIM_SERVER_PULL(ret, server_name, data, data_width) \
  begin \
    pull_call_cnt <= pull_call_cnt + 1; \
    pull_call <= 1; \
    @(posedge clk); \
    pull_call <= 0; \
    while (pull_status_data[PullStatusWidth-1-:31] != pull_call_cnt) @(posedge clk); \
    ret = pull_status_data[PullData32bWidth*32]; \
    data = pull_status_data[PULL_DATA_WIDTH-1:0]; \
  end

`define MULTISIM_SERVER_PUSH(ret, server_name, data, data_width) \
  begin \
    push_data_dpi <= data; \
    push_call_cnt <= push_call_cnt + 1; \
    push_call <= 1; \
    @(posedge clk); \
    push_call <= 0; \
    while (push_status[PushStatusWidth-1-:31] != push_call_cnt) @(posedge clk); \
    ret = push_status[0]; \
  end

`define MULTISIM_SERVER_PULL_DPI(server_name) \
  bit pull_call; \
  bit [30:0] pull_call_cnt; \
  bit [PullStatusWidth-1:0] pull_status_data;  /* written by the deferred DPI only, no reset */ \
  always @(posedge clk) begin \
    if (pull_call) begin \
      fork \
        begin \
          automatic bit [PullStatusWidth-1:0] status_data; \
          automatic bit done = 0; \
          multisim_server_pull_zebu(status_data, done, server_name, PULL_DATA_WIDTH); \
          repeat (`MULTISIM_ZEBU_DPI_LATENCY) @(posedge clk); \
          wait (done == 1); \
          pull_status_data <= status_data; \
        end \
      join_none \
    end \
  end

`define MULTISIM_SERVER_PUSH_DPI(server_name) \
  bit push_call; \
  bit [30:0] push_call_cnt; \
  bit [PushData32bWidth*32-1:0] push_data_dpi; \
  bit [PushStatusWidth-1:0] push_status;  /* written by the deferred DPI only, no reset */ \
  always @(posedge clk) begin \
    if (push_call) begin \
      fork \
        begin \
          automatic bit [PushStatusWidth-1:0] status; \
          automatic bit done = 0; \
          multisim_server_push_zebu(status, done, server_name, push_data_dpi, PUSH_DATA_WIDTH); \
          repeat (`MULTISIM_ZEBU_DPI_LATENCY) @(posedge clk); \
          wait (done == 1); \
          push_status <= status; \
        end \
      join_none \
    end \
  end
`else
`define MULTISIM_SERVER_NAME_T string

`define MULTISIM_SERVER_PULL(ret, server_name, data, data_width) \
  ret = multisim_server_pull_packed(server_name, data, data_width)

`define MULTISIM_SERVER_PUSH(ret, server_name, data, data_width) \
  ret = multisim_server_push_packed(server_name, data, data_width)

`define MULTISIM_SERVER_PULL_DPI(server_name)
`define MULTISIM_SERVER_PUSH_DPI(server_name)
`endif

`endif
