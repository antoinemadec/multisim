CLIENT_SRC := multisim_client.cpp socket_server/client.cpp
CLIENT_HEADERS := multisim_client.h socket_server/client.h

SERVER_SRC := multisim_server.cpp socket_server/server.cpp
SERVER_HEADERS := multisim_server.h socket_server/server.h

CXXFLAGS := -std=c++17 -fPIC -g -shared -fPIC -m64 -DMULTISIM_SW
CXX := g++


all: multisim_client.so multisim_server.so

multisim_client.so: $(CLIENT_SRC) $(CLIENT_HEADERS)
	g++ $(CXXFLAGS) $(CLIENT_SRC) -o $@


multisim_server.so: $(SERVER_SRC) $(SERVER_HEADERS)
	g++ $(CXXFLAGS) $(SERVER_SRC) -o $@

clean:
	rm -f *.so
