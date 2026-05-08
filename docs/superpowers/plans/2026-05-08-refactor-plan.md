# sv_pathlib Refactoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor sv_pathlib from 3 backend packages to 2 (VCS + DPI) with macro selection, add Python pathlib-style functions, and reorganize into `src/` + `tests/` structure.

**Architecture:** Single `sv_pathlib_pkg.sv` package that `ifdef`s between VCS and DPI implementation files. Both impl files share identical path parsing code. New functions (glob, rglob, iterdir, stat, resolve, cwd) are added to both backends.

**Tech Stack:** SystemVerilog, DPI-C, Verilator, Make

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `src/sv_pathlib_define.svh` | Create | Macro definitions header |
| `src/sv_pathlib_pkg.sv` | Create | Top-level package, macro-selects impl |
| `src/sv_pathlib_vcs_impl.svh` | Create | VCS implementation (pure $system) |
| `src/sv_pathlib_dpi_impl.svh` | Create | DPI implementation (DPI-C) |
| `src/dpi/sv_pathlib_dpi.cc` | Create | DPI-C POSIX implementation |
| `tests/test_path_parse.sv` | Create | Path parsing tests |
| `tests/test_path_check.sv` | Create | File check tests |
| `tests/test_dir_ops.sv` | Create | Directory operation tests |
| `tests/test_file_io.sv` | Create | File I/O tests |
| `tests/test_file_ops.sv` | Create | File operation tests |
| `tests/test_stat.sv` | Create | stat() tests |
| `tests/test_glob.sv` | Create | glob/rglob tests |
| `tests/test_resolve.sv` | Create | resolve() tests |
| `tests/test_cwd.sv` | Create | cwd() tests |
| `tests/main_*.cpp` | Create | Verilator entry points |
| `Makefile` | Rewrite | Updated build rules |
| `README.md` | Update | New usage instructions |
| `sv_pathlib_vcs_pkg.sv` | Delete | Old VCS package |
| `sv_pathlib_sys_pkg.sv` | Delete | Old sys package |
| `sv_pathlib_dpi_pkg.sv` | Delete | Old DPI package |
| `sv_pathlib_dpi/` | Delete | Old DPI directory |
| `sv_pathlib_tests/` | Delete | Old tests directory |

---

## Task 1: Create src/ directory and define header

**Files:**
- Create: `src/sv_pathlib_define.svh`

- [ ] **Step 1: Create src/dpi directory**

```bash
mkdir -p src/dpi
```

- [ ] **Step 2: Create sv_pathlib_define.svh**

```systemverilog
// sv_pathlib_define.svh
// Backend selection macro
// Default: VCS mode (no DPI)
// Compile with +define+SV_PATHLIB_USE_DPI for DPI mode
```

- [ ] **Step 3: Commit**

```bash
git add src/
git commit -m "chore: create src/ directory structure"
```

---

## Task 2: Create VCS implementation file

**Files:**
- Create: `src/sv_pathlib_vcs_impl.svh`

- [ ] **Step 1: Create sv_pathlib_vcs_impl.svh with path parsing**

Port all 8 path parsing functions from existing `sv_pathlib_vcs_pkg.sv`. These are pure SV, identical across backends.

```systemverilog
// stat_t struct (defined before class)
typedef struct {
  longint st_size;
  longint st_mtime;
  longint st_atime;
  longint st_ctime;
  int     st_mode;
} stat_t;

class Path;
  // === Path Parsing (pure SV) ===

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
```

- [ ] **Step 2: Add resolve() - pure SV, no backend dependency**

```systemverilog
  // resolve: pure SV, handles .. and .
  static function string resolve(string path);
    string result = "";
    string component;
    string temp;
    int i, start;
    bit is_abs;

    is_abs = is_absolute(path);

    // Split path into components
    string components[$];
    components = {};
    start = is_abs ? 1 : 0;
    for (i = start; i < path.len(); i++) begin
      if (path[i] == "/") begin
        if (i > start) begin
          components.push_back(path.substr(start, i - 1));
        end
        start = i + 1;
      end
    end
    if (start < path.len()) begin
      components.push_back(path.substr(start, path.len() - 1));
    end

    // Resolve .. and .
    string resolved[$];
    resolved = {};
    foreach (components[i]) begin
      if (components[i] == "..") begin
        if (resolved.size() > 0) resolved.pop_back();
      end else if (components[i] != ".") begin
        resolved.push_back(components[i]);
      end
    end

    // Reconstruct path
    if (is_abs) result = "/";
    foreach (resolved[i]) begin
      if (i > 0 || result != "") result = {result, "/"};
      result = {result, resolved[i]};
    end

    if (result == "" && !is_abs) result = ".";
    return result;
  endfunction
```

- [ ] **Step 3: Add VCS file operations (exists through symlink)**

Copy from existing `sv_pathlib_vcs_pkg.sv` lines 120-250. Include: `_read_temp_longint`, `exists`, `is_file`, `is_dir`, `is_symlink`, `is_empty`, `mkdir`, `rmdir`, `read_text`, `write_text`, `copy`, `rename`, `unlink`, `symlink`, `size`, `modified`.

- [ ] **Step 4: Add stat() for VCS mode**

```systemverilog
  // stat: VCS mode uses stat command + temp file
  static function stat_t stat(string path);
    stat_t s;
    string tmpfile = "/tmp/.sv_pathlib_stat_full_tmp";
    int rc;
    string line;
    int fh;

    s.st_size = -1;
    s.st_mtime = 0;
    s.st_atime = 0;
    s.st_ctime = 0;
    s.st_mode = 0;

    if (!exists(path)) return s;

    // Get size
    s.st_size = size(path);

    // Get mtime
    s.st_mtime = modified(path);

    // Get full stat via stat command
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
```

- [ ] **Step 5: Add iterdir() for VCS mode**

```systemverilog
  // iterdir: VCS mode uses ls -1
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
        // Trim trailing newline
        while (line.len() > 0 && line[line.len()-1] == "\n")
          line = line.substr(0, line.len()-2);
        while (line.len() > 0 && line[line.len()-1] == "\r")
          line = line.substr(0, line.len()-2);
        if (line.len() > 0)
          entries.push_back(line);
      end
    end
    $fclose(fh);
    void'($system($sformatf("rm -f %s", tmpfile)));
    return entries;
  endfunction
```

- [ ] **Step 6: Add glob/rglob stubs for VCS mode**

```systemverilog
  // glob: not supported in VCS mode
  static function queue<string> glob(string path, string pattern);
    $error("sv_pathlib: glob() requires DPI mode (+define+SV_PATHLIB_USE_DPI)");
    return {};
  endfunction

  // rglob: not supported in VCS mode
  static function queue<string> rglob(string path, string pattern);
    $error("sv_pathlib: rglob() requires DPI mode (+define+SV_PATHLIB_USE_DPI)");
    return {};
  endfunction
```

- [ ] **Step 7: Add cwd() for VCS mode**

```systemverilog
  // cwd: both modes use pwd + temp file (simple and consistent)
  static function string cwd();
    string tmpfile = "/tmp/.sv_pathlib_cwd_tmp";
    string result = "";
    int fh;

    void'($system($sformatf("pwd > %s 2>/dev/null", tmpfile)));
    fh = $fopen(tmpfile, "r");
    if (fh != 0) begin
      void'($fgets(result, fh));
      $fclose(fh);
      // Trim trailing newline
      while (result.len() > 0 && result[result.len()-1] == "\n")
        result = result.substr(0, result.len()-2);
      while (result.len() > 0 && result[result.len()-1] == "\r")
        result = result.substr(0, result.len()-2);
    end
    void'($system($sformatf("rm -f %s", tmpfile)));
    return result;
  endfunction
```

- [ ] **Step 8: Commit**

```bash
git add src/sv_pathlib_vcs_impl.svh
git commit -m "feat: create VCS implementation with path parsing and file ops"
```

---

## Task 3: Create DPI implementation file

**Files:**
- Create: `src/sv_pathlib_dpi_impl.svh`

- [ ] **Step 1: Create sv_pathlib_dpi_impl.svh with DPI imports**

```systemverilog
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
```

- [ ] **Step 2: Add same path parsing functions (copy from VCS impl)**

Copy all 8 path parsing functions + resolve() from Task 2 Steps 1-2. These are identical.

- [ ] **Step 3: Add DPI file operations**

```systemverilog
  // === File Checks (DPI backend) ===
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

  static function int symlink(string target, string linkpath);
    return sv_pathlib_symlink(target, linkpath);
  endfunction

  // File info
  static function longint size(string path);
    return sv_pathlib_size(path);
  endfunction

  static function longint modified(string path);
    return sv_pathlib_modified(path);
  endfunction
```

- [ ] **Step 4: Add stat() for DPI mode**

```systemverilog
  static function stat_t stat(string path);
    stat_t s;
    s.st_size = 0;
    s.st_mtime = 0;
    s.st_atime = 0;
    s.st_ctime = 0;
    s.st_mode = 0;
    void'(sv_pathlib_stat_full(path, s.st_size, s.st_mtime, s.st_atime, s.st_ctime, s.st_mode));
    return s;
  endfunction
```

- [ ] **Step 5: Add iterdir() for DPI mode**

```systemverilog
  static function queue<string> iterdir(string path);
    queue<string> entries = {};
    string raw;
    string line;
    int i, start;

    if (!is_dir(path)) begin
      $warning("sv_pathlib: iterdir: not a directory: %s", path);
      return entries;
    end

    if (sv_pathlib_readdir(path, raw) != 0) return entries;

    // Split newline-separated result
    start = 0;
    for (i = 0; i < raw.len(); i++) begin
      if (raw[i] == "\n") begin
        if (i > start) entries.push_back(raw.substr(start, i - 1));
        start = i + 1;
      end
    end
    if (start < raw.len()) entries.push_back(raw.substr(start, raw.len() - 1));
    return entries;
  endfunction
```

- [ ] **Step 6: Add fnmatch helper for glob**

```systemverilog
  // fnmatch: match a single path component against a pattern
  static function bit fnmatch(string pattern, string name);
    int pi, ni;
    int star_pi, star_ni;
    int bracket_start;

    pi = 0;
    ni = 0;
    star_pi = -1;
    star_ni = -1;

    while (ni < name.len()) begin
      // Handle bracket expressions [abc] and [!abc]
      if (pi < pattern.len() && pattern[pi] == "[") begin
        bit negate = 0;
        bit matched = 0;
        int ci = pi + 1;

        if (ci < pattern.len() && pattern[ci] == "!") begin
          negate = 1;
          ci++;
        end

        while (ci < pattern.len() && pattern[ci] != "]") begin
          if (ci + 2 < pattern.len() && pattern[ci + 1] == "-") begin
            // Range: [a-z]
            if (name[ni] >= pattern[ci] && name[ni] <= pattern[ci + 2])
              matched = 1;
            ci += 3;
          end else begin
            if (name[ni] == pattern[ci])
              matched = 1;
            ci++;
          end
        end

        if (matched != negate) begin
          pi = ci + 1; // skip past ]
          ni++;
          continue;
        end
        // Fall through to star handling
      end

      if (pi < pattern.len() && (pattern[pi] == name[ni] || pattern[pi] == "?")) begin
        pi++;
        ni++;
      end else if (pi < pattern.len() && pattern[pi] == "*") begin
        star_pi = pi;
        star_ni = ni;
        pi++;
      end else if (star_pi >= 0) begin
        pi = star_pi + 1;
        star_ni++;
        ni = star_ni;
      end else begin
        return 0;
      end
    end

    // Skip trailing stars in pattern
    while (pi < pattern.len() && pattern[pi] == "*") pi++;
    return pi == pattern.len();
  endfunction
```

- [ ] **Step 7: Add glob/rglob for DPI mode**

```systemverilog
  static function queue<string> glob(string path, string pattern);
    queue<string> results = {};
    queue<string> entries = iterdir(path);
    string full_path;

    foreach (entries[i]) begin
      if (fnmatch(pattern, entries[i])) begin
        full_path = (path == "/") ? {"/", entries[i]} : {path, "/", entries[i]};
        results.push_back(full_path);
      end
    end
    return results;
  endfunction

  static function queue<string> rglob(string path, string pattern);
    queue<string> results = {};
    queue<string> entries = iterdir(path);
    queue<string> sub_results;
    string full_path;

    foreach (entries[i]) begin
      full_path = (path == "/") ? {"/", entries[i]} : {path, "/", entries[i]};
      if (is_dir(full_path)) begin
        sub_results = rglob(full_path, pattern);
        foreach (sub_results[j]) results.push_back(sub_results[j]);
      end
      if (fnmatch(pattern, entries[i])) begin
        results.push_back(full_path);
      end
    end
    return results;
  endfunction
```

- [ ] **Step 8: Add cwd() for DPI mode**

```systemverilog
  // cwd: same temp file approach as VCS (simple and consistent)
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
```

- [ ] **Step 9: Commit**

```bash
git add src/sv_pathlib_dpi_impl.svh
git commit -m "feat: create DPI implementation with path parsing, file ops, and new functions"
```

---

## Task 4: Create top-level package

**Files:**
- Create: `src/sv_pathlib_pkg.sv`

- [ ] **Step 1: Create sv_pathlib_pkg.sv**

```systemverilog
`include "sv_pathlib_define.svh"
package sv_pathlib_pkg;

`ifdef SV_PATHLIB_USE_DPI
  `include "sv_pathlib_dpi_impl.svh"
`else
  `include "sv_pathlib_vcs_impl.svh"
`endif

endpackage
```

- [ ] **Step 2: Commit**

```bash
git add src/sv_pathlib_pkg.sv
git commit -m "feat: add top-level package with macro-based backend selection"
```

---

## Task 5: Create DPI-C implementation

**Files:**
- Create: `src/dpi/sv_pathlib_dpi.cc`

- [ ] **Step 1: Create sv_pathlib_dpi.cc with all functions**

```cpp
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

extern "C" {

  // Existing functions (port from old path_dpi_impl.cc)
  int sv_pathlib_exists(const char* path) {
    struct stat buf;
    return stat(path, &buf) == 0;
  }

  int sv_pathlib_is_file(const char* path) {
    struct stat buf;
    if (stat(path, &buf) != 0) return 0;
    return S_ISREG(buf.st_mode);
  }

  int sv_pathlib_is_dir(const char* path) {
    struct stat buf;
    if (stat(path, &buf) != 0) return 0;
    return S_ISDIR(buf.st_mode);
  }

  int sv_pathlib_is_symlink(const char* path) {
    struct stat buf;
    if (lstat(path, &buf) != 0) return 0;
    return S_ISLNK(buf.st_mode);
  }

  int sv_pathlib_is_empty(const char* path) {
    struct stat buf;
    if (stat(path, &buf) != 0) return 0;
    return S_ISREG(buf.st_mode) && buf.st_size == 0;
  }

  int sv_pathlib_mkdir(const char* path) {
    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "mkdir -p \"%s\"", path);
    return system(cmd);
  }

  int sv_pathlib_rmdir(const char* path) {
    return rmdir(path);
  }

  long long sv_pathlib_size(const char* path) {
    struct stat buf;
    if (stat(path, &buf) != 0) return -1;
    return (long long)buf.st_size;
  }

  long long sv_pathlib_modified(const char* path) {
    struct stat buf;
    if (stat(path, &buf) != 0) return -1;
    return (long long)buf.st_mtime;
  }

  void sv_pathlib_copy(const char* src, const char* dst) {
    char cmd[2048];
    snprintf(cmd, sizeof(cmd), "cp \"%s\" \"%s\"", src, dst);
    int ret = system(cmd);
    (void)ret;
  }

  void sv_pathlib_rename(const char* old_path, const char* new_path) {
    rename(old_path, new_path);
  }

  void sv_pathlib_unlink(const char* path) {
    unlink(path);
  }

  int sv_pathlib_symlink(const char* target, const char* linkpath) {
    return symlink(target, linkpath);
  }

  // New functions

  int sv_pathlib_readdir(const char* path, char** result) {
    DIR* dir = opendir(path);
    if (!dir) {
      *result = strdup("");
      return -1;
    }

    // First pass: calculate total size
    struct dirent* entry;
    int total_len = 0;
    int count = 0;
    while ((entry = readdir(dir)) != NULL) {
      if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
        continue;
      total_len += strlen(entry->d_name) + 1; // +1 for \n
      count++;
    }
    rewinddir(dir);

    if (count == 0) {
      *result = strdup("");
      closedir(dir);
      return 0;
    }

    // Second pass: build result string
    *result = (char*)malloc(total_len + 1);
    if (!*result) {
      closedir(dir);
      return -1;
    }
    (*result)[0] = '\0';

    while ((entry = readdir(dir)) != NULL) {
      if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0)
        continue;
      strcat(*result, entry->d_name);
      strcat(*result, "\n");
    }
    closedir(dir);
    return 0;
  }

  int sv_pathlib_stat_full(const char* path, long long* size,
                           long long* mtime, long long* atime,
                           long long* ctime, int* mode) {
    struct stat buf;
    if (stat(path, &buf) != 0) return -1;
    *size = (long long)buf.st_size;
    *mtime = (long long)buf.st_mtime;
    *atime = (long long)buf.st_atime;
    *ctime = (long long)buf.st_ctime;
    *mode = (int)buf.st_mode;
    return 0;
  }

}
```

- [ ] **Step 2: Commit**

```bash
git add src/dpi/sv_pathlib_dpi.cc
git commit -m "feat: add DPI-C implementation with readdir and stat_full"
```

---

## Task 6: Create test files

**Files:**
- Create: `tests/test_path_parse.sv`
- Create: `tests/test_path_check.sv`
- Create: `tests/test_dir_ops.sv`
- Create: `tests/test_file_io.sv`
- Create: `tests/test_file_ops.sv`
- Create: `tests/test_stat.sv`
- Create: `tests/test_glob.sv`
- Create: `tests/test_resolve.sv`
- Create: `tests/test_cwd.sv`
- Create: `tests/main_*.cpp` (one per test)

- [ ] **Step 1: Create test_path_parse.sv**

```systemverilog
import sv_pathlib_pkg::*;

module test_path_parse;
  int pass_count = 0;
  int fail_count = 0;

  task automatic check(string test_name, string actual, string expected);
    if (actual == expected) begin
      $display("[PASS] %s: got '%s'", test_name, actual);
      pass_count++;
    end else begin
      $display("[FAIL] %s: expected '%s', got '%s'", test_name, expected, actual);
      fail_count++;
    end
  endtask

  task automatic check_bit(string test_name, bit actual, bit expected);
    if (actual == expected) begin
      $display("[PASS] %s: got %0d", test_name, actual);
      pass_count++;
    end else begin
      $display("[FAIL] %s: expected %0d, got %0d", test_name, expected, actual);
      fail_count++;
    end
  endtask

  initial begin
    check("name - file.txt", Path::name("/tmp/file.txt"), "file.txt");
    check("name - dir/file.sv", Path::name("/home/user/dir/file.sv"), "file.sv");
    check("stem - file.txt", Path::stem("/tmp/file.txt"), "file");
    check("stem - archive.tar.gz", Path::stem("/tmp/archive.tar.gz"), "archive.tar");
    check("extension - file.txt", Path::extension("/tmp/file.txt"), ".txt");
    check("extension - file.sv", Path::extension("/tmp/file.sv"), ".sv");
    check("extension - no_ext", Path::extension("/tmp/file"), "");
    check("parent - /tmp/file.txt", Path::parent("/tmp/file.txt"), "/tmp");
    check("parent - /a/b/c/file", Path::parent("/a/b/c/file"), "/a/b/c");
    check("join_path - base + rel", Path::join_path("/tmp", "file.txt"), "/tmp/file.txt");
    check("join_path - base + abs", Path::join_path("/tmp", "/abs/file.txt"), "/abs/file.txt");
    check("join_path - trailing slash", Path::join_path("/tmp/", "file.txt"), "/tmp/file.txt");
    check("with_name - /tmp/old.txt", Path::with_name("/tmp/old.txt", "new.txt"), "/tmp/new.txt");
    check("with_suffix - .txt to .sv", Path::with_suffix("/tmp/file.txt", ".sv"), "/tmp/file.sv");
    check_bit("is_absolute - /tmp", Path::is_absolute("/tmp"), 1);
    check_bit("is_absolute - tmp", Path::is_absolute("tmp"), 0);

    $display("\nPath parsing tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
```

- [ ] **Step 2: Create test_resolve.sv**

```systemverilog
import sv_pathlib_pkg::*;

module test_resolve;
  int pass_count = 0;
  int fail_count = 0;

  task automatic check(string test_name, string actual, string expected);
    if (actual == expected) begin
      $display("[PASS] %s: got '%s'", test_name, actual);
      pass_count++;
    end else begin
      $display("[FAIL] %s: expected '%s', got '%s'", test_name, expected, actual);
      fail_count++;
    end
  endtask

  initial begin
    check("resolve - /a/b/../c", Path::resolve("/a/b/../c"), "/a/c");
    check("resolve - /a/b/./c", Path::resolve("/a/b/./c"), "/a/b/c");
    check("resolve - /a/b/../c/./d", Path::resolve("/a/b/../c/./d"), "/a/c/d");
    check("resolve - a/b/../c", Path::resolve("a/b/../c"), "a/c");
    check("resolve - /", Path::resolve("/"), "/");
    check("resolve - .", Path::resolve("."), ".");
    check("resolve - ..", Path::resolve(".."), "..");
    check("resolve - /a/../../b", Path::resolve("/a/../../b"), "/b");

    $display("\nResolve tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
```

- [ ] **Step 3: Create test_stat.sv**

```systemverilog
import sv_pathlib_pkg::*;

module test_stat;
  int pass_count = 0;
  int fail_count = 0;

  task automatic check(string test_name, bit condition);
    if (condition) begin
      $display("[PASS] %s", test_name);
      pass_count++;
    end else begin
      $display("[FAIL] %s", test_name);
      fail_count++;
    end
  endtask

  initial begin
    stat_t s;
    string test_file = "/tmp/sv_pathlib_stat_test.txt";
    int fh;

    // Create test file
    fh = $fopen(test_file, "w");
    $fwrite(fh, "stat test content");
    $fclose(fh);

    s = Path::stat(test_file);
    check("stat - size > 0", s.st_size > 0);
    check("stat - mtime > 0", s.st_mtime > 0);
    check("stat - atime > 0", s.st_atime > 0);

    // Test stat on nonexistent file
    s = Path::stat("/tmp/nonexistent_xyz");
    check("stat - nonexistent size == -1", s.st_size == -1);

    // Cleanup
    Path::unlink(test_file);

    $display("\nStat tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
```

- [ ] **Step 4: Create test_cwd.sv**

```systemverilog
import sv_pathlib_pkg::*;

module test_cwd;
  int pass_count = 0;
  int fail_count = 0;

  task automatic check(string test_name, bit condition);
    if (condition) begin
      $display("[PASS] %s", test_name);
      pass_count++;
    end else begin
      $display("[FAIL] %s", test_name);
      fail_count++;
    end
  endtask

  initial begin
    string cwd;

    cwd = Path::cwd();
    check("cwd - not empty", cwd.len() > 0);
    check("cwd - starts with /", cwd[0] == "/");

    $display("\nCWD tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
```

- [ ] **Step 5: Create test_dir_ops.sv with iterdir**

```systemverilog
import sv_pathlib_pkg::*;

module test_dir_ops;
  int pass_count = 0;
  int fail_count = 0;

  task automatic check(string test_name, bit condition);
    if (condition) begin
      $display("[PASS] %s", test_name);
      pass_count++;
    end else begin
      $display("[FAIL] %s", test_name);
      fail_count++;
    end
  endtask

  task automatic check_int(string test_name, int actual, int expected);
    if (actual == expected) begin
      $display("[PASS] %s: got %0d", test_name, actual);
      pass_count++;
    end else begin
      $display("[FAIL] %s: expected %0d, got %0d", test_name, expected, actual);
      fail_count++;
    end
  endtask

  initial begin
    string test_dir = "/tmp/sv_pathlib_dirtest_new";
    queue<string> entries;
    int fh;

    // Test mkdir
    check("mkdir - create", Path::mkdir(test_dir) == 0);
    check("mkdir - exists after", Path::exists(test_dir));

    // Create some files for iterdir
    fh = $fopen({test_dir, "/file_a.txt"}, "w");
    $fwrite(fh, "a");
    $fclose(fh);
    fh = $fopen({test_dir, "/file_b.txt"}, "w");
    $fwrite(fh, "b");
    $fclose(fh);

    // Test iterdir
    entries = Path::iterdir(test_dir);
    check("iterdir - has entries", entries.size() == 2);

    // Cleanup
    Path::unlink({test_dir, "/file_a.txt"});
    Path::unlink({test_dir, "/file_b.txt"});
    Path::rmdir(test_dir);

    $display("\nDir ops tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
```

- [ ] **Step 6: Create test_glob.sv**

```systemverilog
import sv_pathlib_pkg::*;

module test_glob;
  int pass_count = 0;
  int fail_count = 0;

  task automatic check(string test_name, bit condition);
    if (condition) begin
      $display("[PASS] %s", test_name);
      pass_count++;
    end else begin
      $display("[FAIL] %s", test_name);
      fail_count++;
    end
  endtask

  initial begin
    string test_dir = "/tmp/sv_pathlib_glob_test";
    queue<string> results;
    int fh;

    // Setup
    void'(Path::mkdir(test_dir));
    fh = $fopen({test_dir, "/test.sv"}, "w");
    $fwrite(fh, "test");
    $fclose(fh);
    fh = $fopen({test_dir, "/test.txt"}, "w");
    $fwrite(fh, "test");
    $fclose(fh);
    fh = $fopen({test_dir, "/other.sv"}, "w");
    $fwrite(fh, "test");
    $fclose(fh);

`ifdef SV_PATHLIB_USE_DPI
    // Test glob with *.sv pattern
    results = Path::glob(test_dir, "*.sv");
    check("glob *.sv - found 2", results.size() == 2);

    // Test glob with *.txt pattern
    results = Path::glob(test_dir, "*.txt");
    check("glob *.txt - found 1", results.size() == 1);

    // Test rglob
    void'(Path::mkdir({test_dir, "/sub"}));
    fh = $fopen({test_dir, "/sub/nested.sv"}, "w");
    $fwrite(fh, "test");
    $fclose(fh);
    results = Path::rglob(test_dir, "*.sv");
    check("rglob *.sv - found 3 (including nested)", results.size() == 3);
`else
    // VCS mode: glob should return empty
    results = Path::glob(test_dir, "*.sv");
    check("glob VCS mode - returns empty", results.size() == 0);
`endif

    // Cleanup
    void'($system($sformatf("rm -rf %s", test_dir)));

    $display("\nGlob tests: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) $finish(1);
    $finish;
  end
endmodule
```

- [ ] **Step 7: Create test_path_check.sv**

Port from existing `sv_pathlib_tests/test_path_check_sys.sv`, changing `import sv_pathlib_sys_pkg::*` to `import sv_pathlib_pkg::*` and replacing `c_system(...)` calls with `Path::` equivalents.

- [ ] **Step 8: Create test_file_io.sv**

Port from existing `sv_pathlib_tests/test_file_io_sys.sv`, changing import.

- [ ] **Step 9: Create test_file_ops.sv**

Port from existing `sv_pathlib_tests/test_file_ops_sys.sv`, changing import.

- [ ] **Step 10: Create Verilator main.cpp files**

Each test needs a main.cpp. Pattern:

```cpp
#include "Vtest_<module_name>.h"
#include "verilated.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtest_<module_name>* top = new Vtest_<module_name>;
    while (!Verilated::gotFinish()) {
        top->eval();
    }
    delete top;
    return 0;
}
```

Create one for each test module.

- [ ] **Step 11: Commit**

```bash
git add tests/
git commit -m "feat: add test files for all functions"
```

---

## Task 7: Update Makefile

**Files:**
- Modify: `Makefile`

- [ ] **Step 1: Rewrite Makefile**

```makefile
VERILATOR = verilator
VERILATOR_FLAGS = --cc --exe --build

# VCS mode targets (default)
.PHONY: test_vcs_all test_dpi_all test_clean clean

test_vcs_path_parse:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		src/sv_pathlib_pkg.sv \
		tests/test_path_parse.sv \
		tests/main_path_parse.cpp \
		--top-module test_path_parse \
		--Mdir obj_dir_vcs_path_parse \
		-o test_path_parse
	./obj_dir_vcs_path_parse/test_path_parse

test_vcs_resolve:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		src/sv_pathlib_pkg.sv \
		tests/test_resolve.sv \
		tests/main_resolve.cpp \
		--top-module test_resolve \
		--Mdir obj_dir_vcs_resolve \
		-o test_resolve
	./obj_dir_vcs_resolve/test_resolve

test_vcs_stat:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		src/sv_pathlib_pkg.sv \
		tests/test_stat.sv \
		tests/main_stat.cpp \
		--top-module test_stat \
		--Mdir obj_dir_vcs_stat \
		-o test_stat
	./obj_dir_vcs_stat/test_stat

test_vcs_cwd:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		src/sv_pathlib_pkg.sv \
		tests/test_cwd.sv \
		tests/main_cwd.cpp \
		--top-module test_cwd \
		--Mdir obj_dir_vcs_cwd \
		-o test_cwd
	./obj_dir_vcs_cwd/test_cwd

test_vcs_dir_ops:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		src/sv_pathlib_pkg.sv \
		tests/test_dir_ops.sv \
		tests/main_dir_ops.cpp \
		--top-module test_dir_ops \
		--Mdir obj_dir_vcs_dir_ops \
		-o test_dir_ops
	./obj_dir_vcs_dir_ops/test_dir_ops

test_vcs_file_io:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		src/sv_pathlib_pkg.sv \
		tests/test_file_io.sv \
		tests/main_file_io.cpp \
		--top-module test_file_io \
		--Mdir obj_dir_vcs_file_io \
		-o test_file_io
	./obj_dir_vcs_file_io/test_file_io

test_vcs_file_ops:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		src/sv_pathlib_pkg.sv \
		tests/test_file_ops.sv \
		tests/main_file_ops.cpp \
		--top-module test_file_ops \
		--Mdir obj_dir_vcs_file_ops \
		-o test_file_ops
	./obj_dir_vcs_file_ops/test_file_ops

test_vcs_path_check:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		src/sv_pathlib_pkg.sv \
		tests/test_path_check.sv \
		tests/main_path_check.cpp \
		--top-module test_path_check \
		--Mdir obj_dir_vcs_path_check \
		-o test_path_check
	./obj_dir_vcs_path_check/test_path_check

test_vcs_all: test_vcs_path_parse test_vcs_resolve test_vcs_stat test_vcs_cwd test_vcs_dir_ops test_vcs_file_io test_vcs_file_ops test_vcs_path_check
	@echo "All VCS mode tests passed!"

# DPI mode targets
test_dpi_path_parse:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		+define+SV_PATHLIB_USE_DPI \
		src/sv_pathlib_pkg.sv \
		tests/test_path_parse.sv \
		tests/main_path_parse.cpp \
		src/dpi/sv_pathlib_dpi.cc \
		--top-module test_path_parse \
		--Mdir obj_dir_dpi_path_parse \
		-o test_path_parse
	./obj_dir_dpi_path_parse/test_path_parse

test_dpi_resolve:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		+define+SV_PATHLIB_USE_DPI \
		src/sv_pathlib_pkg.sv \
		tests/test_resolve.sv \
		tests/main_resolve.cpp \
		src/dpi/sv_pathlib_dpi.cc \
		--top-module test_resolve \
		--Mdir obj_dir_dpi_resolve \
		-o test_resolve
	./obj_dir_dpi_resolve/test_resolve

test_dpi_stat:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		+define+SV_PATHLIB_USE_DPI \
		src/sv_pathlib_pkg.sv \
		tests/test_stat.sv \
		tests/main_stat.cpp \
		src/dpi/sv_pathlib_dpi.cc \
		--top-module test_stat \
		--Mdir obj_dir_dpi_stat \
		-o test_stat
	./obj_dir_dpi_stat/test_stat

test_dpi_cwd:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		+define+SV_PATHLIB_USE_DPI \
		src/sv_pathlib_pkg.sv \
		tests/test_cwd.sv \
		tests/main_cwd.cpp \
		src/dpi/sv_pathlib_dpi.cc \
		--top-module test_cwd \
		--Mdir obj_dir_dpi_cwd \
		-o test_cwd
	./obj_dir_dpi_cwd/test_cwd

test_dpi_dir_ops:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		+define+SV_PATHLIB_USE_DPI \
		src/sv_pathlib_pkg.sv \
		tests/test_dir_ops.sv \
		tests/main_dir_ops.cpp \
		src/dpi/sv_pathlib_dpi.cc \
		--top-module test_dir_ops \
		--Mdir obj_dir_dpi_dir_ops \
		-o test_dir_ops
	./obj_dir_dpi_dir_ops/test_dir_ops

test_dpi_file_io:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		+define+SV_PATHLIB_USE_DPI \
		src/sv_pathlib_pkg.sv \
		tests/test_file_io.sv \
		tests/main_file_io.cpp \
		src/dpi/sv_pathlib_dpi.cc \
		--top-module test_file_io \
		--Mdir obj_dir_dpi_file_io \
		-o test_file_io
	./obj_dir_dpi_file_io/test_file_io

test_dpi_file_ops:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		+define+SV_PATHLIB_USE_DPI \
		src/sv_pathlib_pkg.sv \
		tests/test_file_ops.sv \
		tests/main_file_ops.cpp \
		src/dpi/sv_pathlib_dpi.cc \
		--top-module test_file_ops \
		--Mdir obj_dir_dpi_file_ops \
		-o test_file_ops
	./obj_dir_dpi_file_ops/test_file_ops

test_dpi_glob:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		+define+SV_PATHLIB_USE_DPI \
		src/sv_pathlib_pkg.sv \
		tests/test_glob.sv \
		tests/main_glob.cpp \
		src/dpi/sv_pathlib_dpi.cc \
		--top-module test_glob \
		--Mdir obj_dir_dpi_glob \
		-o test_glob
	./obj_dir_dpi_glob/test_glob

test_dpi_path_check:
	$(VERILATOR) $(VERILATOR_FLAGS) \
		+define+SV_PATHLIB_USE_DPI \
		src/sv_pathlib_pkg.sv \
		tests/test_path_check.sv \
		tests/main_path_check.cpp \
		src/dpi/sv_pathlib_dpi.cc \
		--top-module test_path_check \
		--Mdir obj_dir_dpi_path_check \
		-o test_path_check
	./obj_dir_dpi_path_check/test_path_check

test_dpi_all: test_dpi_path_parse test_dpi_resolve test_dpi_stat test_dpi_cwd test_dpi_dir_ops test_dpi_file_io test_dpi_file_ops test_dpi_glob test_dpi_path_check
	@echo "All DPI mode tests passed!"

test_all: test_vcs_all test_dpi_all
	@echo "All tests passed!"

test_clean:
	rm -rf obj_dir_*

clean: test_clean
	rm -rf obj_dir* vcs_build/
```

- [ ] **Step 2: Commit**

```bash
git add Makefile
git commit -m "feat: update Makefile for VCS and DPI mode targets"
```

---

## Task 8: Run tests and fix issues

- [ ] **Step 1: Run VCS mode tests**

```bash
make test_vcs_path_parse
```

Expected: All tests PASS. If any FAIL, fix the implementation.

- [ ] **Step 2: Run DPI mode tests**

```bash
make test_dpi_path_parse
```

Expected: All tests PASS. If any FAIL, fix the implementation.

- [ ] **Step 3: Run all tests**

```bash
make test_all
```

- [ ] **Step 4: Fix any compilation or test failures**

Debug and fix issues found in steps 1-3.

- [ ] **Step 5: Commit fixes**

```bash
git add -A
git commit -m "fix: resolve compilation and test issues"
```

---

## Task 9: Clean up old files

- [ ] **Step 1: Delete old package files**

```bash
git rm sv_pathlib_vcs_pkg.sv sv_pathlib_sys_pkg.sv sv_pathlib_dpi_pkg.sv
```

- [ ] **Step 2: Delete old DPI directory**

```bash
git rm -r sv_pathlib_dpi/
```

- [ ] **Step 3: Delete old tests directory**

```bash
git rm -r sv_pathlib_tests/
```

- [ ] **Step 4: Commit cleanup**

```bash
git commit -m "chore: remove old package files and test directory"
```

---

## Task 10: Update documentation

- [ ] **Step 1: Update README.md**

Update usage instructions to reflect new file structure and backend selection.

- [ ] **Step 2: Update CLAUDE.md**

Update architecture section to reflect new structure.

- [ ] **Step 3: Commit**

```bash
git add README.md CLAUDE.md
git commit -m "docs: update README and CLAUDE.md for new structure"
```
