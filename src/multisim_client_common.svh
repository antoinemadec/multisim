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
// end of simulation
//-----------------------------------------------------------
initial begin
  multisim_client_end_of_simulation eos;
  eos = new();

  // make sure only 1 process handles eos to improve performance
  @(posedge clk);
  if (eos.handles_end_of_simulation()) begin
    string server_exit_file = {SERVER_RUNTIME_DIRECTORY, "/server_exit"};
    int fp;
    int check_every_n_cycles;
    if (!$value$plusargs("MULTISIM_EOS_CHECK_EVERY_N_CYCLES=%d", check_every_n_cycles)) begin
      check_every_n_cycles = 1000;
    end

    forever begin
      repeat (check_every_n_cycles) begin
        @(posedge clk);
      end
      fp = $fopen(server_exit_file, "r");  // can be checked ~2M times/sec on Verilator
      if (fp != 0) begin
        $fclose(fp);
        $display("multisim_client: end of simulation");
        $finish;
      end
    end
  end
end

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

function automatic void connnect_to_server(input string server_runtime_directory,
                                           input string server_name);
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
endfunction
