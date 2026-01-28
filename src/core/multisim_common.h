// There are 3 targets:
//  - SIMULATION (default): called from SV as DPI
//  - EMULATION: called from SV as DPI, with fixed size array (open array is not supported)
//  - SW: called directly from software, send/get are blocking

#pragma once

// default target is SIMULATION
#if !defined(MULTISIM_EMULATION) && !defined(MULTISIM_SW)
#define MULTISIM_SIMULATION
#endif

// SIMULATION
//  - uses SV DPI
//  - uses open array for data handle: required by Verilator when using multiple sizes
#if defined(MULTISIM_SIMULATION)
#define MULTISIM_SV_DPI
#define MULTISIM_SV_DPI_OPEN_ARRAY
#endif

// EMULATION
//  - uses SV DPI
//  - uses fixed size array for data handle: open array is not supported by Veloce
//  - does not support 4-state data
#if defined(MULTISIM_EMULATION)
#define MULTISIM_SV_DPI
#define MULTISIM_4STATE_UNSUPPORTED
#endif

// SW
//  - does not use SV DPI
//  - does not support open array for data handle
//  - send and get are blocking calls to avoid while loops in SW
#if defined(MULTISIM_SW)
#define MULTISIM_BLOCKING_SOCKET
#endif

#include <stdint.h>
#if defined(MULTISIM_SV_DPI)
#include <svdpi.h>
#endif

#if defined(MULTISIM_SV_DPI_OPEN_ARRAY)
typedef svOpenArrayHandle data_handle_t;
#else
typedef uint32_t *data_handle_t;
#endif

#define MULTISIM_SERVER_MAX 1024

#define MULTISIM_SUCCESS 1
#define MULTISIM_FAIL 0
