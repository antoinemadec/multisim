#include "socket_server/client.h"
#include "stdlib.h"
#include "svdpi.h"
#include <stdio.h>
#include <unistd.h>

extern "C" int multisim_client_start(char const *server_name,
                                     char const *server_address,
                                     int server_port);
extern "C" int multisim_client_send_data(const svBitVecVal *data, int data_width);

int new_socket = 0;

int multisim_client_start(char const *server_name, char const *server_address,
                          int server_port) {
  Client *client = new Client(server_name);
  if (!client->start(server_address, server_port)) {
    return 0;
  }
  new_socket = client->getSocket();
  printf("Client: [%s] has started at %s:%0d\n", server_name, server_address,
         server_port);
  return 1;
}

int multisim_client_send_data(const svBitVecVal *data, int data_width) {
  int r;
  int buf_32b_size = (data_width + 31) / 32;
  uint32_t send_buf[buf_32b_size];

  for (int i = 0; i < buf_32b_size; i++) {
    send_buf[i] = data[i];
  }

  r = send(new_socket, send_buf, sizeof(send_buf), 0);
  if (r <= 0) { // send failed
    return 0;
  }
  return 1;
}
