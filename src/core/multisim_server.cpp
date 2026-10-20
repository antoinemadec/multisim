#include "multisim_server.h"
#include "multisim_common.h"
#include "socket_server/server.h"

#include <cassert>
#include <errno.h>
#include <map>
#include <string>
#include <unistd.h>

static Server *server[MULTISIM_SERVER_MAX];
static int sockets[MULTISIM_SERVER_MAX];
static int server_idx = 0;
static std::map<std::string, int> server_name_to_idx;

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

// index of a started server, the name of a server that was not started is an error
static int get_server_idx(char const *server_name) {
  auto it = server_name_to_idx.find(server_name);
  if (it == server_name_to_idx.end()) {
    fprintf(stderr, "ERROR: multisim: server of server [%s] was not started\n", server_name);
    exit(EXIT_FAILURE);
  }
  return it->second;
}

static inline int multisim_server_pull_core(char const *server_name, data_handle_t data_handle,
                                            int data_width, bool is_4state) {
  int r;
  int buf_32b_size = (data_width + 31) / 32;
  uint32_t read_buf[is_4state ? 2 * buf_32b_size : buf_32b_size];
  int idx = get_server_idx(server_name);
#if defined(MULTISIM_SV_DPI_OPEN_ARRAY)
  svBitVecVal *data = NULL;
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

  // 2-state data is read into the SV array itself
  r = read_msg(sockets[idx], is_4state ? read_buf : data, sizeof(read_buf));
  if (r <= 0) {
    // -1: nothing to send
    // 0: client disconnected
    if (r == 0) {
      close(sockets[idx]);
      sockets[idx] = -1;
    }
    return MULTISIM_FAIL;
  }

  if (is_4state) {
    for (int i = 0; i < buf_32b_size; i++) {
#if defined(MULTISIM_SV_DPI_OPEN_ARRAY)
      data_4state[i].aval = read_buf[i];
      data_4state[i].bval = read_buf[buf_32b_size + i];
#else
      data[i] = read_buf[i];
      data[buf_32b_size + i] = read_buf[buf_32b_size + i];
#endif
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
  int idx = get_server_idx(server_name);
#if defined(MULTISIM_SV_DPI_OPEN_ARRAY)
  svBitVecVal *data = NULL;
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

  // 2-state data is sent from the SV array itself, 4-state data as {aval..., bval...}
  const void *msg = data;
  if (is_4state) {
    for (int i = 0; i < buf_32b_size; i++) {
#if defined(MULTISIM_SV_DPI_OPEN_ARRAY)
      send_buf[i] = data_4state[i].aval;
      send_buf[buf_32b_size + i] = data_4state[i].bval;
#else
      send_buf[i] = data[i];
      send_buf[buf_32b_size + i] = data[buf_32b_size + i];
#endif
    }
    msg = send_buf;
  }

#ifdef SIMULATE_SEND_FAIL_SERVER
  static int cnt = 0;
  cnt++;
  if (cnt % 1000 == 0) {
    printf("multisim_server_push: simulate send fail\n");
    return MULTISIM_FAIL;
  }
#endif

  r = send_msg(sockets[idx], msg, sizeof(send_buf));
  if (r <= 0) { // send failed
    // the client disconnected (0, EPIPE...): the next push accepts a new client
    if (r == 0 || (errno != EAGAIN && errno != EWOULDBLOCK)) {
      close(sockets[idx]);
      sockets[idx] = -1;
    }
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
#include <vector>

// ZeBu: ZEMI3 transactor DPIs, see multisim_server_common.svh
//  - the server name is a packed string literal (right-justified, no string type in ZEMI3)
//  - pull/push are deferred DPIs: a single data output and done,
//    the 32-bit status word is {call_count[30:0], MULTISIM_SUCCESS|MULTISIM_FAIL}
//  - ZEMI3 calls the DPIs of different transactors from different threads: they are serialized
static uint32_t zebu_call_cnt[MULTISIM_SERVER_MAX];
static std::mutex zebu_mutex;

static const int ZEBU_NAME_WORDS = (MULTISIM_SERVER_NAME_LEN + 1 + 3) / 4;

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

// server of a packed name: started on its first call (ZEMI3 does not order calls from
// different processes), then found by comparing the packed name with the ones already
// decoded, without decoding it again
struct ZebuServer {
  svBitVecVal packed_name[ZEBU_NAME_WORDS];
  char const *name; // the Server keeps this pointer
  int idx;
};
static std::vector<ZebuServer> zebu_servers;

static ZebuServer const &zebu_server_start(const svBitVecVal *server_name) {
  for (auto const &s : zebu_servers) {
    if (memcmp(s.packed_name, server_name, sizeof(s.packed_name)) == 0) {
      return s;
    }
  }
  ZebuServer s;
  memcpy(s.packed_name, server_name, sizeof(s.packed_name));
  s.name = strdup(zebu_server_name(server_name).c_str());
  if (server_name_to_idx.find(s.name) == server_name_to_idx.end()) {
    multisim_server_start(s.name);
  }
  s.idx = server_name_to_idx[s.name];
  zebu_servers.push_back(s);
  return zebu_servers.back();
}

static inline uint32_t zebu_status(ZebuServer const &s, int r) {
  zebu_call_cnt[s.idx]++;
  return (zebu_call_cnt[s.idx] << 1) | (r == MULTISIM_SUCCESS ? 1 : 0);
}

extern "C" void multisim_server_start_zebu(const svBitVecVal *server_name) {
  std::lock_guard<std::mutex> lock(zebu_mutex);
  zebu_server_start(server_name);
}

extern "C" void multisim_server_pull_zebu(svBitVecVal *status_data, svBit *done,
                                          const svBitVecVal *server_name, int data_width) {
  std::lock_guard<std::mutex> lock(zebu_mutex);
  ZebuServer const &s = zebu_server_start(server_name);
  int r = multisim_server_pull_core(s.name, status_data, data_width, false);
  status_data[(data_width + 31) / 32] = zebu_status(s, r);
  *done = 1;
}

extern "C" void multisim_server_push_zebu(svBitVecVal *status, svBit *done,
                                          const svBitVecVal *server_name, const svBitVecVal *data,
                                          int data_width) {
  std::lock_guard<std::mutex> lock(zebu_mutex);
  ZebuServer const &s = zebu_server_start(server_name);
  int r = multisim_server_push_core(s.name, (data_handle_t)data, data_width, false);
  status[0] = zebu_status(s, r);
  *done = 1;
}
#endif
