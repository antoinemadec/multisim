<div align="center">

<img alt="Multisim" height="280" src="./.assets/multisim_light.png" />

simulate your RTL with real multi-threaded speed  
interface different simulators, chiplets and platforms together
</div>

# ✨ Rationale

`multisim` is a systemverilog/DPI library allowing multiple simulations/platforms to run in parallel and communicate to simulate your DUT.

Typically, you can have:
* 1 **server simulation** with your DUT skeleton (NOC, fabric, etc)
* N **client simulations** with 1 big instance each (computing core, chip, etc)

## example: normal vs multisim simulation
Assuming your original simulation has N CPUs that take a lot of simulation time.

You could transform this DUT:  
![normal simulation](./.assets/multisim_normal.drawio.png)

Into this one, running on N+1 simulation instances:  
![multi simulations](./.assets/multisim_multi.drawio.png)

# 🚄 Performance
Reusing [this example](./example/sim_server/sim_client/core/multi/src) where we have:
* 1 **server simulation** with 1 NOC
* `CPU number` **client simulations** with 1 `cpu` (slow module) each

![sim speed](./example/sim_server/sim_client/core/sim_speed.png)

# 📚 Usage

## examples
Tested platform combinations:

| client \ server | sim                                             | emu                                             | sw                                            |
| -               | -                                               | -                                               | -                                             |
| sim             | ✅ [examples](./example/sim_server/sim_client/) | ✅ [examples](./example/emu_server/sim_client/) | untested                                      |
| emu             | untested                                        | untested                                        | untested                                      |
| sw              | ✅ [examples](./example/sim_server/sw_client/)  | ✅ [examples](./example/emu_server/sw_client/)  | ✅ [examples](./example/sw_server/sw_client/) |

## regression
```bash
./test/run_regression.sh            # all the tools: sw,verilator,vcs,zebu
./test/run_regression.sh -t sw,vcs  # some of them
./test/run_regression.sh -z         # also build the ZeBu database if needed (about 1 hour)
./test/run_regression.sh -a         # also run the full example suites (example/*/run_all.sh, long)
```
Short versions of the tests, a summary at the end (PASS/FAIL/SKIP per tool and test), exit code 1
if a test fails. Tools that are not installed are skipped. Logs and the summary (`summary.txt`) are
in `output_regression/`.
* `sw` (g++ only, about 1 min): [test/sw](./test/sw/) regression tests of the client/server
  library (`test/sw/run_all.sh` runs them alone), and the sw_server example
* `verilator`: sim_server examples, 2 CPUs for the multi ones
* `vcs`: sim_server/sw_client/read_write and sim_server/sim_client/axi_4state/multi (2 CPUs)
* `zebu`: emu_server/sw_client/read_write, reusing its database when it is newer than the sources,
  skipped otherwise (`-z` builds it)

## available modules
* core library (ready/valid protocol)
    * `client->server`: [multisim_client_push](./src/core/multisim_client_push.sv) and [multisim_server_pull](./src/core/multisim_server_pull.sv)
    * `server->client`: [multisim_server_push](./src/core/multisim_server_push.sv) and [multisim_client_pull](./src/core/multisim_client_pull.sv)
* other protocols:
  * [axi](./src/axi/)
  * [apb](./src/apb/)
  * [quasi static signals](./src/quasi_static/) (useful for signals without control signals like IRQ)

## available platforms
* SIMULATION
    * tested with **Verilator 5.040** (`./run` in [sim_server examples](./example/sim_server/))
    * tested with **QuestaSim 2024.3** (`./run_questa` in the [sim_server examples](./example/sim_server/))
    * tested with **VCS X-2025.06** (`./run_vcs` in [sim_server examples](./example/sim_server/))
* EMULATION
    * define `MULTISIM_EMULATION` in SV and C/C++ compilation
    * tested with **Veloce v23.0.1** (`./compile` in [emu_server examples](./example/emu_server/))
    * ZeBu: define `MULTISIM_ZEBU` instead, see [ZeBu](#zebu)
        * tested with **ZeBu W-2025.06-4** (`./compile -e zebu` in [emu_server examples](./example/emu_server/))
* SW
    * define `MULTISIM_SW` in C/C++ compilation
    * [client API](src/core/multisim_client.h) / [server API](src/core/multisim_server.h)
    * tested with **GCC 15.2.1**

Look at those files to have more info about those platforms:
* [multisim_common.h](src/core/multisim_common.h)
* [multisim_common.svh](src/core/multisim_common.svh)

## channels
* **server simulation** and **client simulations** communicate through channels
* channels direction can be `client->server` or `server->client`
* each **simulation** can use multiple channels
* `multisim` modules need a unique `server_name` to link a client/server channel together
* client modules need to set `server_runtime_directory` to know the port/ip address of each channel

## ZeBu
```bash
# optional site settings
export MULTISIM_ZEBU_SETTINGS=site.utf  # UTF sourced by the zCui project (grid_cmd, clock_config...)
export MULTISIM_ZEBU_LAUNCHER="srun --emu-work-dir ./zcui.work/zebu.work"  # zRci prefix, books an emulator

cd example/emu_server/sw_client/core
./compile -e zebu
./output/run
# or all the examples
cd example/emu_server && ./run_all.sh -e zebu
```
* define `MULTISIM_ZEBU` instead of `MULTISIM_EMULATION` in SV and C/C++ compilation
* `server_name` must be a string literal of at most 512 characters
* the server modules are ZEMI3 transactors, see [example/emu_server/zebu](./example/emu_server/zebu/)
  for the zCui project and the zRci script

## 4-state support
By default, `multisim` uses 2-state logic (0 and 1).

However 4-state logic (0, 1, X and Z) can be used by using the parameter `DATA_IS_4STATE`.  
See the [axi_4state example](./example/sim_server/sim_client/axi_4state/multi)

4-state logic:
* is currently not supported in EMULATION
* doubles the amount of bytes exchanges over TCP/IP sockets

## compilation
1. source [env.sh](./env.sh)
2. pass the right files to your simulator:
* server simulation, see [example](./example/sim_server/sim_client/core/multi/run_cpu)
* client simulation, see [example](./example/sim_server/sim_client/core/multi/run_top)

### shared objects
If your platform requires a shared object (.so file), it can be compiled like so:
```bash
# SW client example
g++ -o multisim_sw_client.so -g -shared -fPIC \
  -DMULTISIM_SW                               \
  $MULTISIM_SRC/core/multisim_client.cpp      \
  $MULTISIM_SRC/core/socket_server/client.cpp
```

Look in the [example](./example) directory for more examples.

## end of simulation
You can either:
* use the helper function `$MULTISIM_SRC/bin/kill_all_clients` to kill clients running in the backgroud
* use an "exit" channel to send exit instructions to the clients/servers you want to kill
* write a custom kill script

Find more info about PIDs/IPs of your clients in the server runtime directory in `.multisim/client*.txt`

# ⚖️ Pros and Cons
Pros:
* speed: split your big DUT in as many smaller parts as you want
* interoperability: can use different simulators/platforms combinations (Verilator, VCS, Questa, Xcelium, Veloce, Palladium, Zebu, Qemu etc)
* scalability: as long as you have enough CPUs on your server

Cons:
* ⚠️ **no cycle accuracy** ⚠️: transactionally accurate, but not cycle accurate
* harder debug: waveforms split on N+1 simulation, no time coherency in between them

# 🚀 Future
* simple transaction logging to help debug
