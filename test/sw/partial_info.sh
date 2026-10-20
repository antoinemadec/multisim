#!/usr/bin/env bash
# the client reads a server info file the server is still writing (no port yet):
# it waits for the complete file instead of connecting to a garbage port
source "$(dirname "$0")/lib.sh"
build_server srv "$TEST_DIR/echo.cpp"
build_client cli "$TEST_DIR/echo.cpp"
mkdir .multisim
printf "ip: 127.0.0.1\n" > .multisim/server_ch.txt
./cli ch > cli.log 2>&1 &
cli=$!
sleep 1
./srv ch > srv.log 2>&1 &
timeout 10 tail --pid=$cli -f /dev/null || fail "client not connected 10 s after the server start"
wait $cli || fail "client exit $?"
! grep "failed to connect" cli.log || fail "client used the incomplete info file"
exit 0
