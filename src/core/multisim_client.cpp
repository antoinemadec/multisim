#include "multisim_client.h"
#include "multisim_common.h"
#include "socket_server/client.h"
#include "socket_server/info_file.h"

#include <cassert>
#include <map>
#include <stdio.h>
#include <string>
#include <unistd.h>

static int sockets[MULTISIM_SERVER_MAX];
static int server_idx = 0;
static std::map<std::string, int> server_name_to_idx;

static FILE *open_client_info_file(std::string const &client_info_file, char const *mode) {
  FILE *fp = fopen(client_info_file.c_str(), mode);
  if (fp == NULL) {
    perror(client_info_file.c_str());
    exit(EXIT_FAILURE);
  }
  return fp;
}

void multisim_client_start(char const *server_runtime_directory, char const *server_name) {
  Client *client;
  std::string server_info_dir = std::string(server_runtime_directory) + "/.multisim";

  assert(server_idx < MULTISIM_SERVER_MAX);
  multisim_check_server_name(server_name);

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

  // dump info, in the file named after the 1st server of the client
  static std::string client_info_file;
  FILE *fp;
  if (server_idx == 0) {
    client_info_file = info_file_path(server_info_dir, "client_", server_name);
    fp = open_client_info_file(client_info_file, "w");
    fprintf(fp, "ip: %s\n", client->clientIp);
    fprintf(fp, "pid: %0d\n", getpid());
  } else {
    fp = open_client_info_file(client_info_file, "a");
  }
  fprintf(fp, "server_%0d: %s %s %0d\n", server_idx, server_name, client->serverIp,
          client->serverPort);
  fflush(fp);
  fclose(fp);
  printf("multisim_client_start: [%s] has started, info in %s\n", server_name,
         client_info_file.c_str());

  server_idx++;
}

// index of a started server, the name of a server that was not started is an error
static int get_server_idx(char const *server_name) {
  auto it = server_name_to_idx.find(server_name);
  if (it == server_name_to_idx.end()) {
    fprintf(stderr, "ERROR: multisim: client of server [%s] was not started\n", server_name);
    exit(EXIT_FAILURE);
  }
  return it->second;
}

// #define SIMULATE_SEND_FAIL_CLIENT
static inline int multisim_client_push_core(char const *server_name,
                                            const data_handle_t data_handle, int data_width,
                                            bool is_4state) {
  int r;
  int buf_32b_size = (data_width + 31) / 32;
  uint32_t send_buf[is_4state ? 2 * buf_32b_size : buf_32b_size];
  int idx = get_server_idx(server_name);
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

  r = send_msg(sockets[idx], send_buf, sizeof(send_buf));
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
  int idx = get_server_idx(server_name);
#if defined(MULTISIM_SV_DPI_OPEN_ARRAY)
  svBitVecVal *data = (svBitVecVal *)svGetArrayPtr(data_handle);
  svLogicVecVal *data_4state = (svLogicVecVal *)svGetArrayPtr(data_handle);
#else
  uint32_t *data = data_handle;
#endif

  r = read_msg(sockets[idx], read_buf, sizeof(read_buf));
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
