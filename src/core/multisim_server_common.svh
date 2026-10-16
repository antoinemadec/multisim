`include "multisim_common.svh"

//-----------------------------------------------------------
// DPIs
//-----------------------------------------------------------
localparam int PullData32bWidth = (PULL_DATA_WIDTH + 31) / 32;
localparam int PushData32bWidth = (PUSH_DATA_WIDTH + 31) / 32;

`ifdef MULTISIM_ZEBU
// see MULTISIM_ZEBU in multisim_common.svh and multisim_server.cpp,
// the data output of pull/push is {call_count[30:0], ret} on top of the data
localparam int PullStatusWidth = PullData32bWidth * 32 + 32;
localparam int PushStatusWidth = 32;

import "DPI-C" multisim_server_start_zebu = function void multisim_server_start(
  input `MULTISIM_SERVER_NAME_T server_name
);

(* zemi3_delayed_dpi *)
import "DPI-C" function void multisim_server_pull_zebu(
  output bit [PullStatusWidth-1:0] status_data,
  output bit done,
  input `MULTISIM_SERVER_NAME_T server_name,
  input int data_width
);

(* zemi3_delayed_dpi *)
import "DPI-C" function void multisim_server_push_zebu(
  output bit [PushStatusWidth-1:0] status,
  output bit done,
  input `MULTISIM_SERVER_NAME_T server_name,
  input bit [PushData32bWidth*32-1:0] data,
  input int data_width
);
`else
import "DPI-C" function void multisim_server_start(string server_name);

import "DPI-C" function int multisim_server_pull(
  input string server_name,
`ifdef MULTISIM_SV_DPI_OPEN_ARRAY
  output bit [31:0] data[],
`else
  output bit [31:0] data[PullData32bWidth],
`endif
  input int data_width
);

import "DPI-C" function int multisim_server_push(
  input string server_name,
`ifdef MULTISIM_SV_DPI_OPEN_ARRAY
  input bit [31:0] data[],
`else
  input bit [31:0] data[PushData32bWidth],
`endif
  input int data_width
);

import "DPI-C" function int multisim_server_pull_4state(
  input string server_name,
`ifdef MULTISIM_SV_DPI_OPEN_ARRAY
  output logic [31:0] data[],
`else
  output logic [31:0] data[PullData32bWidth],
`endif
  input int data_width
);

import "DPI-C" function int multisim_server_push_4state(
  input string server_name,
`ifdef MULTISIM_SV_DPI_OPEN_ARRAY
  input logic [31:0] data[],
`else
  input logic [31:0] data[PushData32bWidth],
`endif
  input int data_width
);

function automatic int multisim_server_pull_packed(
    input string server_name, output logic [PULL_DATA_WIDTH-1:0] data, input int data_width);
  logic [PullData32bWidth*32-1:0] data_tmp;
  int ret;
  if (DATA_IS_4STATE) begin
    logic [31:0] data_unpacked[PullData32bWidth];
    ret = multisim_server_pull_4state(server_name, data_unpacked, data_width);
    for (int i = 0; i < PullData32bWidth; i++) begin
      data_tmp[i*32+:32] = data_unpacked[i];
    end
  end else begin
    bit [31:0] data_unpacked[PullData32bWidth];
    ret = multisim_server_pull(server_name, data_unpacked, data_width);
    for (int i = 0; i < PullData32bWidth; i++) begin
      data_tmp[i*32+:32] = data_unpacked[i];
    end
  end
  data = data_tmp[PULL_DATA_WIDTH-1:0];
  return ret;
endfunction

function automatic int multisim_server_push_packed(
    input string server_name, input logic [PUSH_DATA_WIDTH-1:0] data, input int data_width);
  logic [PushData32bWidth*32-1:0] data_tmp;
  int ret;
  data_tmp[PUSH_DATA_WIDTH-1:0] = data;
  if (DATA_IS_4STATE) begin
    logic [31:0] data_unpacked[PushData32bWidth];
    for (int i = 0; i < PushData32bWidth; i++) begin
      data_unpacked[i] = data_tmp[i*32+:32];
    end
    ret = multisim_server_push_4state(server_name, data_unpacked, data_width);
  end else begin
    bit [31:0] data_unpacked[PushData32bWidth];
    for (int i = 0; i < PushData32bWidth; i++) begin
      data_unpacked[i] = data_tmp[i*32+:32];
    end
    ret = multisim_server_push(server_name, data_unpacked, data_width);
  end
  return ret;
endfunction
`endif
