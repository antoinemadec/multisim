// SW function to start, send and get data from a multisim server

#pragma once

#include "multisim_common.h"

#ifdef __cplusplus
extern "C" {
#endif

// start server
int multisim_server_start(char const *server_name);

// get data from client
int multisim_server_pull(char const *server_name, data_handle_t data_handle, int data_width);

// send data to client
int multisim_server_push(char const *server_name, const data_handle_t data_handle, int data_width);

// like multisim_server_pull, but for 4-state data (X and Z),
// avoid using this function if not necessary since the data exchanged is doubled
int multisim_server_pull_4state(char const *server_name, data_handle_t data_handle, int data_width);

// like multisim_server_push, but for 4-state data (X and Z),
// avoid using this function if not necessary since the data exchanged is doubled
int multisim_server_push_4state(char const *server_name, const data_handle_t data_handle,
                                int data_width);

#if defined(MULTISIM_ZEBU)
// ZeBu ZEMI3 transactor DPIs, called by the server modules only (see multisim_server_common.svh)
void multisim_server_start_zebu(const svBitVecVal *server_name);
void multisim_server_pull_zebu(svBitVecVal *status_data, svBit *done,
                               const svBitVecVal *server_name, int data_width);
void multisim_server_push_zebu(svBitVecVal *status, svBit *done, const svBitVecVal *server_name,
                               const svBitVecVal *data, int data_width);
#endif

#ifdef __cplusplus
}
#endif
