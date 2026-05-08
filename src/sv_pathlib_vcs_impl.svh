typedef struct {
  longint st_size;
  longint st_mtime;
  longint st_atime;
  longint st_ctime;
  int     st_mode;
} stat_t;

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

  static function string resolve(string path);
    string result = "";
    int i, start;
    bit is_abs;
    is_abs = is_absolute(path);
    string components[$];
    components = {};
    start = is_abs ? 1 : 0;
    for (i = start; i < path.len(); i++) begin
      if (path[i] == "/") begin
        if (i > start) components.push_back(path.substr(start, i - 1));
        start = i + 1;
      end
    end
    if (start < path.len()) components.push_back(path.substr(start, path.len() - 1));
    string resolved[$];
    resolved = {};
    foreach (components[i]) begin
      if (components[i] == "..") begin
        if (resolved.size() > 0) resolved.pop_back();
      end else if (components[i] != ".") begin
        resolved.push_back(components[i]);
      end
    end
    if (is_abs) result = "/";
    foreach (resolved[i]) begin
      if (i > 0 || result != "") result = {result, "/"};
      result = {result, resolved[i]};
    end
    if (result == "" && !is_abs) result = ".";
    return result;
  endfunction

  // Private helper: read a single integer from a temp file (used by size/modified)
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

  static function int symlink(string target, string linkpath);
    int rc = $system($sformatf("ln -s %s %s", target, linkpath));
    if (rc != 0) $warning("sv_pathlib: symlink failed: %s -> %s", target, linkpath);
    return rc;
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

  // stat - full stat info via stat command + temp file
  static function stat_t stat(string path);
    stat_t s;
    string tmpfile = "/tmp/.sv_pathlib_stat_full_tmp";
    int rc;
    string line;
    int fh;
    s.st_size = -1; s.st_mtime = 0; s.st_atime = 0; s.st_ctime = 0; s.st_mode = 0;
    if (!exists(path)) return s;
    s.st_size = size(path);
    s.st_mtime = modified(path);
    rc = $system($sformatf("stat --format=%%a %%X %%Y %%Z %s > %s 2>/dev/null", path, tmpfile));
    if (rc == 0) begin
      fh = $fopen(tmpfile, "r");
      if (fh != 0) begin
        void'($fgets(line, fh));
        $fclose(fh);
        void'($sscanf(line, "%d %d %d %d", s.st_mode, s.st_atime, s.st_mtime, s.st_ctime));
      end
    end
    void'($system($sformatf("rm -f %s", tmpfile)));
    return s;
  endfunction

  // iterdir - list directory entries via ls -1 + temp file
  static function queue<string> iterdir(string path);
    queue<string> entries = {};
    string tmpfile = "/tmp/.sv_pathlib_iterdir_tmp";
    int rc;
    string line;
    int fh;
    if (!is_dir(path)) begin
      $warning("sv_pathlib: iterdir: not a directory: %s", path);
      return entries;
    end
    rc = $system($sformatf("ls -1 %s > %s 2>/dev/null", path, tmpfile));
    if (rc != 0) return entries;
    fh = $fopen(tmpfile, "r");
    if (fh == 0) return entries;
    while (!$feof(fh)) begin
      if ($fgets(line, fh)) begin
        while (line.len() > 0 && line[line.len()-1] == "\n")
          line = line.substr(0, line.len()-2);
        while (line.len() > 0 && line[line.len()-1] == "\r")
          line = line.substr(0, line.len()-2);
        if (line.len() > 0) entries.push_back(line);
      end
    end
    $fclose(fh);
    void'($system($sformatf("rm -f %s", tmpfile)));
    return entries;
  endfunction

  // glob - stub requiring DPI mode
  static function queue<string> glob(string path, string pattern);
    $error("sv_pathlib: glob() requires DPI mode (+define+SV_PATHLIB_USE_DPI)");
    return {};
  endfunction

  // rglob - stub requiring DPI mode
  static function queue<string> rglob(string path, string pattern);
    $error("sv_pathlib: rglob() requires DPI mode (+define+SV_PATHLIB_USE_DPI)");
    return {};
  endfunction

  // cwd - get current working directory via pwd + temp file
  static function string cwd();
    string tmpfile = "/tmp/.sv_pathlib_cwd_tmp";
    string result = "";
    int fh;
    void'($system($sformatf("pwd > %s 2>/dev/null", tmpfile)));
    fh = $fopen(tmpfile, "r");
    if (fh != 0) begin
      void'($fgets(result, fh));
      $fclose(fh);
      while (result.len() > 0 && result[result.len()-1] == "\n")
        result = result.substr(0, result.len()-2);
      while (result.len() > 0 && result[result.len()-1] == "\r")
        result = result.substr(0, result.len()-2);
    end
    void'($system($sformatf("rm -f %s", tmpfile)));
    return result;
  endfunction
endclass
