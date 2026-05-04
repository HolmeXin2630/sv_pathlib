/* verilator lint_off IMPLICITSTATIC */
package sv_pathlib_sys_pkg;
  import "DPI-C" function int c_system(input string cmd);
  import "DPI-C" function void c_write_text(input string path, input string content);
  import "DPI-C" function void c_unlink(input string path);
  import "DPI-C" function longint c_file_size(input string path);
  import "DPI-C" function longint c_file_mtime(input string path);

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

    // File checks ($system backend)
    static function bit exists(string path);
      return c_system($sformatf("test -e %s", path)) == 0;
    endfunction

    static function bit is_file(string path);
      return c_system($sformatf("test -f %s", path)) == 0;
    endfunction

    static function bit is_dir(string path);
      return c_system($sformatf("test -d %s", path)) == 0;
    endfunction

    static function bit is_symlink(string path);
      return c_system($sformatf("test -L %s", path)) == 0;
    endfunction

    static function bit is_empty(string path);
      if (!is_file(path)) return 0;
      return c_system($sformatf("test -s %s", path)) != 0;
    endfunction

    // Directory operations
    static function int mkdir(string path);
      int rc = c_system($sformatf("mkdir -p %s", path));
      if (rc != 0) $warning("sv_pathlib: mkdir failed: %s", path);
      return rc;
    endfunction

    static function int rmdir(string path);
      int rc = c_system($sformatf("rmdir %s", path));
      if (rc != 0) $warning("sv_pathlib: rmdir failed: %s", path);
      return rc;
    endfunction

    // File I/O
    static function string read_text(string path);
      int fh;
      string content = "";
      string line;
      int fgets_result;

      if (!exists(path)) begin
        $warning("sv_pathlib: file not found: %s", path);
        return "";
      end

      fh = $fopen(path, "r");
      if (fh == 0) begin
        $warning("sv_pathlib: cannot open file: %s", path);
        return "";
      end

      while (!$feof(fh)) begin
        fgets_result = $fgets(line, fh);
        if (fgets_result != 0) begin
          content = {content, line};
        end
      end

      $fclose(fh);
      return content;
    endfunction

    static function void write_text(string path, string content);
      int fh = $fopen(path, "w");
      if (fh == 0) begin
        $warning("sv_pathlib: cannot open file for writing: %s", path);
        return;
      end
      $fwrite(fh, "%s", content);
      $fclose(fh);
    endfunction

    static function void copy(string src, string dst);
      int rc;
      if (!exists(src)) begin
        $warning("sv_pathlib: source file not found: %s", src);
        return;
      end
      rc = c_system($sformatf("cp %s %s", src, dst));
      if (rc != 0) $warning("sv_pathlib: copy failed: %s -> %s", src, dst);
    endfunction

    static function void rename(string old_path, string new_path);
      int rc = c_system($sformatf("mv %s %s", old_path, new_path));
      if (rc != 0) $warning("sv_pathlib: rename failed: %s -> %s", old_path, new_path);
    endfunction

    static function void unlink(string path);
      if (exists(path)) begin
        c_unlink(path);
      end
    endfunction

    // File info
    static function longint size(string path);
      if (!exists(path)) return -1;
      return c_file_size(path);
    endfunction

    static function longint modified(string path);
      if (!exists(path)) return -1;
      return c_file_mtime(path);
    endfunction
  endclass
endpackage
