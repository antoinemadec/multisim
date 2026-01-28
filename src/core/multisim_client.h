// SW function to start, send and get data from a multisim client

#pragma once

#include "multisim_common.h"

#ifdef __cplusplus
extern "C" {
#endif

// start client and get socket
void multisim_client_start(char const *server_runtime_directory, char const *server_name);

// send data to server
int multisim_client_push(char const *server_name, const data_handle_t data_handle, int data_width);

// get data from server
int multisim_client_pull(char const *server_name, data_handle_t data_handle, int data_width);

// like multisim_client_push, but for 4-state data (X and Z),
// avoid using this function if not necessary since the data exchanged is doubled
int multisim_client_push_4state(char const *server_name, const data_handle_t data_handle,
                                int data_width);

// like multisim_client_pull, but for 4-state data (X and Z),
// avoid using this function if not necessary since the data exchanged is doubled
int multisim_client_pull_4state(char const *server_name, data_handle_t data_handle, int data_width);

#ifdef __cplusplus
}
#endif
