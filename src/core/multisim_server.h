// SW function to start, send and get data from a multisim server
//
// There are 3 targets:
//  - SIMULATION (default): called from SV as DPI
//  - EMULATION: called from SV as DPI, with fixed size array (open array is not supported)
//  - SW: TODO

#pragma once

#include <stdint.h>
#if !defined(SW)
#include <svdpi.h>
#endif

#if defined(EMULATION) || defined(SW)
typedef uint32_t *data_handle_t;
#else
typedef svOpenArrayHandle data_handle_t;
#endif

#define MULTISIM_SERVER_MAX 1024

// start server
extern "C" int multisim_server_start(char const *server_name);

// get data from client
extern "C" int multisim_server_get_data(char const *server_name, data_handle_t data_handle,
                                        int data_width);

// send data to client
extern "C" int multisim_server_send_data(char const *server_name, const data_handle_t data_handle,
                                         int data_width);
