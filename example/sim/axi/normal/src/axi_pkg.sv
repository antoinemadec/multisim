package axi_pkg;

  parameter int AXI_ID_WIDTH = 16;
  parameter int AXI_ADDR_WIDTH = 32;
  parameter int AXI_DATA_WIDTH = 64;
  parameter int AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8;

  typedef struct packed {
    bit [AXI_ID_WIDTH-1:0]   id;
    bit [AXI_ADDR_WIDTH-1:0] addr;
    bit [7:0]                len;     // AXI3: 4 bits; AXI4: 8 bits
    bit [2:0]                size;
    bit [1:0]                burst;
    bit [1:0]                lock;    // AXI3: 2 bits; AXI4: 1 bit
    bit [3:0]                cache;
    bit [2:0]                prot;
    bit [3:0]                qos;     // AXI4 only
    bit [3:0]                region;  // AXI4 only
  } axi_aw_t;

  typedef struct packed {
    bit [AXI_ID_WIDTH-1:0]   id;    // AXI3 only
    bit [AXI_DATA_WIDTH-1:0] data;
    bit [AXI_STRB_WIDTH-1:0] strb;
    bit                      last;
  } axi_w_t;

  typedef struct packed {
    bit [AXI_ID_WIDTH-1:0] id;
    bit [1:0]              resp;
  } axi_b_t;

  typedef struct packed {
    bit [AXI_ID_WIDTH-1:0]   id;
    bit [AXI_ADDR_WIDTH-1:0] addr;
    bit [7:0]                len;     // AXI3: 4 bits; AXI4: 8 bits
    bit [2:0]                size;
    bit [1:0]                burst;
    bit [1:0]                lock;    // AXI3: 2 bits; AXI4: 1 bits
    bit [3:0]                cache;
    bit [2:0]                prot;
    bit [3:0]                qos;     // AXI4 only
    bit [3:0]                region;  // AXI4 only
  } axi_ar_t;

  typedef struct packed {
    bit [AXI_ID_WIDTH-1:0]   id;
    bit [AXI_DATA_WIDTH-1:0] data;
    bit [1:0]                resp;
    bit                      last;
  } axi_r_t;

endpackage
