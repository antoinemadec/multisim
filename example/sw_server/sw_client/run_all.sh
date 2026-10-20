#!/usr/bin/env bash
# run the sw_server/sw_client examples (about 1 min): read_write, then the unit tests

cd "$(dirname "$(readlink -f "$0")")" || exit 1
fail=0

printf "%-24s " read_write
# own session: the run script kills its process group on failure
if (cd read_write && timeout 300 setsid ./run > run.log 2>&1 < /dev/null); then
  echo PASS
else
  echo "FAIL (read_write/run.log)"
  fail=1
fi

# unit/run_all.sh prints "TEST PASS|FAIL..." lines, then "N failed"
unit/run_all.sh | sed '$d; s|^|unit/|'
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1

exit $fail
