#include "multisim_client.h"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>

int main() {
  int r;
  uint32_t write_buf[2];
  uint32_t read_buf[2];

  multisim_client_start(".", "exit");
  multisim_client_start(".", "rx64");
  multisim_client_start(".", "tx64");

  write_buf[0] = 0xcafedeca;
  write_buf[1] = 0xdeadbeef;

  //-----------------------------------------------------------
  // rx64->tx64
  //-----------------------------------------------------------
  printf("rx64: 0xcafedeca 0xdeadbeef\n");
  r = multisim_client_send_data("rx64", write_buf, 64);
  assert(r > 0);

  r = multisim_client_get_data("tx64", read_buf, 64);
  printf("tx64: 0x%08x 0x%08x\n", read_buf[0], read_buf[1]);
  assert(r > 0);

  //-----------------------------------------------------------
  // exit
  //-----------------------------------------------------------
  printf("exit\n");
  // sending whatever to exit socket will quit the Veloce
  r = multisim_client_send_data("exit", write_buf, 32);
  assert(r > 0);

  return 0;
}
