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

/**
 * Implementation of a non-blocking socket client
 */
class Client {
public:
  Client(char const *name);
  int start(char const *server_address, int server_port);
  int getSocket();

private:
  int new_socket;
};
#endif
