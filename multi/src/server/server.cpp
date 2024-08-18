#include "server.h"


std::set<char const *> Server::serverNameSet;


Server::Server(char const *name) : serverName(name) {
  if (Server::serverNameSet.find(name) != Server::serverNameSet.end())
  {
    fprintf(stderr, "ERROR: server name [%s] already exist, use another name\n", name);
    exit(EXIT_FAILURE);
  }
  Server::serverNameSet.insert(name);
}


void Server::start() {
  int i = 0;
  FILE *fp;

  // create server
  if (serverIsRunning) {
    fprintf(stderr, "ERROR: server [%s] start() has already been called\n", serverName);
    exit(EXIT_FAILURE);
  }
  if ((server_fd = socket(AF_INET, SOCK_NONBLOCK | SOCK_STREAM, 0)) == 0)
  {
    perror("socket failed");
    exit(EXIT_FAILURE);
  }
  address.sin_family = AF_INET;
  address.sin_addr.s_addr = INADDR_ANY;
  while (1) {
    serverPort = BASE_PORT + i;
    address.sin_port = htons(serverPort);
    if (bind(server_fd, (struct sockaddr *)&address, addrlen) >= 0)
      break;
    i++;
  }
  if (listen(server_fd, 8) < 0)
  {
    perror("listen");
    exit(EXIT_FAILURE);
  }
  serverIp = getIp();
  serverIsRunning = true;

  // print server's ip and port
  snprintf(serverInfoFile, FILENAME_MAX_SIZE, "server_%s.txt", serverName);
  fp = fopen(serverInfoFile, "w+");
  fprintf(fp, "ip: %s\n", serverIp);
  fprintf(fp, "port: %0d\n", serverPort);
  fclose(fp);
  printf("Server: [%s] has started, info in %s\n", serverName, serverInfoFile);
}


int Server::acceptNewSocket() {
  int new_socket;
  new_socket = accept(server_fd, (struct sockaddr *)&address, (socklen_t*)&addrlen);
  fcntl(new_socket, F_SETFL, O_NONBLOCK);
  return new_socket;
}


char const *Server::getIp() {
  setenv("LANG","C",1);
  FILE * fp = popen("hostname -i", "r");
  if (fp) {
    char *p=NULL; size_t n;
    while ((getline(&p, &n, fp) > 0) && p) {
      char *pos;
      if ((pos=strchr(p, '\n')) != NULL)
        *pos = '\0';
      return p;
    }
  }
  pclose(fp);
  return NULL;
}
