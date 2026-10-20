#!/usr/bin/env bash
# a client on the host of the server connects to its Unix socket, published in the info file;
# it falls back to TCP when the Unix socket cannot be reached (other host)
source "$(dirname "$0")/lib.sh"
build_server srv "$TEST_DIR/echo.cpp"
build_client cli "$TEST_DIR/echo.cpp"

# Unix socket, also with a 512-character name (shortened socket file)
./srv ch 512 ch_tcp > srv.log 2>&1 &
wait_file .multisim/server_ch_tcp.txt
sock=$(sed -n 's/^unix: //p' .multisim/server_ch.txt)
[ -S "$sock" ] || fail "no Unix socket in the info file: $(tr '\n' ';' < .multisim/server_ch.txt)"
timeout 30 ./cli ch 512 > cli.log 2>&1 || fail "client exit $?"
grep -q "connect to server ch at $sock" cli.log || fail "client not on the Unix socket: $(grep connect cli.log)"
grep -q "connect to server a.* at .*\.sock" cli.log || fail "512-character name: $(grep 'connect to' cli.log | tail -1)"

# TCP fallback: the Unix socket of the info file does not exist
sed -i 's|^unix: .*|unix: /nonexistent/server_ch_tcp.sock|' .multisim/server_ch_tcp.txt
timeout 30 ./cli ch_tcp > cli_tcp.log 2>&1 || fail "TCP client exit $?"
grep -qE "connect to server ch_tcp at [0-9.]+:[0-9]+" cli_tcp.log || fail "no TCP fallback: $(grep connect cli_tcp.log)"
kill $!
wait $! 2> /dev/null

# runtime directory too long for a sun_path (108 bytes): the socket is reached through /proc
deep=$(printf 'a_long_directory_name_%.0s' 1 2 3 4 5 6)
mkdir -p "$deep" && cd "$deep" || fail "mkdir"
../srv ch > srv.log 2>&1 &
timeout 30 ../cli ch > cli.log 2>&1 || fail "long directory: client exit $?"
grep -q "connect to server ch at .*/server_ch.sock" cli.log || fail "long directory: $(grep connect cli.log)"
exit 0
