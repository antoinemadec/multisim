`ifndef MULTISIM_CLIENT_END_OF_SIMULATION
`define MULTISIM_CLIENT_END_OF_SIMULATION

  // make sure only 1 process handles eos to improve performance
class multisim_client_end_of_simulation;
  static int cnt = 0;
  int my_cnt;

  function new();
    my_cnt = cnt;
    cnt++;
  endfunction

  function bit handles_end_of_simulation();
    return my_cnt == 0;
  endfunction
endclass : multisim_client_end_of_simulation
`endif
