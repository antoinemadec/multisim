#!/usr/bin/env bash
# kill_all_clients kills the live clients, even when the 1st client has already exited
source "$(dirname "$0")/lib.sh"
mkdir .multisim
sh -c 'exit 0' &
dead=$!
wait $dead
sleep 60 &
live=$!
printf "pid: %d\nserver_0: a\n" $dead > .multisim/client_a.txt
printf "pid: %d\nserver_0: b\n" $live > .multisim/client_b.txt
"$MULTISIM_SRC/bin/kill_all_clients" > kill.log 2>&1 || fail "exit $?, $(tail -1 kill.log)"
sleep 0.2
kill -0 $live 2> /dev/null && fail "the live client was not killed"
exit 0
