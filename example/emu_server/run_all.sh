#!/usr/bin/env bash

set -e

# arguments are passed to the compile scripts, e.g. "-e zebu"
compile_args="$@"

SCRIPT_DIR=$(readlink -f $0)

run_script () (
  script="$1"
  log="$2"
  shift 2
  cd $(dirname $script)
  ./$(basename $script) "$@" &> $log
)

for compile_script in $(find -L -type f -name compile); do
  echo "Compiling $compile_script..."
  run_script $compile_script "compile.log" $compile_args &
done
wait
echo "compilations finished!"

global_fail=0

for test_script in $(find -L -type f -name run); do
  [[ $test_script =~ "/input/" ]] && continue
  fail=0
  echo -n "Testing $test_script..."
  run_script $test_script "run.log" || fail=1
  if [[ $fail == 1 ]]; then
    global_fail=1
    echo "FAIL"
  else
    echo "PASS"
  fi
done

exit $global_fail
