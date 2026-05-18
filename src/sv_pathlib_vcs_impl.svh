`include "sv_pathlib_common.svh"

  static function string relative_to(string path, string base);
    string rpath, rbase;
    string tmpfile;
    string result;
    int rc, fh;

    rpath = resolve(path);
    rbase = resolve(base);

    if (!is_absolute(rpath) || !is_absolute(rbase)) begin
      $warning("sv_pathlib: relative_to requires absolute paths");
      return "";
    end

    tmpfile = _tmpfile("rel");
    rc = $system($sformatf("realpath --relative-to='%s' '%s' > '%s' 2>/dev/null", rbase, rpath, tmpfile));
    if (rc != 0) begin
      void'($system($sformatf("rm -f '%s'", tmpfile)));
      $warning("sv_pathlib: relative_to failed: %s relative to %s", path, base);
      return "";
    end
    result = "";
    fh = $fopen(tmpfile, "r");
    if (fh != 0) begin
      void'($fgets(result, fh));
      $fclose(fh);
      while (result.len() > 0 && result[result.len()-1] == "\n")
        result = result.substr(0, result.len()-2);
      while (result.len() > 0 && result[result.len()-1] == "\r")
        result = result.substr(0, result.len()-2);
    end
    void'($system($sformatf("rm -f '%s'", tmpfile)));
    if (result.len() == 0) result = ".";
    return result;
  endfunction

  // Private helper: generate unique temp file name
  static function string _tmpfile(string prefix);
    int seed;
    seed = int'($random) ^ int'($time) * 37;
    return $sformatf("/tmp/.sv_pathlib_%s_%0d_%0d.tmp", prefix, $time, seed);
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
    result = longint'(tmp_val);
    return result;
  endfunction

  // File checks
  static function bit exists(string path);
    return $system($sformatf("test -e '%s'", path)) == 0;
  endfunction

  static function bit is_file(string path);
    return $system($sformatf("test -f '%s'", path)) == 0;
  endfunction

  static function bit is_dir(string path);
    return $system($sformatf("test -d '%s'", path)) == 0;
  endfunction

  static function bit is_symlink(string path);
    return $system($sformatf("test -L '%s'", path)) == 0;
  endfunction

  static function bit is_empty(string path);
    if (!is_file(path)) return 0;
    return $system($sformatf("test -s '%s'", path)) != 0;
  endfunction

  // Directory operations
  static function int mkdir(string path);
    int rc = $system($sformatf("mkdir -p '%s'", path));
    if (rc != 0) $warning("sv_pathlib: mkdir failed: %s", path);
    return rc;
  endfunction

  static function int rmdir(string path);
    int rc = $system($sformatf("rmdir '%s'", path));
    if (rc != 0) $warning("sv_pathlib: rmdir failed: %s", path);
    return rc;
  endfunction

  static function void copy(string src, string dst);
    int rc;
    if (!exists(src)) begin
      $warning("sv_pathlib: source file not found: %s", src);
      return;
    end
    rc = $system($sformatf("cp '%s' '%s'", src, dst));
    if (rc != 0) $warning("sv_pathlib: copy failed: %s -> %s", src, dst);
  endfunction

  static function void rename(string old_path, string new_path);
    int rc = $system($sformatf("mv '%s' '%s'", old_path, new_path));
    if (rc != 0) $warning("sv_pathlib: rename failed: %s -> %s", old_path, new_path);
  endfunction

  static function int symlink(string target, string linkpath);
    int rc = $system($sformatf("ln -s '%s' '%s'", target, linkpath));
    if (rc != 0) $warning("sv_pathlib: symlink failed: %s -> %s", target, linkpath);
    return rc;
  endfunction

  static function void unlink(string path);
    if (exists(path)) begin
      void'($system($sformatf("rm -f '%s'", path)));
    end
  endfunction

  // File info (via stat redirect to temp file)
  static function longint size(string path);
    string tmpfile;
    longint result;
    int rc;
    if (!exists(path)) return -1;
    tmpfile = _tmpfile("stat");
    rc = $system($sformatf("stat -c '%%s' '%s' > '%s' 2>/dev/null", path, tmpfile));
    if (rc != 0) begin
      void'($system($sformatf("rm -f '%s'", tmpfile)));
      return -1;
    end
    result = _read_temp_longint(tmpfile);
    void'($system($sformatf("rm -f '%s'", tmpfile)));
    return result;
  endfunction

  static function longint modified(string path);
    string tmpfile;
    longint result;
    int rc;
    if (!exists(path)) return -1;
    tmpfile = _tmpfile("mtime");
    rc = $system($sformatf("stat -c '%%Y' '%s' > '%s' 2>/dev/null", path, tmpfile));
    if (rc != 0) begin
      void'($system($sformatf("rm -f '%s'", tmpfile)));
      return -1;
    end
    result = _read_temp_longint(tmpfile);
    void'($system($sformatf("rm -f '%s'", tmpfile)));
    return result;
  endfunction

  // stat - full stat info via single stat command + temp file
  static function stat_t stat(string path);
    stat_t s;
    string tmpfile;
    int rc;
    string line;
    int fh;
    int tmp_size, tmp_mode, tmp_atime, tmp_mtime, tmp_ctime;
    s.st_size = -1; s.st_mtime = 0; s.st_atime = 0; s.st_ctime = 0; s.st_mode = 0;
    if (!exists(path)) return s;
    tmpfile = _tmpfile("stat");
    rc = $system($sformatf("stat -c '%%s %%a %%X %%Y %%Z' '%s' > '%s' 2>/dev/null", path, tmpfile));
    if (rc == 0) begin
      fh = $fopen(tmpfile, "r");
      if (fh != 0) begin
        void'($fgets(line, fh));
        $fclose(fh);
        void'($sscanf(line, "%d %d %d %d %d", tmp_size, tmp_mode, tmp_atime, tmp_mtime, tmp_ctime));
        s.st_size = longint'(tmp_size);
        s.st_mode = tmp_mode;
        s.st_atime = longint'(tmp_atime);
        s.st_mtime = longint'(tmp_mtime);
        s.st_ctime = longint'(tmp_ctime);
      end
    end
    void'($system($sformatf("rm -f '%s'", tmpfile)));
    return s;
  endfunction

  // iterdir - list directory entries via ls -1 + temp file
  // Returns newline-separated string; caller splits on \n
  static function string iterdir(string path);
    string result = "";
    string tmpfile;
    int rc;
    string line;
    int fh;
    if (!is_dir(path)) begin
      $warning("sv_pathlib: iterdir: not a directory: %s", path);
      return result;
    end
    tmpfile = _tmpfile("iterdir");
    rc = $system($sformatf("ls -1 '%s' > '%s' 2>/dev/null", path, tmpfile));
    if (rc != 0) return result;
    fh = $fopen(tmpfile, "r");
    if (fh == 0) return result;
    while (!$feof(fh)) begin
      if ($fgets(line, fh) != 0) begin
        while (line.len() > 0 && line[line.len()-1] == "\n")
          line = line.substr(0, line.len()-2);
        while (line.len() > 0 && line[line.len()-1] == "\r")
          line = line.substr(0, line.len()-2);
        if (line.len() > 0) begin
          if (result.len() > 0) result = {result, "\n"};
          result = {result, line};
        end
      end
    end
    $fclose(fh);
    void'($system($sformatf("rm -f '%s'", tmpfile)));
    return result;
  endfunction

  // glob - stub requiring DPI mode
  static function string glob(string path, string pattern);
    $warning("sv_pathlib: glob() requires DPI mode (+define+SV_PATHLIB_USE_DPI)");
    return "";
  endfunction

  // rglob - stub requiring DPI mode
  static function string rglob(string path, string pattern);
    $warning("sv_pathlib: rglob() requires DPI mode (+define+SV_PATHLIB_USE_DPI)");
    return "";
  endfunction

  // cwd - get current working directory via pwd + temp file
  static function string cwd();
    string tmpfile;
    string result = "";
    int fh;
    tmpfile = _tmpfile("cwd");
    void'($system($sformatf("pwd > '%s' 2>/dev/null", tmpfile)));
    fh = $fopen(tmpfile, "r");
    if (fh != 0) begin
      void'($fgets(result, fh));
      $fclose(fh);
      while (result.len() > 0 && result[result.len()-1] == "\n")
        result = result.substr(0, result.len()-2);
      while (result.len() > 0 && result[result.len()-1] == "\r")
        result = result.substr(0, result.len()-2);
    end
    void'($system($sformatf("rm -f '%s'", tmpfile)));
    return result;
  endfunction

  // Environment variable access
  static function string getenv(string name);
    string tmpfile;
    string result = "";
    int fh;
    tmpfile = _tmpfile("env");
    void'($system($sformatf("printenv '%s' > '%s' 2>/dev/null", name, tmpfile)));
    fh = $fopen(tmpfile, "r");
    if (fh != 0) begin
      void'($fgets(result, fh));
      $fclose(fh);
      while (result.len() > 0 && result[result.len()-1] == "\n")
        result = result.substr(0, result.len()-2);
      while (result.len() > 0 && result[result.len()-1] == "\r")
        result = result.substr(0, result.len()-2);
    end
    void'($system($sformatf("rm -f '%s'", tmpfile)));
    return result;
  endfunction
endclass
