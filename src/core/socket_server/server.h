#ifndef SERVER_H
#define SERVER_H

#include <arpa/inet.h>
#include <fcntl.h>
#include <ifaddrs.h>
#include <set>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <sys/socket.h>
#include <sys/stat.h>
#include <unistd.h>

// send() fails instead of killing the process (SIGPIPE) when the peer is gone
#ifndef MSG_NOSIGNAL
#define MSG_NOSIGNAL 0
#endif
#include "socket_io.h"

#define BASE_PORT 8100

/**
 * Implementation of a non-blocking socket server
 *
 * Main features:
 *  - finds 1st port available starting from BASE_PORT
 *  - also listens on a Unix socket for the clients of the same host (unix_socket.h)
 *  - write port, ip and Unix socket info in 'server_<serverName>.txt' at start()
 *  - forbids servers with the same name
 */
class Server {
public:
  Server(char const *server_info_dir, char const *name);
  void start();
  int acceptNewSocket();
  char const *serverName;
  char const *serverInfoDir;
  char const *serverIp;
  int serverPort;

private:
  int server_fd;
  int unix_fd = -1;
  std::string unixSocketPath;
  void startUnixSocket();
  struct sockaddr_in address;
  int addrlen = sizeof(address);
  bool serverIsRunning = false;
  char const *getIp();
  static std::set<std::string> serverNameSet;
};
#endif
