#include "socket_server/client.h"

#include <cassert>
#include <map>
#include "stdlib.h"
#include <string>
#include <stdio.h>
#include "svdpi.h"
#include <unistd.h>

using namespace std;

extern "C" int multisim_client_start(char const *server_name,
                                     char const *server_address,
                                     int server_port);
extern "C" int multisim_client_send_data(char const *server_name, const svBitVecVal *data, int data_width);
extern "C" int multisim_client_get_data(char const *server_name, svBitVecVal *data, int data_width);

#define MULTISIM_SERVER_MAX 256
int new_socket[MULTISIM_SERVER_MAX];
int server_idx = 0;
map<string, int> server_name_to_idx;

int multisim_client_start(char const *server_name, char const *server_address,
                          int server_port) {
  Client *client = new Client(server_name);
  assert(server_idx < MULTISIM_SERVER_MAX);
  if (!client->start(server_address, server_port)) {
    return 0;
  }
  new_socket[server_idx] = client->getSocket();
  printf("Client: [%s] has started at %s:%0d\n", server_name, server_address,
         server_port);
  server_name_to_idx[server_name] = server_idx;
  server_idx++;
  return 1;
}

int multisim_client_send_data(char const *server_name, const svBitVecVal *data, int data_width) {
  int r;
  int buf_32b_size = (data_width + 31) / 32;
  uint32_t send_buf[buf_32b_size];
  int idx = server_name_to_idx[server_name];

  for (int i = 0; i < buf_32b_size; i++) {
    send_buf[i] = data[i];
  }

  r = send(new_socket[idx], send_buf, sizeof(send_buf), 0);
  if (r <= 0) { // send failed
    return 0;
  }
  return 1;
}

int multisim_client_get_data(char const *server_name, svBitVecVal *data, int data_width) {
  int r;
  int buf_32b_size = (data_width + 31) / 32;
  uint32_t read_buf[buf_32b_size];
  int idx = server_name_to_idx[server_name];

  r = read(new_socket[idx], read_buf, sizeof(read_buf));
  if (r <= 0) {
    return 0;
  }

  for (int i = 0; i < buf_32b_size; i++) {
    data[i] = read_buf[i];
  }
  return 1;
}
