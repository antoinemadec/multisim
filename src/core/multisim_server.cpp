#include "multisim_server.h"
#include "multisim_common.h"
#include "socket_server/server.h"

#include <cassert>
#include <map>
#include <string>
#include <unistd.h>

using namespace std;

Server *server[MULTISIM_SERVER_MAX];
int sockets[MULTISIM_SERVER_MAX];
int server_idx = 0;
map<string, int> server_name_to_idx;

int multisim_server_start(char const *server_name) {
  assert(server_idx < MULTISIM_SERVER_MAX);
  server[server_idx] = new Server(".multisim", server_name);
  server[server_idx]->start();
  sockets[server_idx] = -1;
  server_name_to_idx[server_name] = server_idx;
  server_idx++;
  return MULTISIM_SUCCESS;
}

int multisim_server_pull(char const *server_name, data_handle_t data_handle, int data_width) {
  int r;
  int buf_32b_size = (data_width + 31) / 32;
  uint32_t read_buf[buf_32b_size];
  int idx = server_name_to_idx[server_name];
#if defined(MULTISIM_EMULATION) || defined(MULTISIM_SW)
  uint32_t *data = data_handle;
#else
  svBitVecVal *data = (svBitVecVal *)svGetArrayPtr(data_handle);
#endif

  if (sockets[idx] < 0) {
    sockets[idx] = server[idx]->acceptNewSocket();
    if (sockets[idx] < 0) {
      return MULTISIM_FAIL;
    }
  }

  r = read(sockets[idx], read_buf, sizeof(read_buf));
  if (r <= 0) {
    // -1: nothing to send
    // 0: client disconnected
    if (r == 0) {
      sockets[idx] = -1;
    }
    return MULTISIM_FAIL;
  }

  for (int i = 0; i < buf_32b_size; i++) {
    data[i] = read_buf[i];
  }
  return MULTISIM_SUCCESS;
}

// #define SIMULATE_SEND_FAIL_SERVER
int multisim_server_push(char const *server_name, const data_handle_t data_handle, int data_width) {
  int r;
  int buf_32b_size = (data_width + 31) / 32;
  uint32_t send_buf[buf_32b_size];
  int idx = server_name_to_idx[server_name];
#if defined(MULTISIM_EMULATION) || defined(MULTISIM_SW)
  uint32_t *data = data_handle;
#else
  svBitVecVal *data = (svBitVecVal *)svGetArrayPtr(data_handle);
#endif

  // 0: client disconnected
  r = read(sockets[idx], send_buf, 1);

  if (sockets[idx] < 0 || r == 0) {
    sockets[idx] = server[idx]->acceptNewSocket();
    if (sockets[idx] < 0) {
      return MULTISIM_FAIL;
    }
  }

  for (int i = 0; i < buf_32b_size; i++) {
    send_buf[i] = data[i];
  }

#ifdef SIMULATE_SEND_FAIL_SERVER
  static int cnt = 0;
  cnt++;
  if (cnt % 1000 == 0) {
    printf("multisim_server_push: simulate send fail\n");
    return MULTISIM_FAIL;
  }
#endif

  r = send(sockets[idx], send_buf, sizeof(send_buf), 0);
  if (r <= 0) { // send failed
    return MULTISIM_FAIL;
  }
  return MULTISIM_SUCCESS;
}
