// DPI-C import statements (outside class, before class)
import "DPI-C" function int    sv_pathlib_exists(input string path);
import "DPI-C" function int    sv_pathlib_is_file(input string path);
import "DPI-C" function int    sv_pathlib_is_dir(input string path);
import "DPI-C" function int    sv_pathlib_is_symlink(input string path);
import "DPI-C" function int    sv_pathlib_is_empty(input string path);
import "DPI-C" function int    sv_pathlib_mkdir(input string path);
import "DPI-C" function int    sv_pathlib_rmdir(input string path);
import "DPI-C" function longint sv_pathlib_size(input string path);
import "DPI-C" function longint sv_pathlib_modified(input string path);
import "DPI-C" function void   sv_pathlib_copy(input string src, input string dst);
import "DPI-C" function void   sv_pathlib_rename(input string old_path, input string new_path);
import "DPI-C" function void   sv_pathlib_unlink(input string path);
import "DPI-C" function int    sv_pathlib_symlink(input string target, input string linkpath);
import "DPI-C" function int    sv_pathlib_readdir(input string path, output string result);
import "DPI-C" function int    sv_pathlib_stat_full(input string path, output longint size, output longint mtime, output longint atime, output longint ctime, output int mode);
import "DPI-C" function string sv_pathlib_getenv(input string name);

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
    string component = "";
    int i;
    bit is_abs;
    bit in_component;
    is_abs = is_absolute(path);
    in_component = 0;
    result = is_abs ? "/" : "";
    for (i = is_abs ? 1 : 0; i < path.len(); i++) begin
      if (path[i] == "/") begin
        if (in_component) begin
          if (component == "..") begin
            if (result.len() > 1) begin
              int last_slash = -1;
              int j;
              for (j = result.len() - 2; j >= 0; j--) begin
                if (result[j] == "/") begin
                  last_slash = j;
                  break;
                end
              end
              if (last_slash > 0)
                result = result.substr(0, last_slash - 1);
              else if (last_slash == 0)
                result = "/";
              else
                result = "";
            end else if (result == "/") begin
            end
          end else if (component != ".") begin
            if (result == "/")
              result = {result, component};
            else if (result.len() == 0)
              result = component;
            else
              result = {result, "/", component};
          end
          component = "";
          in_component = 0;
        end
      end else begin
        component = {component, path[i]};
        in_component = 1;
      end
    end
    if (in_component) begin
      if (component == "..") begin
        if (result.len() > 1) begin
          int last_slash = -1;
          int j;
          for (j = result.len() - 2; j >= 0; j--) begin
            if (result[j] == "/") begin
              last_slash = j;
              break;
            end
          end
          if (last_slash > 0)
            result = result.substr(0, last_slash - 1);
          else if (last_slash == 0)
            result = "/";
          else
            result = "";
        end else if (result == "/") begin
        end else if (result.len() == 0) begin
          result = "..";
        end
      end else if (component != ".") begin
        if (result == "/")
          result = {result, component};
        else if (result.len() == 0)
          result = component;
        else
          result = {result, "/", component};
      end
    end
    if (result == "" && !is_abs) result = ".";
    return result;
  endfunction

  static function string absolute(string path);
    if (is_absolute(path)) return resolve(path);
    return resolve(join_path(cwd(), path));
  endfunction

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

    tmpfile = "/tmp/.sv_pathlib_rel_tmp";
    rc = $system($sformatf("realpath --relative-to=%s %s > %s 2>/dev/null", rbase, rpath, tmpfile));
    if (rc != 0) begin
      void'($system($sformatf("rm -f %s", tmpfile)));
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
    void'($system($sformatf("rm -f %s", tmpfile)));
    if (result.len() == 0) result = ".";
    return result;
  endfunction

  // File operations (DPI wrappers)
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

  static function int mkdir(string path);
    int rc = sv_pathlib_mkdir(path);
    if (rc != 0) $warning("sv_pathlib: mkdir failed: %s", path);
    return rc;
  endfunction

  static function int rmdir(string path);
    int rc = sv_pathlib_rmdir(path);
    if (rc != 0) $warning("sv_pathlib: rmdir failed: %s", path);
    return rc;
  endfunction

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
    sv_pathlib_copy(src, dst);
  endfunction

  static function void rename(string old_path, string new_path);
    sv_pathlib_rename(old_path, new_path);
  endfunction

  static function int symlink(string target, string linkpath);
    int rc = sv_pathlib_symlink(target, linkpath);
    if (rc != 0) $warning("sv_pathlib: symlink failed: %s -> %s", target, linkpath);
    return rc;
  endfunction

  static function void unlink(string path);
    sv_pathlib_unlink(path);
  endfunction

  static function longint size(string path);
    return sv_pathlib_size(path);
  endfunction

  static function longint modified(string path);
    return sv_pathlib_modified(path);
  endfunction

  // Full stat via DPI
  static function stat_t stat(string path);
    stat_t s;
    int rc;
    s.st_size = -1; s.st_mtime = 0; s.st_atime = 0; s.st_ctime = 0; s.st_mode = 0;
    rc = sv_pathlib_stat_full(path, s.st_size, s.st_mtime, s.st_atime, s.st_ctime, s.st_mode);
    if (rc != 0) begin
      s.st_size = -1;
      s.st_mtime = 0; s.st_atime = 0; s.st_ctime = 0; s.st_mode = 0;
    end
    return s;
  endfunction

  // iterdir via DPI - returns newline-separated string
  static function string iterdir(string path);
    string result;
    int rc;

    rc = sv_pathlib_readdir(path, result);
    if (rc != 0) begin
      $warning("sv_pathlib: iterdir failed: %s", path);
      return "";
    end

    return result;
  endfunction

  // Pattern matching (private)
  static function bit fnmatch(string pattern, string name);
    int pi, ni;
    int star_pi, star_ni;
    pi = 0; ni = 0; star_pi = -1; star_ni = -1;
    while (ni < name.len()) begin
      if (pi < pattern.len() && pattern[pi] == "[") begin
        bit negate = 0;
        bit matched = 0;
        int ci = pi + 1;
        if (ci < pattern.len() && pattern[ci] == "!") begin
          negate = 1; ci++;
        end
        while (ci < pattern.len() && pattern[ci] != "]") begin
          if (ci + 2 < pattern.len() && pattern[ci + 1] == "-") begin
            if (name[ni] >= pattern[ci] && name[ni] <= pattern[ci + 2]) matched = 1;
            ci += 3;
          end else begin
            if (name[ni] == pattern[ci]) matched = 1;
            ci++;
          end
        end
        if (matched != negate) begin
          pi = ci + 1; ni++; continue;
        end
      end
      if (pi < pattern.len() && (pattern[pi] == name[ni] || pattern[pi] == "?")) begin
        pi++; ni++;
      end else if (pi < pattern.len() && pattern[pi] == "*") begin
        star_pi = pi; star_ni = ni; pi++;
      end else if (star_pi >= 0) begin
        pi = star_pi + 1; star_ni++; ni = star_ni;
      end else begin
        return 0;
      end
    end
    while (pi < pattern.len() && pattern[pi] == "*") pi++;
    return pi == pattern.len();
  endfunction

  // Glob (non-recursive) - returns newline-separated matches
  static function string glob(string path, string pattern);
    string results = "";
    string entries = iterdir(path);
    string entry = "";
    string full_path;
    int i;

    if (entries.len() == 0) return results;

    for (i = 0; i < entries.len(); i++) begin
      if (entries[i] == "\n") begin
        if (entry.len() > 0) begin
          if (fnmatch(pattern, entry)) begin
            full_path = (path == "/") ? {"/", entry} : {path, "/", entry};
            if (results.len() > 0) results = {results, "\n"};
            results = {results, full_path};
          end
          entry = "";
        end
      end else begin
        entry = {entry, entries[i]};
      end
    end
    // Handle last entry
    if (entry.len() > 0) begin
      if (fnmatch(pattern, entry)) begin
        full_path = (path == "/") ? {"/", entry} : {path, "/", entry};
        if (results.len() > 0) results = {results, "\n"};
        results = {results, full_path};
      end
    end

    return results;
  endfunction

  // Recursive glob - returns newline-separated matches
  static function string rglob(string path, string pattern);
    string results = "";
    string entries = iterdir(path);
    string entry = "";
    string full_path;
    string sub_results;
    string sub_entry;
    int i, j;

    if (entries.len() == 0) return results;

    for (i = 0; i < entries.len(); i++) begin
      if (entries[i] == "\n") begin
        if (entry.len() > 0) begin
          full_path = (path == "/") ? {"/", entry} : {path, "/", entry};
          if (is_dir(full_path)) begin
            sub_results = rglob(full_path, pattern);
            if (sub_results.len() > 0) begin
              if (results.len() > 0) results = {results, "\n"};
              results = {results, sub_results};
            end
          end
          if (fnmatch(pattern, entry)) begin
            if (results.len() > 0) results = {results, "\n"};
            results = {results, full_path};
          end
          entry = "";
        end
      end else begin
        entry = {entry, entries[i]};
      end
    end
    // Handle last entry
    if (entry.len() > 0) begin
      full_path = (path == "/") ? {"/", entry} : {path, "/", entry};
      if (is_dir(full_path)) begin
        sub_results = rglob(full_path, pattern);
        if (sub_results.len() > 0) begin
          if (results.len() > 0) results = {results, "\n"};
          results = {results, sub_results};
        end
      end
      if (fnmatch(pattern, entry)) begin
        if (results.len() > 0) results = {results, "\n"};
        results = {results, full_path};
      end
    end

    return results;
  endfunction

  // Current working directory (via temp file, same as VCS)
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

  // Environment variable access (via DPI)
  static function string getenv(string name);
    return sv_pathlib_getenv(name);
  endfunction
endclass
