#include "multisim_client.h"
#include "multisim_common.h"
#include "socket_server/client.h"

#include <cassert>
#include <map>
#include <stdio.h>
#include <string>
#include <unistd.h>

int sockets[MULTISIM_SERVER_MAX];
int server_idx = 0;
std::map<std::string, int> server_name_to_idx;

void multisim_client_start(char const *server_runtime_directory, char const *server_name) {
  Client *client;
  std::string server_info_dir = std::string(server_runtime_directory) + "/.multisim";

  assert(server_idx < MULTISIM_SERVER_MAX);

  client = new Client(server_info_dir.c_str(), server_name);
  client->start();
  sockets[server_idx] = client->getSocket();
  server_name_to_idx[server_name] = server_idx;

#if defined(MULTISIM_BLOCKING_SOCKET)
  // make socket blocking
  int flags;
  flags = fcntl(sockets[server_idx], F_GETFD, 0);
  flags &= ~O_NONBLOCK;
  fcntl(sockets[server_idx], F_SETFL, flags);
#endif

  // dump info
  std::string first_server_name = server_name_to_idx.begin()->first;
  std::string client_info_file = server_info_dir + "/client_" + first_server_name + ".txt";
  FILE *fp;
  if (server_idx == 0) {
    fp = fopen(client_info_file.c_str(), "w");
    fprintf(fp, "ip: %s\n", client->clientIp);
    fprintf(fp, "pid: %0d\n", getpid());
  } else {
    fp = fopen(client_info_file.c_str(), "a");
  }
  fprintf(fp, "server_%0d: %s %s %0d\n", server_idx, server_name, client->serverIp,
          client->serverPort);
  fflush(fp);
  fclose(fp);
  printf("multisim_client_start: [%s] has started, info in %s\n", server_name,
         client_info_file.c_str());

  server_idx++;
}

// #define SIMULATE_SEND_FAIL_CLIENT
static inline int multisim_client_push_core(char const *server_name,
                                            const data_handle_t data_handle, int data_width,
                                            bool is_4state) {
  int r;
  int buf_32b_size = (data_width + 31) / 32;
  uint32_t send_buf[is_4state ? 2 * buf_32b_size : buf_32b_size];
  int idx = server_name_to_idx[server_name];
#if defined(MULTISIM_SV_DPI_OPEN_ARRAY)
  svBitVecVal *data = (svBitVecVal *)svGetArrayPtr(data_handle);
  svLogicVecVal *data_4state = (svLogicVecVal *)svGetArrayPtr(data_handle);
#else
  uint32_t *data = data_handle;
#endif

  for (int i = 0; i < buf_32b_size; i++) {
    if (is_4state) {
#if defined(MULTISIM_SV_DPI_OPEN_ARRAY)
      send_buf[i] = data_4state[i].aval;
      send_buf[buf_32b_size + i] = data_4state[i].bval;
#else
      send_buf[i] = data[i];
      send_buf[buf_32b_size + i] = data[buf_32b_size + i];
#endif
    } else {
      send_buf[i] = data[i];
    }
  }

#ifdef SIMULATE_SEND_FAIL_CLIENT
  static int cnt = 0;
  cnt++;
  if (cnt % 1000 == 0) {
    printf("multisim_client_push: simulate send fail\n");
    return MULTISIM_FAIL;
  }
#endif

  r = send(sockets[idx], send_buf, sizeof(send_buf), 0);
  if (r <= 0) { // send failed
    return MULTISIM_FAIL;
  }
  return MULTISIM_SUCCESS;
}

static inline int multisim_client_pull_core(char const *server_name, data_handle_t data_handle,
                                            int data_width, bool is_4state) {
  int r;
  int buf_32b_size = (data_width + 31) / 32;
  uint32_t read_buf[is_4state ? 2 * buf_32b_size : buf_32b_size];
  int idx = server_name_to_idx[server_name];
#if defined(MULTISIM_SV_DPI_OPEN_ARRAY)
  svBitVecVal *data = (svBitVecVal *)svGetArrayPtr(data_handle);
  svLogicVecVal *data_4state = (svLogicVecVal *)svGetArrayPtr(data_handle);
#else
  uint32_t *data = data_handle;
#endif

  r = read(sockets[idx], read_buf, sizeof(read_buf));
  if (r <= 0) {
    return MULTISIM_FAIL;
  }

  for (int i = 0; i < buf_32b_size; i++) {
    if (is_4state) {
#if defined(MULTISIM_SV_DPI_OPEN_ARRAY)
      data_4state[i].aval = read_buf[i];
      data_4state[i].bval = read_buf[buf_32b_size + i];
#else
      data[i] = read_buf[i];
      data[buf_32b_size + i] = read_buf[buf_32b_size + i];
#endif
    } else {
      data[i] = read_buf[i];
    }
  }
  return MULTISIM_SUCCESS;
}

int multisim_client_push(char const *server_name, const data_handle_t data_handle, int data_width) {
  return multisim_client_push_core(server_name, data_handle, data_width, false);
}

int multisim_client_pull(char const *server_name, data_handle_t data_handle, int data_width) {
  return multisim_client_pull_core(server_name, data_handle, data_width, false);
}

int multisim_client_push_4state(char const *server_name, const data_handle_t data_handle,
                                int data_width) {
#if defined(MULTISIM_4STATE_UNSUPPORTED)
  assert(false);
#endif
  return multisim_client_push_core(server_name, data_handle, data_width, true);
}

int multisim_client_pull_4state(char const *server_name, data_handle_t data_handle,
                                int data_width) {
#if defined(MULTISIM_4STATE_UNSUPPORTED)
  assert(false);
#endif
  return multisim_client_pull_core(server_name, data_handle, data_width, true);
}
