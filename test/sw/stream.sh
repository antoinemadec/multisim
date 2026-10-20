#!/usr/bin/env bash
# a slow client pulls wide messages: the sockets transfer them in pieces, no message is corrupted
source "$(dirname "$0")/lib.sh"
build_server srv "$TEST_DIR/stream.cpp"
build_client cli "$TEST_DIR/stream.cpp"
for w in 800 100000; do
  ./srv $w 2000 > srv.log 2>&1 &
  timeout 60 ./cli $w 2000 > cli.log 2>&1 || fail "width $w: $(grep -v Client cli.log | tail -1)"
  kill $!
  wait 2> /dev/null
  rm -rf .multisim
done
exit 0
