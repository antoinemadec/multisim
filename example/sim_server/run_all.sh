#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(readlink -f $0)

run_test () (
    test_script="$1"
    cd $(dirname $test_script)
    ./$(basename $test_script) &> /dev/null
)

global_fail=0

for test_script in $(find -type f -name run); do
    fail=0
    echo -n "Testing $test_script..."
    run_test $test_script || fail=1
    if [[ $fail == 1 ]]; then
        global_fail=1
        echo "FAIL"
    else
        echo "PASS"
    fi
done

exit $global_fail


