module multisim_client_pull #(
    parameter string SERVER_RUNTIME_DIRECTORY = "../output_top",
    parameter int DATA_WIDTH = 64
) (
    input bit clk,
    input string server_name,
    input bit data_rdy,
    output bit data_vld,
    output bit [DATA_WIDTH-1:0] data
);

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

  function automatic int get_server_address_and_port(
      input string server_name, output string server_address, output int server_port);
    int fp;
    string garbage;
    string server_file = {SERVER_RUNTIME_DIRECTORY, "/server_", server_name, ".txt"};
    $display("multisim_client_pull: server_file=%s", server_file);
    fp = $fopen(server_file, "r");
    if (fp == 0) begin
      return 0;
    end
    $fscanf(fp, "%s %s", garbage, server_address);
    $fscanf(fp, "%s %d", garbage, server_port);
    $fclose(fp);
    return 1;
  endfunction

  initial begin
    string server_address;
    int server_port;
    wait (server_name != "");
    while (get_server_address_and_port(
        server_name, server_address, server_port
    ) != 1) begin
      ;
    end
    $display("multisim_client_pull: server_name=%s server_address=%s server_port=%d", server_name,
             server_address, server_port);
    while (multisim_client_start(
        server_name, server_address, server_port
    ) != 1) begin
      ;
    end
  end

  always @(posedge clk) begin
    bit [DATA_WIDTH-1:0] data_dpi;
    if (!data_vld || data_rdy) begin
      int data_vld_dpi;
      data_vld_dpi = multisim_client_get_data(server_name, data_dpi, DATA_WIDTH);
      data_vld <= data_vld_dpi[0];
      data <= data_dpi;
    end
  end

endmodule
