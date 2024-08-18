#include <stdio.h>
#include <unistd.h>
#include "stdlib.h"
#include "svdpi.h"
#include "server/server.h"


extern "C" int dpi_cpu_server_start(int idx);
extern "C" int dpi_cpu_server_get_data(int idx, svBitVecVal data[2]);

#define CPU_NUMBER 16

Server *server[CPU_NUMBER];
int new_socket[CPU_NUMBER];


int dpi_cpu_server_start(int idx)
{
  char *str = new char[80];
  sprintf(str, "cpu_%0d", idx);
  server[idx] = new Server(str);
  server[idx]->start();
  new_socket[idx] = -1;
  return 0;
}


int dpi_cpu_server_get_data(int idx, svBitVecVal* data) {
  uint32_t read_buf[2];
  int r;

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
