proc args procname {
  # signature of a proc
  set res ""
  foreach a [info args $procname] {
    if [info default $procname $a default] {
      lappend a $default
    }
    lappend res $a
  }
  set res
}


proc docstring procname {
  # reports a proc's args and leading comments,
  # multiple documentation lines are allowed
  set res "{usage: [namespace tail $procname] [uplevel 1 [list args $procname]]\n}"

  foreach line [split [uplevel 1 [list info body $procname]] \n] {
    if {[string trim $line] eq ""} continue
    if {![regexp {\s*#(.+)} $line -> line]} break
    lappend res [string trim $line]
  }
  join $res \n
}


proc add_to_ax_procs {procname} {
  lappend ::ax_procs $procname
}


proc help_ax {{procname ""}} {
  # print help for procname, or list all procs
  if {$procname == ""} {
    puts [join $::ax_procs \n]
  } else {
    puts [docstring $procname]
  }
}
