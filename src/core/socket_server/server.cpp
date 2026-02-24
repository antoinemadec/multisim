#include "server.h"
#include <string>

std::set<char const *> Server::serverNameSet;

Server::Server(char const *server_info_dir, char const *name)
    : serverInfoDir(server_info_dir), serverName(name) {
  char *name_copy = new char[SERVERNAME_MAX_SIZE];
  strcpy(name_copy, name);
  if (Server::serverNameSet.find(name_copy) != Server::serverNameSet.end()) {
    fprintf(stderr, "ERROR: server name [%s] already exist, use another name\n", name_copy);
    exit(EXIT_FAILURE);
  }
  Server::serverNameSet.insert(name_copy);
}

void Server::start() {
  int i = 0;
  FILE *fp;
  std::string server_info_file;

  // create server
  if (serverIsRunning) {
    fprintf(stderr, "ERROR: server [%s] start() has already been called\n", serverName);
    exit(EXIT_FAILURE);
  }
  if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
    perror("socket failed");
    exit(EXIT_FAILURE);
  }
  fcntl(server_fd, F_SETFL, O_NONBLOCK);
  address.sin_family = AF_INET;
  address.sin_addr.s_addr = INADDR_ANY;
  while (1) {
    serverPort = BASE_PORT + i;
    address.sin_port = htons(serverPort);
    if (::bind(server_fd, (struct sockaddr *)&address, addrlen) >= 0)
      break;
    i++;
  }
  if (listen(server_fd, 8) < 0) {
    perror("listen");
    exit(EXIT_FAILURE);
  }
  serverIp = getIp();
  serverIsRunning = true;

  // print server's ip and port
  mkdir(serverInfoDir, 0777);
  server_info_file = std::string(serverInfoDir) + "/server_" + std::string(serverName) + ".txt";
  fp = fopen(server_info_file.c_str(), "w+");
  fprintf(fp, "ip: %s\n", serverIp);
  fprintf(fp, "port: %0d\n", serverPort);
  fflush(fp);
  fclose(fp);
  printf("Server: [%s] has started, info in %s\n", serverName, server_info_file.c_str());
}

int Server::acceptNewSocket() {
  int new_socket;
  new_socket = accept(server_fd, (struct sockaddr *)&address, (socklen_t *)&addrlen);
  fcntl(new_socket, F_SETFL, O_NONBLOCK);
  return new_socket;
}

char const *Server::getIp() {
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
