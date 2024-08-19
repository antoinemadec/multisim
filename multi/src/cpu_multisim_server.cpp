#include "server/server.h"

#include <cassert>
#include <map>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <svdpi.h>
#include <unistd.h>

using namespace std;

extern "C" int multisim_server_start(char const *server_name);
extern "C" int multisim_server_get_data(char const *server_name,
                                        svBitVecVal data[2]);

#define MULTISIM_SERVER_MAX 256
Server *server[MULTISIM_SERVER_MAX];
int new_socket[MULTISIM_SERVER_MAX];
int server_idx = 0;
map<string, int> server_name_to_idx;

int multisim_server_start(char const *server_name) {
  char *str = new char[80];
  assert(server_idx < MULTISIM_SERVER_MAX);
  strcpy(str, server_name);
  server[server_idx] = new Server(str);
  server[server_idx]->start();
  new_socket[server_idx] = -1;
  server_name_to_idx[server_name] = server_idx;
  server_idx++;
  return 0;
}

int multisim_server_get_data(char const *server_name, svBitVecVal *data) {
  uint32_t read_buf[2];
  int r;
  int idx = server_name_to_idx[server_name];

  if (new_socket[idx] < 0) {
    new_socket[idx] = server[idx]->acceptNewSocket();
    if (new_socket[idx] < 0) {
      return 0;
    }
  }

  r = read(new_socket[idx], read_buf, sizeof(read_buf));
  if (r <= 0) {
    // -1: nothing to send
    // 0: client disconnected
    if (r == 0) {
      new_socket[idx] = -1;
    }
    return 0;
  }

  data[0] = read_buf[0];
  data[1] = read_buf[1];
  return 1;
}
