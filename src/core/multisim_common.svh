// There are 2 targets:
//  - SIMULATION (default): called from SV as DPI
//  - EMULATION: called from SV as DPI, with fixed size array (open array is not supported)

`ifndef MULTISIM_COMMON_SVH
`define MULTISIM_COMMON_SVH

// default target is SIMULATION
`ifndef MULTISIM_EMULATION
`define MULTISIM_SIMULATION
`endif

// SIMULATION
//  - uses SV DPI
//  - uses open array for data handle: required by Verilator when using multiple sizes
`ifdef MULTISIM_SIMULATION
`define MULTISIM_SV_DPI
`define MULTISIM_SV_DPI_OPEN_ARRAY
`endif

// EMULATION
//  - uses SV DPI
//  - uses fixed size array for data handle: open array is not supported by Veloce
//  - does not support 4-state data
`ifdef MULTISIM_EMULATION
`define MULTISIM_SV_DPI
`define MULTISIM_4STATE_UNSUPPORTED
`endif

`endif
