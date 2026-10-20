#!/usr/bin/env bash
# the server keeps pushing after its client exited: it must not die of SIGPIPE
source "$(dirname "$0")/lib.sh"
build_server srv "$TEST_DIR/sigpipe.cpp"
build_client cli "$TEST_DIR/sigpipe.cpp"
./srv > srv.log 2>&1 &
srv=$!
timeout 30 ./cli > cli.log 2>&1 || fail "client exit $?"
wait $srv
rc=$?
[ $rc -eq 0 ] || fail "server exit $rc"
exit 0
