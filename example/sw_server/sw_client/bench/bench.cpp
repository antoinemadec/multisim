// multisim micro-benchmarks: bench MODE N W
//  pingpong: client push W bits then pull the echo, N times (latency)
//  stream:   server pushes N messages of W bits, client pulls them (throughput)
//  upstream: client pushes N messages of W bits, server pulls them (throughput, server side)
//  idle:     server calls pull N times with no data (cost of an empty poll)
#ifdef ROLE_CLIENT
#include "multisim_client.h"
#else
#include "multisim_server.h"
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <vector>

static double now() {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec + t.tv_nsec * 1e-9;
}

int main(int argc, char **argv) {
  const char *mode = argv[1];
  long n = atol(argv[2]);
  int w = atoi(argv[3]);
  std::vector<uint32_t> buf((w + 31) / 32, 0x5a5a5a5a);
  bool pp = !strcmp(mode, "pingpong"), st = !strcmp(mode, "stream");
  bool up = !strcmp(mode, "upstream");
#ifdef ROLE_CLIENT
  multisim_client_start(".", "req");
  multisim_client_start(".", "rsp");
  double t0 = now();
  for (long i = 0; i < n; i++) {
    if (pp || up) {
      buf[0] = i;
      while (!multisim_client_push("req", buf.data(), w))
        ;
    }
    if (pp || st) {
      while (!multisim_client_pull("rsp", buf.data(), w))
        ;
      if (buf[0] != (uint32_t)i) {
        printf("bad data %u at %ld\n", buf[0], i);
        return 1;
      }
    }
  }
  double dt = now() - t0;
  if (pp)
    printf("pingpong W=%d: %.2f us/round-trip\n", w, dt / n * 1e6);
  if (st)
    printf("stream W=%d: %.0f msg/s, %.1f MB/s\n", w, n / dt, n / dt * buf.size() * 4 / 1e6);
  if (!strcmp(mode, "idle") || up)
    sleep(3600); // the server measures and stops the benchmark
#else
  multisim_server_start("req");
  multisim_server_start("rsp");
  if (pp) {
    for (long i = 0; i < n; i++) {
      while (!multisim_server_pull("req", buf.data(), w))
        ;
      while (!multisim_server_push("rsp", buf.data(), w))
        ;
    }
  } else if (st) {
    for (long i = 0; i < n; i++) {
      buf[0] = i;
      while (!multisim_server_push("rsp", buf.data(), w))
        ;
    }
  } else if (up) {
    double t0 = 0;
    for (long i = 0; i < n; i++) {
      while (!multisim_server_pull("req", buf.data(), w))
        ;
      if (i == 0)
        t0 = now(); // from the 1st message: the client start is not measured
      if (buf[0] != (uint32_t)i) {
        printf("bad data %u at %ld\n", buf[0], i);
        return 1;
      }
    }
    double dt = now() - t0;
    printf("upstream W=%d: %.0f msg/s, %.1f MB/s\n", w, n / dt, n / dt * buf.size() * 4 / 1e6);
  } else {
    while (!multisim_server_push("rsp", buf.data(), w)) // wait for the client
      ;
    double t0 = now();
    for (long i = 0; i < n; i++)
      multisim_server_pull("req", buf.data(), w);
    printf("idle pull: %.3f us/call\n", (now() - t0) / n * 1e6);
  }
  sleep(1);
#endif
  return 0;
}
