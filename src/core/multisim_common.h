// There are 3 targets:
//  - SIMULATION (default): called from SV as DPI
//  - EMULATION: called from SV as DPI, with fixed size array (open array is not supported)
//    - ZEBU: EMULATION flavor for ZeBu, the server DPIs are ZEMI3 deferred DPIs
//  - SW: called directly from software, send/get are blocking

#pragma once

// ZEBU implies EMULATION
#if defined(MULTISIM_ZEBU) && !defined(MULTISIM_EMULATION)
#define MULTISIM_EMULATION
#endif

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

// ZEBU
//  - server modules are ZEMI3 transactors: no string type, the server name is a packed
//    bit [8*(MULTISIM_SERVER_NAME_LEN+1)-1:0] holding the string literal (right-justified)
//  - DPIs with outputs are ZEMI3 deferred DPIs: the emulator clocks keep running while the
//    host processes the call

// server names: at most MULTISIM_SERVER_NAME_LEN characters, on all targets
#ifndef MULTISIM_SERVER_NAME_LEN
#define MULTISIM_SERVER_NAME_LEN 512
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static inline void multisim_check_server_name(char const *server_name) {
  size_t len = strlen(server_name);
  if (len > MULTISIM_SERVER_NAME_LEN) {
    fprintf(stderr, "ERROR: multisim: server name [%s] has %zu characters, the limit is %d\n",
            server_name, len, MULTISIM_SERVER_NAME_LEN);
    exit(EXIT_FAILURE);
  }
}
