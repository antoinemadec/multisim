#!/usr/bin/env bash
# server names: duplicates are rejected, names of up to 512 characters work, longer ones are
# rejected with an error
source "$(dirname "$0")/lib.sh"
build_server srv "$TEST_DIR/echo.cpp"
build_client cli "$TEST_DIR/echo.cpp"

timeout 10 ./srv same same > dup.log 2>&1 && fail "duplicate server names accepted"
grep -q "already exist" dup.log || fail "duplicate server names: $(tail -1 dup.log)"

./srv 512 > srv.log 2>&1 &
timeout 30 ./cli 512 > cli.log 2>&1 || fail "512-character name: client exit $?"
kill $!

for exe in srv cli; do
  timeout 10 ./$exe 513 > $exe.log 2>&1
  rc=$?
  [ $rc -eq 1 ] && grep -q "has 513 characters, the limit is 512" $exe.log ||
    fail "513-character name: $exe exit $rc, $(tail -1 $exe.log)"
done
exit 0
