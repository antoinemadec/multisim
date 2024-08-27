//-----------------------------------------------------------
// DPIs
//-----------------------------------------------------------
import "DPI-C" function void multisim_server_start(string name);
import "DPI-C" function int multisim_server_get_data(
  input string name,
  output bit [DATA_WIDTH-1:0] data,
  input int data_width
);
import "DPI-C" function int multisim_server_send_data(
  input string name,
  input bit [DATA_WIDTH-1:0] data,
  input int data_width
);
