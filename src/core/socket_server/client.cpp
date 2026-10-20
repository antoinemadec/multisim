#include "client.h"
#include "info_file.h"
#include "unix_socket.h"
#include <string>

Client::Client(char const *server_info_dir, char const *name)
    : serverInfoDir(server_info_dir), serverName(name) {};

void Client::start() {
  int i;
  std::string server_file = info_file_path(serverInfoDir, "server_", serverName);

  i = 0;
  while (!getServerIpAndPort(server_file.c_str())) {
    if (i == 0) {
      printf("Client: waiting for server %s info file %s\n", serverName, server_file.c_str());
    }
    i++;
    usleep(100000); // wait for 0.1s
  };

  i = 0;
  // the Unix socket first: it only answers on the host of the server
  while (
      !(startWithUnixSocket(serverUnixSocket) || startWithAddressAndPort(serverIp, serverPort))) {
    if (i == 0) {
      printf("Client: failed to connect to server %s at %s:%0d\n", serverName, serverIp,
             serverPort);
    }
    i++;
    usleep(100000); // wait for 0.1s
    // the info file can be a stale one: read it again
    getServerIpAndPort(server_file.c_str());
  };
  printf("Client: connect to server %s at %s\n", serverName, serverAddress.c_str());
}

// connect to the Unix socket of the server, 0 if path is empty or the server is on another host
int Client::startWithUnixSocket(std::string const &path) {
  struct sockaddr_un addr;
  int dirfd = -1;
  size_t slash = path.rfind('/');
  if (path.empty() || slash == std::string::npos) {
    return 0;
  }
  if ((new_socket = socket(AF_UNIX, SOCK_STREAM, 0)) < 0) {
    return 0;
  }
  if (unix_socket_addr(path.substr(0, slash), path.substr(slash + 1), &addr, &dirfd) < 0 ||
      connect(new_socket, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
    if (dirfd >= 0) {
      close(dirfd);
    }
    close(new_socket);
    return 0;
  }
  if (dirfd >= 0) {
    close(dirfd);
  }
  fcntl(new_socket, F_SETFL, O_NONBLOCK);
  clientIp = getIp();
  serverAddress = path;
  return 1;
}

int Client::startWithAddressAndPort(char const *server_address, int server_port) {
  struct sockaddr_in serv_addr;
  // connect to server
  if ((new_socket = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
    return 0;
  }
  memset(&serv_addr, '0', sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  serv_addr.sin_port = htons(server_port);
  if (inet_pton(AF_INET, server_address, &serv_addr.sin_addr) <= 0) {
    close(new_socket);
    return 0;
  }
  if (connect(new_socket, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
    close(new_socket);
    return 0;
  }
  fcntl(new_socket, F_SETFL, O_NONBLOCK);

  clientIp = getIp();
  serverAddress = std::string(server_address) + ":" + std::to_string(server_port);

  return 1;
}

int Client::getSocket() { return new_socket; }

char const *Client::getIp() {
  struct ifaddrs *ifaddr, *ifa;
  if (getifaddrs(&ifaddr) == -1)
    return "127.0.0.1";
  for (ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
    if (ifa->ifa_addr == NULL || ifa->ifa_addr->sa_family != AF_INET)
      continue;
    // Skip loopback
    if (strcmp(ifa->ifa_name, "lo") == 0 || strcmp(ifa->ifa_name, "lo0") == 0)
      continue;
    char *ip = new char[INET_ADDRSTRLEN];
    struct sockaddr_in *sa = (struct sockaddr_in *)ifa->ifa_addr;
    inet_ntop(AF_INET, &sa->sin_addr, ip, INET_ADDRSTRLEN);
    freeifaddrs(ifaddr);
    return ip;
  }
  freeifaddrs(ifaddr);
  return "127.0.0.1";
}

int Client::getServerIpAndPort(char const *server_file) {
  FILE *fp = fopen(server_file, "r");
  char garbage[128];
  char ip_str[128];
  if (fp == NULL) {
    return 0;
  }
  int port;
  // read "ip: xxx.xxx.xxx.xxx" and "port: xxxxx", the server can still be writing the file
  if (fscanf(fp, "%127s %127s", &garbage[0], &ip_str[0]) != 2 ||
      fscanf(fp, "%127s %d", &garbage[0], &port) != 2) {
    fclose(fp);
    return 0;
  }
  serverIp = (char *)malloc(128);
  strcpy((char *)serverIp, &ip_str[0]);
  serverPort = port;
  // optional "unix: /path/of/the/socket"
  char unix_path[4096];
  serverUnixSocket = "";
  if (fscanf(fp, "%127s %4095s", &garbage[0], &unix_path[0]) == 2 &&
      strcmp(garbage, "unix:") == 0) {
    serverUnixSocket = unix_path;
  }
  fclose(fp);
  return 1;
}
