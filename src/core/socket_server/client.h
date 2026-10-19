#ifndef SERVER_H
#define SERVER_H

#include <arpa/inet.h>
#include <fcntl.h>
#include <ifaddrs.h>
#include <set>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

// send() fails instead of killing the process (SIGPIPE) when the peer is gone
#ifndef MSG_NOSIGNAL
#define MSG_NOSIGNAL 0
#endif

/**
 * Implementation of a non-blocking socket client
 */
class Client {
public:
  Client(char const *server_info_dir, char const *name);
  void start();
  int startWithAddressAndPort(char const *server_address, int server_port);
  int getSocket();
  char const *clientIp;
  char const *serverName;
  char const *serverInfoDir;
  char const *serverIp;
  int serverPort;

private:
  char const *getIp();
  int new_socket;
  int getServerIpAndPort(char const *server_file);
};
#endif
