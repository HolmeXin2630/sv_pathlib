`include "sv_pathlib_define.svh"
package sv_pathlib_pkg;

`ifdef SV_PATHLIB_USE_DPI
  `include "sv_pathlib_dpi_impl.svh"
`else
  `include "sv_pathlib_vcs_impl.svh"
`endif

endpackage
