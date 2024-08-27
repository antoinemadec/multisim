//-----------------------------------------------------------
// DPIs
//-----------------------------------------------------------
import "DPI-C" function int multisim_client_start(
  string server_name,
  string server_address,
  int server_port
);
import "DPI-C" function int multisim_client_get_data(
  string server_name,
  output bit [DATA_WIDTH-1:0] data,
  input int data_width
);
import "DPI-C" function int multisim_client_send_data(
  string server_name,
  input bit [DATA_WIDTH-1:0] data,
  input int data_width
);

//-----------------------------------------------------------
// functions/tasks
//-----------------------------------------------------------
function automatic int get_server_address_and_port(
    input string server_runtime_directory, input string server_name, output string server_address,
    output int server_port);
  int fp;
  string garbage;
  string server_file = {server_runtime_directory, "/server_", server_name, ".txt"};
  fp = $fopen(server_file, "r");
  if (fp == 0) begin
    return 0;
  end
  $fscanf(fp, "%s %s", garbage, server_address);
  $fscanf(fp, "%s %d", garbage, server_port);
  $fclose(fp);
  return 1;
endfunction

task automatic connnect_to_server(input string server_runtime_directory, input string server_name);
  string server_address;
  int server_port;
  while (get_server_address_and_port(
      server_runtime_directory, server_name, server_address, server_port
  ) != 1) begin
    ;
  end
  $display("multisim_client: server_name=%s server_address=%s server_port=%d", server_name,
           server_address, server_port);
  while (multisim_client_start(
      server_name, server_address, server_port
  ) != 1) begin
    ;
  end
endtask
