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
#include <unistd.h>

// send() fails instead of killing the process (SIGPIPE) when the peer is gone
#ifndef MSG_NOSIGNAL
#define MSG_NOSIGNAL 0
#endif
#include "socket_io.h"

/**
 * Implementation of a non-blocking socket client
 *
 * Connects to the Unix socket of the server when it is on the same host, to its TCP port otherwise
 */
class Client {
public:
  Client(char const *server_info_dir, char const *name);
  void start();
  int startWithAddressAndPort(char const *server_address, int server_port);
  int startWithUnixSocket(std::string const &path);
  int getSocket();
  char const *clientIp;
  char const *serverName;
  char const *serverInfoDir;
  char const *serverIp;
  int serverPort;
  std::string serverUnixSocket; // empty when the server has none
  std::string serverAddress;    // of the connection: Unix socket path or ip:port

private:
  char const *getIp();
  int new_socket;
  int getServerIpAndPort(char const *server_file);
};
#endif
