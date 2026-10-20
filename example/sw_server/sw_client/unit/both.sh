#!/usr/bin/env bash
# the client and server libraries link in the same process and work there
source "$(dirname "$0")/lib.sh"
$CXX -o both "$TEST_DIR/both.cpp" $CORE/multisim_client.cpp $CORE/socket_server/client.cpp \
  $CORE/multisim_server.cpp $CORE/socket_server/server.cpp > build.log 2>&1 ||
  fail "build: $(grep -m1 -i 'multiple definition' build.log)"
timeout 30 ./both > both.log 2>&1 || fail "exit $?"
exit 0
