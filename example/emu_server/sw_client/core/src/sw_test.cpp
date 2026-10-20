#include "multisim_client.h"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <sys/time.h>

#define BW_ITERATION_NB 100000
// push only and pull only tests alternate chunks of pushes and pulls:
// the loopback holds the data pushed but not pulled yet in the sockets, which have a limited size
#define BW_CHUNK_NB 1000

double get_secs(struct timeval start, struct timeval stop) {
  return (double)(stop.tv_usec - start.tv_usec) / 1000000 + (double)(stop.tv_sec - start.tv_sec);
}

void print_bw_secs(double secs, uint32_t byte_nb) {
  printf("time: %.3f s\n", secs);
  printf("byte_nb: %d\n", byte_nb);
  printf("BW = %0d B/sec\n", (uint32_t)(byte_nb / secs));
}

void print_bw_value(struct timeval start, struct timeval stop, uint32_t byte_nb) {
  print_bw_secs(get_secs(start, stop), byte_nb);
}

int main() {
  int r;
  uint32_t write_buf[2];
  uint32_t read_buf[2];
  struct timeval stop, start;

  multisim_client_start(".", "exit");
  multisim_client_start(".", "rx64");
  multisim_client_start(".", "tx64");

  write_buf[0] = 0xcafedeca;
  write_buf[1] = 0xdeadbeef;

  //-----------------------------------------------------------
  // rx64->tx64
  //-----------------------------------------------------------
  printf("\nloopback test\n");
  printf("rx64: 0xcafedeca 0xdeadbeef\n");
  r = multisim_client_push("rx64", write_buf, 64);
  assert(r > 0);

  r = multisim_client_pull("tx64", read_buf, 64);
  printf("tx64: 0x%08x 0x%08x\n", read_buf[0], read_buf[1]);
  assert(r > 0);
  assert(read_buf[0] == write_buf[0] && read_buf[1] == write_buf[1]);

  //-----------------------------------------------------------
  // bandwidth tests
  //-----------------------------------------------------------
  double push_secs = 0;
  double pull_secs = 0;
  for (int c = 0; c < BW_ITERATION_NB / BW_CHUNK_NB; c++) {
    gettimeofday(&start, NULL);
    for (int i = 0; i < BW_CHUNK_NB; i++) {
      r = multisim_client_push("rx64", write_buf, 64);
      assert(r > 0);
    }
    gettimeofday(&stop, NULL);
    push_secs += get_secs(start, stop);

    gettimeofday(&start, NULL);
    for (int i = 0; i < BW_CHUNK_NB; i++) {
      r = multisim_client_pull("tx64", read_buf, 64);
      assert(r > 0);
    }
    gettimeofday(&stop, NULL);
    pull_secs += get_secs(start, stop);
  }

  printf("\nbandwidth test: push only\n");
  print_bw_secs(push_secs, BW_ITERATION_NB * 8);

  printf("\nbandwidth test: pull only\n");
  print_bw_secs(pull_secs, BW_ITERATION_NB * 8);

  printf("\nbandwidth test: push/pull\n");
  gettimeofday(&start, NULL);
  for (int i = 0; i < BW_ITERATION_NB; i++) {
    r = multisim_client_push("rx64", write_buf, 64);
    assert(r > 0);
    r = multisim_client_pull("tx64", read_buf, 64);
    assert(r > 0);
  }
  gettimeofday(&stop, NULL);
  print_bw_value(start, stop, BW_ITERATION_NB * 8);

  //-----------------------------------------------------------
  // exit
  //-----------------------------------------------------------
  printf("exit\n");
  // sending whatever to exit socket will quit the Veloce
  r = multisim_client_push("exit", write_buf, 32);
  assert(r > 0);

  return 0;
}
