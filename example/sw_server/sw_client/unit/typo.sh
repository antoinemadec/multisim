#!/usr/bin/env bash
# a pull from a server name that was never started stops with an error
source "$(dirname "$0")/lib.sh"
build_server srv "$TEST_DIR/echo.cpp"
build_client cli "$TEST_DIR/typo.cpp"
./srv a > srv.log 2>&1 &
timeout 30 ./cli > cli.log 2>&1 && fail "the pull from [b] was accepted"
grep -q "\[b\] was not started" cli.log || fail "no error message: $(tail -1 cli.log)"
exit 0
