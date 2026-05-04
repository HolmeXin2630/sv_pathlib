package sv_pathlib_vcs_pkg;

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

    // Private helper: read a single integer from a temp file (used by size/modified)
    // NOTE: uses GNU stat syntax (stat --format), Linux only
    static function longint _read_temp_longint(string tmpfile);
      int fh;
      int fgets_result;
      string line;
      int tmp_val;
      longint result;
      fh = $fopen(tmpfile, "r");
      if (fh == 0) return -1;
      fgets_result = $fgets(line, fh);
      $fclose(fh);
      if (fgets_result == 0) return -1;
      while (line.len() > 0 && line[line.len()-1] == "\n")
        line = line.substr(0, line.len()-2);
      while (line.len() > 0 && (line[line.len()-1] == "\r" || line[line.len()-1] == " "))
        line = line.substr(0, line.len()-2);
      if (line.len() == 0) return -1;
      void'($sscanf(line, "%d", tmp_val));
      result = tmp_val;
      return result;
    endfunction

    // File checks
    static function bit exists(string path);
      return $system($sformatf("test -e %s", path)) == 0;
    endfunction

    static function bit is_file(string path);
      return $system($sformatf("test -f %s", path)) == 0;
    endfunction

    static function bit is_dir(string path);
      return $system($sformatf("test -d %s", path)) == 0;
    endfunction

    static function bit is_symlink(string path);
      return $system($sformatf("test -L %s", path)) == 0;
    endfunction

    static function bit is_empty(string path);
      if (!is_file(path)) return 0;
      return $system($sformatf("test -s %s", path)) != 0;
    endfunction

    // Directory operations
    static function int mkdir(string path);
      int rc = $system($sformatf("mkdir -p %s", path));
      if (rc != 0) $warning("sv_pathlib: mkdir failed: %s", path);
      return rc;
    endfunction

    static function int rmdir(string path);
      int rc = $system($sformatf("rmdir %s", path));
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
      rc = $system($sformatf("cp %s %s", src, dst));
      if (rc != 0) $warning("sv_pathlib: copy failed: %s -> %s", src, dst);
    endfunction

    static function void rename(string old_path, string new_path);
      int rc = $system($sformatf("mv %s %s", old_path, new_path));
      if (rc != 0) $warning("sv_pathlib: rename failed: %s -> %s", old_path, new_path);
    endfunction

    static function void unlink(string path);
      if (exists(path)) begin
        void'($system($sformatf("rm -f %s", path)));
      end
    endfunction

    // File info (via stat redirect to temp file)
    static function longint size(string path);
      string tmpfile = "/tmp/.sv_pathlib_stat_tmp";
      longint result;
      int rc;
      if (!exists(path)) return -1;
      rc = $system($sformatf("stat --format=%%s %s > %s 2>/dev/null", path, tmpfile));
      if (rc != 0) begin
        void'($system($sformatf("rm -f %s", tmpfile)));
        return -1;
      end
      result = _read_temp_longint(tmpfile);
      void'($system($sformatf("rm -f %s", tmpfile)));
      return result;
    endfunction

    static function longint modified(string path);
      string tmpfile = "/tmp/.sv_pathlib_mtime_tmp";
      longint result;
      int rc;
      if (!exists(path)) return -1;
      rc = $system($sformatf("stat --format=%%Y %s > %s 2>/dev/null", path, tmpfile));
      if (rc != 0) begin
        void'($system($sformatf("rm -f %s", tmpfile)));
        return -1;
      end
      result = _read_temp_longint(tmpfile);
      void'($system($sformatf("rm -f %s", tmpfile)));
      return result;
    endfunction
  endclass
endpackage
