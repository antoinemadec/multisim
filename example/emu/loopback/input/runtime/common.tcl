source help.tcl

  # reg setvalue hdl_top/por_rst_ni 1
  # run
  # waitfor runcomplete

add_to_ax_procs "dump_waves_all"
proc dump_waves_all {name} {
  # continuously dump waveforms for all nets in the design
  # Warning: very slow
  hwtrace autoupload on -tracedir $name
}
