// server: start the servers NAME... (a NAME of digits only is replaced by that many letters),
// push 0x12345678 to each of them until accepted, then wait
// client: start the clients NAME..., pull the value of each server and check it
#ifdef ROLE_CLIENT
#include "multisim_client.h"
#else
#include "multisim_server.h"
#endif
#include <stdio.h>
#include <string>
#include <unistd.h>
#include <vector>

int main(int argc, char **argv) {
  std::vector<std::string> names;
  for (int i = 1; i < argc; i++) {
    std::string arg = argv[i];
    if (arg.find_first_not_of("0123456789") == std::string::npos) {
      std::string name;
      for (int k = 0; k < std::stoi(arg); k++)
        name += 'a' + k % 26;
      names.push_back(name);
    } else {
      names.push_back(arg);
    }
  }
  uint32_t data[1] = {0x12345678};
#ifdef ROLE_CLIENT
  for (auto &n : names)
    multisim_client_start(".", n.c_str());
  for (auto &n : names) {
    data[0] = 0;
    if (!multisim_client_pull(n.c_str(), data, 32) || data[0] != 0x12345678)
      return 1;
  }
  return 0;
#else
  for (auto &n : names)
    multisim_server_start(n.c_str());
  for (auto &n : names)
    while (!multisim_server_push(n.c_str(), data, 32))
      usleep(1000);
  pause();
  return 0;
#endif
}
