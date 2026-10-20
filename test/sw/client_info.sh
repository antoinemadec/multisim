#!/usr/bin/env bash
# a client of 2 servers writes all its info in one file, named after its 1st server
source "$(dirname "$0")/lib.sh"
build_server srv "$TEST_DIR/echo.cpp"
build_client cli "$TEST_DIR/echo.cpp"
./srv zeta alpha > srv.log 2>&1 &
timeout 30 ./cli zeta alpha > cli.log 2>&1 || fail "client exit $?"
files=$(cd .multisim && ls client_*)
[ "$files" = client_zeta.txt ] || fail "client info files: $(echo $files)"
grep -q "^pid: " .multisim/client_zeta.txt &&
  grep -q "^server_0: zeta " .multisim/client_zeta.txt &&
  grep -q "^server_1: alpha " .multisim/client_zeta.txt ||
  fail "client_zeta.txt: $(tr '\n' ';' < .multisim/client_zeta.txt)"
exit 0
