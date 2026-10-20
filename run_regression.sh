#!/usr/bin/env bash
# quick regression on all the available tools, see README.md "regression"

usage() {
  cat << EOF
usage: $(basename "$0") [-h] [-t TOOLS] [-a] [-z]

run short versions of the tests and examples, then print a summary:
  sw         example/sw_server/sw_client/run_all.sh: read_write and the unit tests
  verilator  sim_server examples, 2 CPUs for the multi ones
  vcs        sim_server/sw_client/read_write and axi_4state/multi (2 CPUs)
  zebu       emu_server/sw_client/read_write, reusing its database if up to date

  -h        display this help
  -t TOOLS  comma-separated list among sw,verilator,vcs,zebu (default: all of them)
  -a        also run the long example suites: example/sim_server/run_all.sh with verilator,
            example/emu_server/run_all.sh -e zebu with zebu (builds the 3 ZeBu databases,
            about 1 hour)
  -z        ZeBu: build the database of emu_server/sw_client/read_write if it does not
            exist (about 1 hour), otherwise ZeBu reuses it or is skipped

the tools that are not installed are skipped, the logs and the summary
(summary.txt) are in output_regression/
exit code: 1 if a test fails, 0 otherwise
EOF
}

tools=sw,verilator,vcs,zebu
all=0
zebu_build=0
while getopts "ht:az" opt; do
  case $opt in
    t) tools=$OPTARG ;;
    a) all=1 ;;
    z) zebu_build=1 ;;
    h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

root=$(dirname "$(readlink -f "$0")")
source "$root/env.sh" # MULTISIM_SRC of this repository
logs=$root/output_regression
rm -rf "$logs"
mkdir -p "$logs"
summary=()
failed=0

# record TOOL TEST RESULT [DETAIL]
record() {
  summary+=("$(printf "%-10s %-48s %s" "$1" "$2" "$3${4:+ ($4)}")")
  [ "$3" = FAIL ] && failed=1
  echo "${summary[-1]}"
}

# run TOOL TIMEOUT SCRIPT [ARGS...]: run an example script in its directory, in its own
# session (the scripts kill their process group on exit)
run() {
  local tool=$1 timeout=$2 script=$3
  shift 3
  local name=${script#"$root"/example/}
  local log=$logs/$tool.${name//\//.}.log
  if (cd "$(dirname "$script")" && timeout "$timeout" setsid "./$(basename "$script")" "$@") \
    > "$log" 2>&1 < /dev/null; then
    record "$tool" "$name" PASS
  else
    record "$tool" "$name" FAIL "$log"
  fi
}

# has TOOL COMMAND: COMMAND is installed, otherwise TOOL is skipped
has() {
  command -v "$2" > /dev/null && return 0
  record "$1" "-" SKIP "$2 not found"
  return 1
}

ex=$root/example
for tool in ${tools//,/ }; do
  case $tool in
    sw)
      # one summary line per "TEST PASS|FAIL..." line of the sw_client run_all.sh
      log=$logs/sw.sw_server.sw_client.run_all.sh.log
      (cd "$ex/sw_server/sw_client" && timeout 900 ./run_all.sh) > "$log" 2>&1 < /dev/null
      rc=$?
      while read -r name result detail; do
        record sw "sw_server/sw_client/$name" "${result%:}" "$detail"
      done < <(grep -E '^[^ ]+ +(PASS|FAIL)' "$log")
      if ((rc)) && ! grep -qE '^[^ ]+ +FAIL' "$log"; then
        record sw "sw_server/sw_client/run_all.sh" FAIL "$log"
      fi
      ;;
    verilator)
      has verilator verilator || continue
      run verilator 900 "$ex/sim_server/sw_client/read_write/run"
      for e in apb axi core quasi_static; do
        run verilator 900 "$ex/sim_server/sim_client/$e/multi/run" 2
      done
      run verilator 900 "$ex/sim_server/sim_client/axi_server_push/run"
      ((all)) && run verilator 3600 "$ex/sim_server/run_all.sh"
      ;;
    vcs)
      has vcs vcs || continue
      run vcs 900 "$ex/sim_server/sw_client/read_write/run_vcs"
      run vcs 900 "$ex/sim_server/sim_client/axi_4state/multi/run_vcs" 2
      ;;
    zebu)
      has zebu zRci || continue
      if ((all)); then
        run zebu 14400 "$ex/emu_server/run_all.sh" -e zebu
        continue
      fi
      e=$ex/emu_server/sw_client/read_write
      db=$e/output
      # the database is stale if a source is newer than its libdpi.so (built last)
      if [ ! -d "$db/zcui.work" ] || [ ! -f "$db/libdpi.so" ] ||
        [ -n "$(find "$MULTISIM_SRC/core" "$e/src" "$ex/emu_server/zebu" -newer "$db/libdpi.so")" ]; then
        if ((!zebu_build)); then
          record zebu "emu_server/sw_client/read_write" SKIP "no up-to-date database, -z builds it"
          continue
        fi
        run zebu 10800 "$e/compile" -e zebu
        [ -f "$db/libdpi.so" ] || continue
      fi
      run zebu 900 "$db/run"
      ;;
    *)
      record "$tool" "-" FAIL "unknown tool"
      ;;
  esac
done

echo
echo "#--------------------------------------------------------------"
echo "# summary"
echo "#--------------------------------------------------------------"
{
  printf "%s\n" "${summary[@]}"
  ((failed)) && echo "FAIL" || echo "PASS"
} | tee "$logs/summary.txt"
exit $failed
