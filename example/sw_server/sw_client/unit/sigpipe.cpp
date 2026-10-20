// client: pull 10 messages and exit, server: push them, then keep pushing for 2 s
#ifdef ROLE_CLIENT
#include "multisim_client.h"
#else
#include "multisim_server.h"
#endif
#include <time.h>
#include <unistd.h>

int main() {
  uint32_t data[2] = {1, 2};
#ifdef ROLE_CLIENT
  multisim_client_start(".", "ch");
  for (int i = 0; i < 10; i++)
    multisim_client_pull("ch", data, 64);
#else
  multisim_server_start("ch");
  for (int n = 0; n < 10;)
    n += multisim_server_push("ch", data, 64);
  for (time_t t = time(NULL); time(NULL) < t + 2;) {
    multisim_server_push("ch", data, 64);
    usleep(100);
  }
#endif
  return 0;
}
