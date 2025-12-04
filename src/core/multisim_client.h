// SW function to start, send and get data from a multisim client
//
// There are 3 targets:
//  - SIMULATION (default): called from SV as DPI
//  - EMULATION: called from SV as DPI, with fixed size array (open array is not supported)
//  - SW: called directly from software, send/get are blocking

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

// start client and get socket
extern "C" void multisim_client_start(char const *server_runtime_directory,
                                      char const *server_name);

// send data to server
extern "C" int multisim_client_send_data(char const *server_name, const data_handle_t data_handle,
                                         int data_width);

// get data from server
extern "C" int multisim_client_get_data(char const *server_name, data_handle_t data_handle,
                                        int data_width);
