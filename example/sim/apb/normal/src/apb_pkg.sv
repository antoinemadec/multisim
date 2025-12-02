package apb_pkg;

  parameter int APB_ADDR_WIDTH = 32;
  parameter int APB_DATA_WIDTH = 32;
  parameter int APB_STRB_WIDTH = APB_DATA_WIDTH / 8;

  typedef struct packed {
    bit [APB_ADDR_WIDTH-1:0] addr;
    bit [APB_DATA_WIDTH-1:0] wdata;
    bit                      write;
    bit [APB_STRB_WIDTH-1:0] strb;
    bit [2:0]                prot;
  } apb_req_t;

  typedef struct packed {
    bit [APB_DATA_WIDTH-1:0] rdata;
    bit                      slverr;
  } apb_resp_t;

endpackage
