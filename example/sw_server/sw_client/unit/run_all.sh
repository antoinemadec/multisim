#!/usr/bin/env bash
# run the SW tests (C++ client and server, g++ only): run_all.sh [TEST...]
# MULTISIM_SRC selects the sources under test (default: this repository)

cd "$(dirname "$0")" || exit 1
tests=("$@")
[ ${#tests[@]} -eq 0 ] && tests=(*.sh)
failed=0
for t in "${tests[@]}"; do
  t=${t%.sh}
  [ "$t" = lib ] || [ "$t" = run_all ] && continue
  printf "%-19s " "$t"
  if out=$(bash "$t.sh" 2>&1); then
    echo PASS
  else
    grep -m1 "^FAIL: " <<< "$out" || echo "FAIL: $(tail -1 <<< "$out")"
    failed=$((failed + 1))
  fi
done
echo "$failed failed"
[ $failed -eq 0 ]
