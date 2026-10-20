module multisim_server_quasi_static_push #(
    parameter int DATA_WIDTH = 64
) (
    input bit clk,
    input string server_name,
    input bit [DATA_WIDTH-1:0] data
);

  bit data_rdy;
  bit data_vld;
  bit [DATA_WIDTH-1:0] data_push;

  bit [DATA_WIDTH-1:0] data_prev;
  bit [DATA_WIDTH-1:0] data_queue[$];

  initial begin
    data_queue.push_back(data);
    data_prev = data;
  end

  always @(posedge clk) begin
    if (data !== data_prev) begin
      data_queue.push_back(data);
      data_prev <= data;
    end
    // keep the data until it is accepted
    if (!data_vld || data_rdy) begin
      if (data_queue.size() > 0) begin
        data_push <= data_queue.pop_front();
        data_vld <= 1;
      end else begin
        data_vld <= 0;
      end
    end
  end

  multisim_server_push #(
      .DATA_WIDTH(DATA_WIDTH)
  ) i_multisim_server_push (
      .clk        (clk),
      .server_name(server_name),
      .data_rdy   (data_rdy),
      .data_vld   (data_vld),
      .data       (data_push)
  );

endmodule
