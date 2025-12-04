#include "multisim_client.h"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>

int main() {
  int r;
  uint32_t write_buf[2];
  uint32_t read_buf[2];

  multisim_client_start(".", "exit");
  multisim_client_start(".", "rx32");
  multisim_client_start(".", "tx32");
  multisim_client_start(".", "rx64");
  multisim_client_start(".", "tx64");

  write_buf[0] = 0xcafedeca;
  write_buf[1] = 0xdeadbeef;

  //-----------------------------------------------------------
  // rx32->tx32
  //-----------------------------------------------------------
  printf("rx32: 0xcafedeca\n");
  r = multisim_client_send_data("rx32", write_buf, 32);
  assert(r > 0);

  r = multisim_client_get_data("tx32", read_buf, 32);
  printf("tx32: 0x%08x\n", read_buf[0]);
  assert(r > 0);

  // //-----------------------------------------------------------
  // // rx64->tx64
  // //-----------------------------------------------------------
  // printf("rx64: 0xcafedeca 0xdeadbeef\n");
  // r = write(socket_rx64, write_buf, 8);
  // assert(r > 0);
  //
  // r = read(socket_tx64, read_buf, 8);
  // printf("tx64: 0x%08x 0x%08x\n", read_buf[0], read_buf[1]);
  // assert(r > 0);
  //
  // //-----------------------------------------------------------
  // // exit
  // //-----------------------------------------------------------
  // printf("exit\n");
  // // sending whatever to exit socket will quit the Veloce
  // r = write(socket_exit, write_buf, 4);
  // assert(r > 0);

  return 0;
}
