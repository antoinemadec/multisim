#include <stdio.h>
#include <unistd.h>
#include "stdlib.h"
#include "svdpi.h"
#include "client/client.h"

extern "C" int multisim_client_start(int idx, char const *server_address, int server_port);
extern "C" int multisim_client_send_data(const svBitVecVal *data);

int new_socket = 0;

int multisim_client_start(int idx, char const *server_address, int server_port) {
  char *str = new char[80];
  sprintf(str, "cpu_%0d", idx);
  Client *client = new Client(str);
  if (!client->start(server_address, server_port)) {
    return 0;
  }
  new_socket = client->getSocket();
  printf("Client: [client_cpu_%0d] has started at %s:%0d\n", idx, server_address, server_port);
  return 1;
}

int multisim_client_send_data(const svBitVecVal *data) {
  int r;
  uint32_t send_buf[2];
  send_buf[0] = data[0];
  send_buf[1] = data[1];
  r = send(new_socket, send_buf, sizeof(send_buf), 0);
  if (r <= 0) { // send failed
    return 0;
  }
  return 1;
}
