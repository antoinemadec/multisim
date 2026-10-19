# zRci runtime script of the emu_server examples

# multisim server modules: ZEMI3 transactors, one library per transactor
zemi3 -lib ./libdpi.so
foreach lib [glob ./zcui.work/zebu.work/multisim_server_*.so] {
  zemi3 -lib $lib
}
zemi3 -enable

# $finish in top ends the run
set finished 0
proc on_finish {} {
  global finished
  set finished 1
  ccall -flush
}
dollar_finish -enable on_finish

start_zebu

ccall -load ./zcui.work/zebu.work/grp0_ccall.so
ccall -enable_synchronization
ccall -enable

while {!$finished} {
  run 100ms
}
exit
