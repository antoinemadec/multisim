#ifndef UNIX_SOCKET_H
#define UNIX_SOCKET_H

#include "info_file.h"
#include <fcntl.h>
#include <stdio.h>
#include <string>
#include <sys/un.h>
#include <unistd.h>

// Unix socket of a server, for the clients running on its host (lower latency than TCP):
// the server listens on <info_dir>/server_<name>.sock and publishes the absolute path of the
// socket in its info file, a client that cannot connect to it (other host) uses TCP

// file name of the socket, short enough for a sun_path (see unix_socket_addr)
inline std::string unix_socket_file(std::string const &name) {
  if (name.size() <= 64) {
    return "server_" + name + ".sock";
  }
  return "server_" + name.substr(0, 40) + "_" + fnv1a_hash_str(name) + ".sock";
}

// fill addr with the path dir/file; a path too long for a sun_path (108 bytes) goes through
// /proc/self/fd/<fd of dir>/file (Linux), *dirfd is then the fd to close after the bind/connect
// returns 0 on success
inline int unix_socket_addr(std::string const &dir, std::string const &file,
                            struct sockaddr_un *addr, int *dirfd) {
  std::string path = dir + "/" + file;
  *dirfd = -1;
  if (path.size() >= sizeof(addr->sun_path)) {
    *dirfd = open(dir.c_str(), O_RDONLY | O_DIRECTORY);
    if (*dirfd < 0) {
      return -1;
    }
    path = "/proc/self/fd/" + std::to_string(*dirfd) + "/" + file;
    if (path.size() >= sizeof(addr->sun_path)) {
      close(*dirfd);
      *dirfd = -1;
      return -1;
    }
  }
  memset(addr, 0, sizeof(*addr));
  addr->sun_family = AF_UNIX;
  strcpy(addr->sun_path, path.c_str());
  return 0;
}
#endif
