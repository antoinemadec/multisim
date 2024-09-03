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

//-----------------------------------------------------------
// end of simulation
//-----------------------------------------------------------
final begin
  string server_exit_file = "./server_exit";
  int fp;
  fp = $fopen(server_exit_file, "w");
  if (fp == 0) begin
    $fatal("cannot write server_exit_file");
  end
  $fwrite(fp, "");
  $fclose(fp);
end
