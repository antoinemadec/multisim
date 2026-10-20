// server: pull N messages from successive clients, then print its number of open files
// client: push 1 message and exit
#ifdef ROLE_CLIENT
#include "multisim_client.h"
#else
#include "multisim_server.h"
#endif
#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char **argv) {
  uint32_t data[1] = {1};
#ifdef ROLE_CLIENT
  multisim_client_start(".", "ch");
  return multisim_client_push("ch", data, 32) ? 0 : 1;
#else
  multisim_server_start("ch");
  for (int n = atoi(argv[1]); n > 0;)
    if (multisim_server_pull("ch", data, 32))
      n--;
    else
      usleep(100);
  int fds = -2; // . and ..
  DIR *d = opendir("/proc/self/fd");
  while (readdir(d))
    fds++;
  printf("fds: %d\n", fds - 1); // opendir
  return 0;
#endif
}
