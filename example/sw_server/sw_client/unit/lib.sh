# sourced by the tests: build the SW client/server and run in a temporary directory
# MULTISIM_SRC selects the sources under test (default: this repository)

TEST_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
MULTISIM_SRC=${MULTISIM_SRC:-$(readlink -f "$TEST_DIR/../../../../src")}
CORE=$MULTISIM_SRC/core
CXX="${CXX:-g++} -g -DMULTISIM_SW -I$CORE"

WORK=$(mktemp -d)
cd "$WORK" || exit 1
trap '{ kill $(jobs -p); wait; } 2> /dev/null; rm -rf "$WORK"' EXIT

fail() {
  echo "FAIL: $*"
  exit 1
}

# build_server|build_client BINARY SOURCE: SOURCE is built with ROLE_SERVER or ROLE_CLIENT
build_server() {
  $CXX -DROLE_SERVER -o "$1" "$2" $CORE/multisim_server.cpp $CORE/socket_server/server.cpp ||
    fail "server build"
}
build_client() {
  $CXX -DROLE_CLIENT -o "$1" "$2" $CORE/multisim_client.cpp $CORE/socket_server/client.cpp ||
    fail "client build"
}

# wait_file FILE: wait up to 10 s for FILE
wait_file() {
  for _ in $(seq 100); do
    [ -f "$1" ] && return 0
    sleep 0.1
  done
  fail "no $1"
}
