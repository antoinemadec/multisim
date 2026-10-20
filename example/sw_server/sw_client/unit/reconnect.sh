#!/usr/bin/env bash
# clients connect and disconnect one after the other: the server closes their sockets
source "$(dirname "$0")/lib.sh"
build_server srv "$TEST_DIR/reconnect.cpp"
build_client cli "$TEST_DIR/reconnect.cpp"
./srv 100 > srv.log 2>&1 &
for _ in $(seq 100); do
  timeout 10 ./cli > /dev/null 2>&1 || fail "client exit $?"
done
timeout 10 tail --pid=$! -f /dev/null || fail "server did not get the 100 messages"
fds=$(sed -n 's/^fds: //p' srv.log)
[ "$fds" -lt 20 ] || fail "server has $fds open files after 100 clients"
exit 0
