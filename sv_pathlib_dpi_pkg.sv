/* verilator lint_off IMPLICITSTATIC */
package sv_pathlib_dpi_pkg;
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

  class Path;
    // Path parsing
    static function string name(string path);
      int last_slash = -1;
      for (int i = path.len() - 1; i >= 0; i--) begin
        if (path[i] == "/") begin
          last_slash = i;
          break;
        end
      end
      return path.substr(last_slash + 1, path.len() - 1);
    endfunction

    static function string stem(string path);
      string filename = name(path);
      int last_dot = -1;
      for (int i = filename.len() - 1; i >= 0; i--) begin
        if (filename[i] == ".") begin
          last_dot = i;
          break;
        end
      end
      if (last_dot <= 0) return filename;
      return filename.substr(0, last_dot - 1);
    endfunction

    static function string extension(string path);
      string filename = name(path);
      int last_dot = -1;
      for (int i = filename.len() - 1; i >= 0; i--) begin
        if (filename[i] == ".") begin
          last_dot = i;
          break;
        end
      end
      if (last_dot < 0) return "";
      return filename.substr(last_dot, filename.len() - 1);
    endfunction

    static function string parent(string path);
      int last_slash = -1;
      for (int i = path.len() - 1; i >= 0; i--) begin
        if (path[i] == "/") begin
          last_slash = i;
          break;
        end
      end
      if (last_slash < 0) return "";
      if (last_slash == 0) return "/";
      return path.substr(0, last_slash - 1);
    endfunction

    static function string join_path(string base, string other);
      if (other.len() > 0 && other[0] == "/") return other;
      if (base.len() == 0) return other;
      if (base[base.len() - 1] == "/") return {base, other};
      return {base, "/", other};
    endfunction

    static function string with_name(string path, string new_name);
      string parent_dir = parent(path);
      if (parent_dir == "") return new_name;
      if (parent_dir == "/") return {"/", new_name};
      return {parent_dir, "/", new_name};
    endfunction

    static function string with_suffix(string path, string new_suffix);
      string filename = name(path);
      string parent_dir = parent(path);
      string new_filename;
      int last_dot = -1;

      for (int i = filename.len() - 1; i >= 0; i--) begin
        if (filename[i] == ".") begin
          last_dot = i;
          break;
        end
      end

      if (last_dot > 0)
        new_filename = {filename.substr(0, last_dot - 1), new_suffix};
      else
        new_filename = {filename, new_suffix};

      if (parent_dir == "") return new_filename;
      if (parent_dir == "/") return {"/", new_filename};
      return {parent_dir, "/", new_filename};
    endfunction

    static function bit is_absolute(string path);
      return (path.len() > 0 && path[0] == "/");
    endfunction

    // File checks (DPI backend)
    static function bit exists(string path);
      return sv_pathlib_exists(path) != 0;
    endfunction

    static function bit is_file(string path);
      return sv_pathlib_is_file(path) != 0;
    endfunction

    static function bit is_dir(string path);
      return sv_pathlib_is_dir(path) != 0;
    endfunction

    static function bit is_symlink(string path);
      return sv_pathlib_is_symlink(path) != 0;
    endfunction

    static function bit is_empty(string path);
      return sv_pathlib_is_empty(path) != 0;
    endfunction

    // Directory operations
    static function int mkdir(string path);
      return sv_pathlib_mkdir(path);
    endfunction

    static function int rmdir(string path);
      return sv_pathlib_rmdir(path);
    endfunction

    // File I/O
    static function void copy(string src, string dst);
      sv_pathlib_copy(src, dst);
    endfunction

    static function void rename(string old_path, string new_path);
      sv_pathlib_rename(old_path, new_path);
    endfunction

    static function void unlink(string path);
      sv_pathlib_unlink(path);
    endfunction

    // File info
    static function longint size(string path);
      return sv_pathlib_size(path);
    endfunction

    static function longint modified(string path);
      return sv_pathlib_modified(path);
    endfunction

    // DPI-specific
    static function int symlink(string target, string linkpath);
      return sv_pathlib_symlink(target, linkpath);
    endfunction
  endclass
endpackage
