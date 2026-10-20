// a process that is both a server and a client of another server
#include "multisim_client.h"
#include "multisim_server.h"
#include <unistd.h>

int main() {
  uint32_t out[2] = {0x11111111, 0x22222222}, in[2] = {0, 0};
  multisim_server_start("ch");
  if (fork() == 0) {
    multisim_client_start(".", "ch");
    multisim_client_push("ch", out, 64);
    _exit(0);
  }
  for (int i = 0; i < 100000 && !multisim_server_pull("ch", in, 64); i++)
    usleep(100);
  return in[0] == out[0] && in[1] == out[1] ? 0 : 1;
}
