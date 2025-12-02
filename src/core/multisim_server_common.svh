//-----------------------------------------------------------
// DPIs
//-----------------------------------------------------------
localparam int Data32bWidth = (DATA_WIDTH + 31) / 32;

import "DPI-C" function void multisim_server_start(string name);
import "DPI-C" function int multisim_server_get_data(
  input string name,
`ifdef EMULATION
  output bit [31:0] data[Data32bWidth],
`else
  output bit [31:0] data[],
`endif
  input int data_width
);
import "DPI-C" function int multisim_server_send_data(
  input string name,
`ifdef EMULATION
  input bit [31:0] data[Data32bWidth],
`else
  input bit [31:0] data[],
`endif
  input int data_width
);

function automatic int multisim_server_get_data_packed(
    input string name, output bit [DATA_WIDTH-1:0] data, input int data_width);
  bit [31:0] data_unpacked[Data32bWidth];
  bit [Data32bWidth*32-1:0] data_tmp;
  int ret;
  ret = multisim_server_get_data(server_name, data_unpacked, data_width);
  for (int i = 0; i < Data32bWidth; i++) begin
    data_tmp[i*32+:32] = data_unpacked[i];
  end
  data = data_tmp[DATA_WIDTH-1:0];
  return ret;
endfunction

function automatic int multisim_server_send_data_packed(
    input string name, input bit [DATA_WIDTH-1:0] data, input int data_width);
  bit [31:0] data_unpacked[Data32bWidth];
  bit [Data32bWidth*32-1:0] data_tmp;
  int ret;
  data_tmp[DATA_WIDTH-1:0] = data;
  for (int i = 0; i < Data32bWidth; i++) begin
    data_unpacked[i] = data_tmp[i*32+:32];
  end
  ret = multisim_server_send_data(server_name, data_unpacked, data_width);
  return ret;
endfunction

//-----------------------------------------------------------
// end of simulation
//-----------------------------------------------------------
// TODO: can it work in emulation?
`ifndef EMULATION
final begin
  string server_exit_file = "multisim/server_exit";
  int fp;
  fp = $fopen(server_exit_file, "w");
  if (fp == 0) begin
    $fatal("cannot write server_exit_file");
  end
  $fwrite(fp, "");
  $fclose(fp);
end
`endif
