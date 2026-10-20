#!/usr/bin/env bash
# the info directory cannot be written: the server and the client stop with an error, no crash
source "$(dirname "$0")/lib.sh"
build_server srv "$TEST_DIR/echo.cpp"
build_client cli "$TEST_DIR/echo.cpp"
mkdir .multisim
chmod a-w .multisim
timeout 10 ./srv ch > srv.log 2>&1
rc=$?
[ $rc -eq 1 ] && grep -q "Permission denied" srv.log || fail "server exit $rc, $(tail -1 srv.log)"

chmod u+w .multisim
./srv ch > srv.log 2>&1 &
wait_file .multisim/server_ch.txt
sleep 0.1 # the server writes the file after creating it
chmod a-w .multisim
timeout 10 ./cli ch > cli.log 2>&1
rc=$?
chmod u+w .multisim
[ $rc -eq 1 ] && grep -q "Permission denied" cli.log || fail "client exit $rc, $(tail -1 cli.log)"
exit 0
