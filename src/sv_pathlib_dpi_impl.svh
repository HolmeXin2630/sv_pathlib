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
import "DPI-C" function int    sv_pathlib_getcwd(output string result);
import "DPI-C" function int    sv_pathlib_relative_to(input string path, input string base, output string result);

`include "sv_pathlib_common.svh"

  static function string relative_to(string path, string base);
    string rpath, rbase;
    string result;
    int rc;

    rpath = resolve(path);
    rbase = resolve(base);

    if (!is_absolute(rpath) || !is_absolute(rbase)) begin
      $warning("sv_pathlib: relative_to requires absolute paths");
      return "";
    end

    rc = sv_pathlib_relative_to(rpath, rbase, result);
    if (rc != 0) begin
      $warning("sv_pathlib: relative_to failed: %s relative to %s", path, base);
      return "";
    end
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

  // Current working directory (via DPI-C getcwd)
  static function string cwd();
    string result;
    int rc;
    rc = sv_pathlib_getcwd(result);
    if (rc != 0) begin
      $warning("sv_pathlib: getcwd failed");
      return "";
    end
    return result;
  endfunction

  // Environment variable access (via DPI)
  static function string getenv(string name);
    return sv_pathlib_getenv(name);
  endfunction
endclass
