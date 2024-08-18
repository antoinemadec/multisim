#include "client.h"

Client::Client(char const *name){};

int Client::start(char const *server_address, int server_port) {
  struct sockaddr_in serv_addr;
  // connect to server
  if ((new_socket = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
    // printf("\n Socket creation error \n");
    return 0;
  }
  memset(&serv_addr, '0', sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  serv_addr.sin_port = htons(server_port);
  if (inet_pton(AF_INET, server_address, &serv_addr.sin_addr) <= 0) {
    // printf("\nInvalid address/ Address not supported \n");
    return 0;
  }
  if (connect(new_socket, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) <
      0) {
    // printf("\nConnection Failed \n");
    return 0;
  }

  return 1;
}

int Client::getSocket() { return new_socket; }
