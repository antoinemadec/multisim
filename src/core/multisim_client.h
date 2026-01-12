// SW function to start, send and get data from a multisim client
//
// There are 3 targets:
//  - SIMULATION (default): called from SV as DPI
//  - EMULATION: called from SV as DPI, with fixed size array (open array is not supported)
//  - SW: called directly from software, send/get are blocking

#pragma once

#include <stdint.h>
#if !defined(MULTISIM_SW)
#include <svdpi.h>
#endif

#if defined(EMULATION) || defined(MULTISIM_SW)
typedef uint32_t *data_handle_t;
#else
typedef svOpenArrayHandle data_handle_t;
#endif

#define MULTISIM_SERVER_MAX 1024

#ifdef __cplusplus
extern "C" {
#endif

// start client and get socket
void multisim_client_start(char const *server_runtime_directory,
                                      char const *server_name);

// send data to server
int multisim_client_push(char const *server_name, const data_handle_t data_handle,
                                    int data_width);

// get data from server
int multisim_client_pull(char const *server_name, data_handle_t data_handle,
                                    int data_width);
#ifdef __cplusplus
}
#endif
