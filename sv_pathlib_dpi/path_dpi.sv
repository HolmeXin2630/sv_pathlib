/* verilator lint_off IMPLICITSTATIC */
package path_dpi;
  import "DPI-C" function int sv_pathlib_exists(input string path);
  import "DPI-C" function int sv_pathlib_is_file(input string path);
  import "DPI-C" function int sv_pathlib_is_dir(input string path);
  import "DPI-C" function int sv_pathlib_is_symlink(input string path);
  import "DPI-C" function int sv_pathlib_is_empty(input string path);
  import "DPI-C" function int sv_pathlib_mkdir(input string path);
  import "DPI-C" function int sv_pathlib_rmdir(input string path);
  import "DPI-C" function longint sv_pathlib_size(input string path);
  import "DPI-C" function longint sv_pathlib_modified(input string path);
  import "DPI-C" function void sv_pathlib_copy(input string src, input string dst);
  import "DPI-C" function void sv_pathlib_rename(input string old_path, input string new_path);
  import "DPI-C" function void sv_pathlib_unlink(input string path);
  import "DPI-C" function int sv_pathlib_symlink(input string target, input string linkpath);

  function bit exists(string path);
    return sv_pathlib_exists(path) != 0;
  endfunction

  function bit is_file(string path);
    return sv_pathlib_is_file(path) != 0;
  endfunction

  function bit is_dir(string path);
    return sv_pathlib_is_dir(path) != 0;
  endfunction

  function bit is_symlink(string path);
    return sv_pathlib_is_symlink(path) != 0;
  endfunction

  function bit is_empty(string path);
    return sv_pathlib_is_empty(path) != 0;
  endfunction

  function int mkdir(string path);
    return sv_pathlib_mkdir(path);
  endfunction

  function int rmdir(string path);
    return sv_pathlib_rmdir(path);
  endfunction

  function longint size(string path);
    return sv_pathlib_size(path);
  endfunction

  function longint modified(string path);
    return sv_pathlib_modified(path);
  endfunction

  function void copy(string src, string dst);
    sv_pathlib_copy(src, dst);
  endfunction

  function void rename(string old_path, string new_path);
    sv_pathlib_rename(old_path, new_path);
  endfunction

  function void unlink(string path);
    sv_pathlib_unlink(path);
  endfunction

  function int symlink(string target, string linkpath);
    return sv_pathlib_symlink(target, linkpath);
  endfunction
endpackage
