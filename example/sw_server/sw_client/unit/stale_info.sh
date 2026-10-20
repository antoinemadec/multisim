#!/usr/bin/env bash
# the server info file is a stale one: the client retries without leaking sockets,
# and connects once the real server has started
source "$(dirname "$0")/lib.sh"
build_server srv "$TEST_DIR/echo.cpp"
build_client cli "$TEST_DIR/echo.cpp"
mkdir .multisim
printf "ip: 127.0.0.1\nport: 1\n" > .multisim/server_ch.txt
./cli ch > cli.log 2>&1 &
cli=$!
sleep 3
fds=$(ls /proc/$cli/fd | wc -l)
[ "$fds" -lt 10 ] || fail "client has $fds open files after 3 s of retries"
./srv ch > srv.log 2>&1 &
for _ in $(seq 100); do
  kill -0 $cli 2> /dev/null || break
  sleep 0.1
done
kill -0 $cli 2> /dev/null && fail "client not connected 10 s after the server start"
wait $cli || fail "client exit $?"
exit 0
