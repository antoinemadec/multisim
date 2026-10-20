// client: pull from a server that was not started
#include "multisim_client.h"

int main() {
  uint32_t data[1];
  multisim_client_start(".", "a");
  multisim_client_pull("b", data, 32);
  return 0;
}
