# Available targets are:
#  - SIMULATION (default): called from SV as DPI
#  - EMULATION: called from SV as DPI, with fixed size array (open array is not supported)
#  - SW: called directly from software, send/get are blocking
TARGET ?= SIMULATION
TARGET_LC := $(shell echo $(TARGET) | tr A-Z a-z)

RELEASE_DIR ?= $(PWD)
CORE_DIR=./src/core

MULTISIM_HEADERS := $(CORE_DIR)/multisim_client.h $(CORE_DIR)/multisim_server.h $(CORE_DIR)/multisim_common.h
SOCKET_SERVER_HEADERS := $(CORE_DIR)/socket_server/client.h $(CORE_DIR)/socket_server/server.h
HEADERS := $(MULTISIM_HEADERS) $(SOCKET_SERVER_HEADERS)
CLIENT_SRC := $(CORE_DIR)/multisim_client.cpp $(CORE_DIR)/socket_server/client.cpp
SERVER_SRC := $(CORE_DIR)/multisim_server.cpp $(CORE_DIR)/socket_server/server.cpp

CXXFLAGS := -std=c++17 -fPIC -g -shared -fPIC -m64 -DMULTISIM_$(TARGET)
CXX := g++

create_release:	multisim_$(TARGET_LC)_client.so multisim_$(TARGET_LC)_server.so copy_headers

copy_headers:
	echo "$(MULTISIM_HEADERS)" | tr ' ' '\n' | xargs -I{} cp {} $(RELEASE_DIR)

multisim_%_client.so: $(CLIENT_SRC) $(HEADERS) $(RELEASE_DIR)
	g++ $(CXXFLAGS) $(CLIENT_SRC) -o $(RELEASE_DIR)/$@


multisim_%_server.so: $(SERVER_SRC) $(HEADERS) $(RELEASE_DIR)
	g++ $(CXXFLAGS) $(SERVER_SRC) -o $(RELEASE_DIR)/$@


$(RELEASE_DIR):
	mkdir -p $(RELEASE_DIR)

clean:
	rm -f *.so
