#include "client.h"
#include <string>

Client::Client(char const *server_info_dir, char const *name)
    : serverInfoDir(server_info_dir), serverName(name) {};

void Client::start() {
  int i;
  std::string server_file = std::string(serverInfoDir) + "/server_" + std::string(serverName) + ".txt";

  i = 0;
  while (!getServerIpAndPort(server_file.c_str())) {
    if (i == 0) {
      printf("Client: waiting for server %s info file %s\n", serverName, server_file.c_str());
    }
    i++;
    usleep(100000); // wait for 0.1s
  };

  i = 0;
  while (!startWithAddressAndPort(serverIp, serverPort)) {
    if (i == 0) {
      printf("Client: failed to connect to server %s at %s:%0d\n", serverName, serverIp, serverPort);
    }
    i++;
    usleep(100000); // wait for 0.1s
  };
  printf("Client: connect to server %s at %s:%0d\n", serverName, serverIp, serverPort);
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
    return 0;
  }
  if (connect(new_socket, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
    return 0;
  }
  fcntl(new_socket, F_SETFL, O_NONBLOCK);

  clientIp = getIp();

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
  fscanf(fp, "%s %s", &garbage[0], &ip_str[0]); // read "ip: xxx.xxx.xxx.xxx"
  serverIp = (char *)malloc(128);
  strcpy((char *)serverIp, &ip_str[0]);
  fscanf(fp, "%s %d", &garbage[0], &serverPort); // read "port: xxxxx"
  fclose(fp);
  return 1;
}
