package sv_pathlib_pkg;
  `include "path.sv"
endpackage

// Users can choose backend:
// import sv_pathlib_pkg::*;  // Path class only
// import path_sys::*;        // $system backend
// import path_dpi::*;        // DPI backend
