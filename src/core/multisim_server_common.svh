//-----------------------------------------------------------
// DPIs
//-----------------------------------------------------------
localparam int PullData32bWidth = (PULL_DATA_WIDTH + 31) / 32;
localparam int PushData32bWidth = (PUSH_DATA_WIDTH + 31) / 32;

import "DPI-C" function void multisim_server_start(string server_name);

import "DPI-C" function int multisim_server_pull(
  input string server_name,
`ifdef MULTISIM_EMULATION
  output bit [31:0] data[PullData32bWidth],
`else
  output bit [31:0] data[],
`endif
  input int data_width
);

import "DPI-C" function int multisim_server_push(
  input string server_name,
`ifdef MULTISIM_EMULATION
  input bit [31:0] data[PushData32bWidth],
`else
  input bit [31:0] data[],
`endif
  input int data_width
);

function automatic int multisim_server_pull_packed(
    input string server_name, output bit [PULL_DATA_WIDTH-1:0] data, input int data_width);
  bit [31:0] data_unpacked[PullData32bWidth];
  bit [PullData32bWidth*32-1:0] data_tmp;
  int ret;
  ret = multisim_server_pull(server_name, data_unpacked, data_width);
  for (int i = 0; i < PullData32bWidth; i++) begin
    data_tmp[i*32+:32] = data_unpacked[i];
  end
  data = data_tmp[PULL_DATA_WIDTH-1:0];
  return ret;
endfunction

function automatic int multisim_server_push_packed(
    input string server_name, input bit [PUSH_DATA_WIDTH-1:0] data, input int data_width);
  bit [31:0] data_unpacked[PushData32bWidth];
  bit [PushData32bWidth*32-1:0] data_tmp;
  int ret;
  data_tmp[PUSH_DATA_WIDTH-1:0] = data;
  for (int i = 0; i < PushData32bWidth; i++) begin
    data_unpacked[i] = data_tmp[i*32+:32];
  end
  ret = multisim_server_push(server_name, data_unpacked, data_width);
  return ret;
endfunction

//-----------------------------------------------------------
// end of simulation
//-----------------------------------------------------------
// TODO: can it work in emulation?
`ifndef MULTISIM_EMULATION
final begin
  string server_exit_file = ".multisim/server_exit";
  int fp;
  fp = $fopen(server_exit_file, "w");
  if (fp == 0) begin
    $fatal("cannot write server_exit_file");
  end
  $fwrite(fp, "");
  $fclose(fp);
end
`endif
