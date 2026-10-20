// server: push N numbered messages of W bits, client: pull them after 1 s and check them
#ifdef ROLE_CLIENT
#include "multisim_client.h"
#else
#include "multisim_server.h"
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <vector>

int main(int argc, char **argv) {
  int w = atoi(argv[1]), n = atoi(argv[2]);
  std::vector<uint32_t> buf((w + 31) / 32);
#ifdef ROLE_CLIENT
  multisim_client_start(".", "ch");
  sleep(1); // let the server fill the socket buffers
  for (int i = 0; i < n; i++) {
    memset(buf.data(), 0xff, buf.size() * 4);
    if (!multisim_client_pull("ch", buf.data(), w)) {
      printf("client: pull %d failed\n", i);
      return 1;
    }
    for (size_t k = 0; k < buf.size(); k++) {
      if (buf[k] != (uint32_t)(i * 7919 + k)) {
        printf("client: message %d word %zu is 0x%08x\n", i, k, buf[k]);
        return 1;
      }
    }
  }
  return 0;
#else
  multisim_server_start("ch");
  for (int i = 0; i < n; i++) {
    for (size_t k = 0; k < buf.size(); k++)
      buf[k] = i * 7919 + k;
    while (!multisim_server_push("ch", buf.data(), w))
      usleep(10);
  }
  pause();
  return 0;
#endif
}
