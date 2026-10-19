#include "multisim_server.h"
#include "multisim_common.h"
#include "socket_server/server.h"

#include <cassert>
#include <map>
#include <string>
#include <unistd.h>

Server *server[MULTISIM_SERVER_MAX];
int sockets[MULTISIM_SERVER_MAX];
int server_idx = 0;
std::map<std::string, int> server_name_to_idx;

int multisim_server_start(char const *server_name) {
  assert(server_idx < MULTISIM_SERVER_MAX);
  multisim_check_server_name(server_name);
  server[server_idx] = new Server(".multisim", server_name);
  server[server_idx]->start();
  sockets[server_idx] = -1;
  server_name_to_idx[server_name] = server_idx;
  server_idx++;
  return MULTISIM_SUCCESS;
}

static inline int multisim_server_pull_core(char const *server_name, data_handle_t data_handle,
                                            int data_width, bool is_4state) {
  int r;
  int buf_32b_size = (data_width + 31) / 32;
  uint32_t read_buf[is_4state ? 2 * buf_32b_size : buf_32b_size];
  int idx = server_name_to_idx[server_name];
#if defined(MULTISIM_SV_DPI_OPEN_ARRAY)
  svBitVecVal *data;
  svLogicVecVal *data_4state;
  if (is_4state) {
    data_4state = (svLogicVecVal *)svGetArrayPtr(data_handle);
  } else {
    data = (svBitVecVal *)svGetArrayPtr(data_handle);
  }
#else
  uint32_t *data = data_handle;
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

// #define SIMULATE_SEND_FAIL_SERVER
static inline int multisim_server_push_core(char const *server_name,
                                            const data_handle_t data_handle, int data_width,
                                            bool is_4state) {
  int r;
  int buf_32b_size = (data_width + 31) / 32;
  uint32_t send_buf[is_4state ? 2 * buf_32b_size : buf_32b_size];
  int idx = server_name_to_idx[server_name];
#if defined(MULTISIM_SV_DPI_OPEN_ARRAY)
  svBitVecVal *data;
  svLogicVecVal *data_4state;
  if (is_4state) {
    data_4state = (svLogicVecVal *)svGetArrayPtr(data_handle);
  } else {
    data = (svBitVecVal *)svGetArrayPtr(data_handle);
  }
#else
  uint32_t *data = data_handle;
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

int multisim_server_pull(char const *server_name, data_handle_t data_handle, int data_width) {
  return multisim_server_pull_core(server_name, data_handle, data_width, false);
}

int multisim_server_push(char const *server_name, const data_handle_t data_handle, int data_width) {
  return multisim_server_push_core(server_name, data_handle, data_width, false);
}

int multisim_server_pull_4state(char const *server_name, data_handle_t data_handle,
                                int data_width) {
#if defined(MULTISIM_4STATE_UNSUPPORTED)
  assert(false);
#endif
  return multisim_server_pull_core(server_name, data_handle, data_width, true);
}

int multisim_server_push_4state(char const *server_name, const data_handle_t data_handle,
                                int data_width) {
#if defined(MULTISIM_4STATE_UNSUPPORTED)
  assert(false);
#endif
  return multisim_server_push_core(server_name, data_handle, data_width, true);
}

#if defined(MULTISIM_ZEBU)
#include <cstring>
#include <mutex>

// ZeBu: ZEMI3 transactor DPIs, see multisim_server_common.svh
//  - the server name is a packed string literal (right-justified, no string type in ZEMI3)
//  - pull/push are deferred DPIs: a single data output and done,
//    the 32-bit status word is {call_count[30:0], MULTISIM_SUCCESS|MULTISIM_FAIL}
//  - ZEMI3 calls the DPIs of different transactors from different threads: they are serialized
static uint32_t zebu_call_cnt[MULTISIM_SERVER_MAX];
static std::mutex zebu_mutex;

static std::string zebu_server_name(const svBitVecVal *server_name) {
  std::string name;
  for (int i = MULTISIM_SERVER_NAME_LEN; i >= 0; i--) {
    char c = (server_name[i / 4] >> (8 * (i % 4))) & 0xff;
    if (c != 0) {
      name += c;
    }
  }
  // the port keeps the last MULTISIM_SERVER_NAME_LEN+1 characters of longer names
  if (name.size() > MULTISIM_SERVER_NAME_LEN) {
    fprintf(stderr, "ERROR: multisim: server name [...%s] has more than %d characters\n",
            name.c_str(), MULTISIM_SERVER_NAME_LEN);
    exit(EXIT_FAILURE);
  }
  return name;
}

// start the server on its first call: ZEMI3 does not order calls from different processes
static std::string zebu_server_start(const svBitVecVal *server_name) {
  std::string name = zebu_server_name(server_name);
  if (server_name_to_idx.find(name) == server_name_to_idx.end()) {
    // the Server keeps the name pointer
    multisim_server_start(strdup(name.c_str()));
  }
  return name;
}

static inline uint32_t zebu_status(std::string const &name, int r) {
  int idx = server_name_to_idx[name];
  zebu_call_cnt[idx]++;
  return (zebu_call_cnt[idx] << 1) | (r == MULTISIM_SUCCESS ? 1 : 0);
}

extern "C" void multisim_server_start_zebu(const svBitVecVal *server_name) {
  std::lock_guard<std::mutex> lock(zebu_mutex);
  zebu_server_start(server_name);
}

extern "C" void multisim_server_pull_zebu(svBitVecVal *status_data, svBit *done,
                                          const svBitVecVal *server_name, int data_width) {
  std::lock_guard<std::mutex> lock(zebu_mutex);
  std::string name = zebu_server_start(server_name);
  int r = multisim_server_pull_core(name.c_str(), status_data, data_width, false);
  status_data[(data_width + 31) / 32] = zebu_status(name, r);
  *done = 1;
}

extern "C" void multisim_server_push_zebu(svBitVecVal *status, svBit *done,
                                          const svBitVecVal *server_name, const svBitVecVal *data,
                                          int data_width) {
  std::lock_guard<std::mutex> lock(zebu_mutex);
  std::string name = zebu_server_start(server_name);
  int r = multisim_server_push_core(name.c_str(), (data_handle_t)data, data_width, false);
  status[0] = zebu_status(name, r);
  *done = 1;
}
#endif
