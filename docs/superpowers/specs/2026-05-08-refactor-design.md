# sv_pathlib Refactoring Design Spec

Date: 2026-05-08

## Overview

Refactor sv_pathlib to:
1. Consolidate 3 backend packages into 2 (VCS + DPI) with macro-based selection
2. Add Python pathlib-style functions (glob, rglob, iterdir, stat, resolve, cwd)
3. Reorganize file structure into `src/` + `tests/`

## 1. File Structure

```
sv_pathlib/
├── src/
│   ├── sv_pathlib_pkg.sv          # Top-level package, macro-selects impl
│   ├── sv_pathlib_define.svh      # Macro definitions
│   ├── sv_pathlib_vcs_impl.svh    # VCS implementation (pure $system)
│   ├── sv_pathlib_dpi_impl.svh    # DPI implementation (DPI-C)
│   └── dpi/
│       └── sv_pathlib_dpi.cc      # DPI-C POSIX implementation
├── tests/
│   ├── test_path_parse.sv
│   ├── test_path_check.sv
│   ├── test_dir_ops.sv
│   ├── test_file_io.sv
│   ├── test_file_ops.sv
│   ├── test_stat.sv
│   ├── test_glob.sv
│   ├── test_resolve.sv
│   ├── test_cwd.sv
│   ├── main_*.cpp                 # Verilator entry points
│   └── ...
├── Makefile
├── README.md
└── CLAUDE.md
```

Delete old files: `sv_pathlib_vcs_pkg.sv`, `sv_pathlib_sys_pkg.sv`, `sv_pathlib_dpi_pkg.sv`, `sv_pathlib_dpi/`, `sv_pathlib_tests/`

## 2. Package Architecture

### sv_pathlib_define.svh

```systemverilog
// Default: no SV_PATHLIB_USE_DPI defined = VCS mode
// Compile with: +define+SV_PATHLIB_USE_DPI for DPI mode
```

### sv_pathlib_pkg.sv

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

## 3. Path Class API

```systemverilog
class Path;
  // === Path Parsing (pure SV, identical in both impl files) ===
  static function string name(string path);
  static function string stem(string path);
  static function string extension(string path);
  static function string parent(string path);
  static function string join_path(string base, string other);
  static function string with_name(string path, string new_name);
  static function string with_suffix(string path, string new_suffix);
  static function bit    is_absolute(string path);
  static function string resolve(string path);        // NEW

  // === File Checks ===
  static function bit    exists(string path);
  static function bit    is_file(string path);
  static function bit    is_dir(string path);
  static function bit    is_symlink(string path);
  static function bit    is_empty(string path);

  // === Directory Operations ===
  static function int    mkdir(string path);
  static function int    rmdir(string path);

  // === File I/O ===
  static function string read_text(string path);
  static function void   write_text(string path, string content);
  static function void   copy(string src, string dst);
  static function void   rename(string old_path, string new_path);
  static function void   unlink(string path);
  static function int    symlink(string target, string linkpath);

  // === File Metadata ===
  static function longint size(string path);
  static function longint modified(string path);
  static function stat_t  stat(string path);          // NEW

  // === Directory Traversal (NEW) ===
  static function queue<string> iterdir(string path);

  // === File Globbing (NEW) ===
  static function queue<string> glob(string path, string pattern);
  static function queue<string> rglob(string path, string pattern);

  // === System Info (NEW) ===
  static function string cwd();
endclass
```

## 4. New Functions - Python pathlib Mapping

| Python | sv_pathlib | VCS Mode | DPI Mode |
|---|---|---|---|
| `Path.cwd()` | `Path::cwd()` | `$system("pwd")` + temp file | DPI-C `getcwd()` |
| `Path.glob(pattern)` | `Path::glob(path, pattern)` | `$error` + return empty | DPI-C `opendir/readdir` + SV fnmatch |
| `Path.rglob(pattern)` | `Path::rglob(path, pattern)` | `$error` + return empty | Recursive glob via iterdir |
| `Path.iterdir()` | `Path::iterdir(path)` | `$system("ls -1")` + parse | DPI-C `opendir/readdir` |
| `Path.stat()` | `Path::stat(path)` | Temp file + `$system("stat")` | DPI-C `stat()` |
| `Path.resolve()` | `Path::resolve(path)` | Pure SV string processing | Pure SV (same as VCS) |

### stat_t struct

```systemverilog
typedef struct {
  longint st_size;    // File size in bytes
  longint st_mtime;   // Last modification time (Unix timestamp)
  longint st_atime;   // Last access time (Unix timestamp)
  longint st_ctime;   // Status change time (Unix timestamp)
  int     st_mode;    // File type + permissions (POSIX st_mode)
} stat_t;
```

Note: `st_mode` enables `S_ISREG()`, `S_ISDIR()`, `S_ISLNK()` checks without extra syscalls.

### resolve() logic

Pure SV, handles `..` and `.`:
- Input: `"/a/b/../c/./d"` -> Output: `"/a/c/d"`
- Input: `"a/b/../c"` -> Output: `"a/c"`
- Absolute paths stay absolute

### glob pattern matching rules

Aligned with Python `fnmatch`:
- `*` matches any characters except `/`
- `?` matches single character
- `[abc]` matches any character in bracket
- `[!abc]` matches any character not in bracket

Implementation: DPI layer only does `opendir/readdir`, pattern matching in SV layer.

## 5. DPI-C New Functions

```c
// sv_pathlib_dpi.cc new additions
int sv_pathlib_readdir(const char* path, char** result);
  // Read directory entries, return newline-separated filenames
  // Caller frees result. Returns 0 on success, -1 on error.

int sv_pathlib_getcwd(char* buf, int bufsize);
  // Get current working directory into buf. Returns 0 on success.

int sv_pathlib_stat(const char* path, long long* size,
                    long long* mtime, long long* atime,
                    long long* ctime, int* mode);
  // Get file stat info. Returns 0 on success, -1 on error.
```

Note: `readdir` returns newline-separated string (not pointer array) to simplify DPI-C interface. SV layer splits on `\n`.

## 6. Testing Plan

| Test File | Coverage |
|---|---|
| `test_path_parse.sv` | name, stem, extension, parent, join_path, with_name, with_suffix, is_absolute |
| `test_path_check.sv` | exists, is_file, is_dir, is_symlink, is_empty |
| `test_dir_ops.sv` | mkdir, rmdir, iterdir |
| `test_file_io.sv` | read_text, write_text |
| `test_file_ops.sv` | copy, rename, unlink, size, modified, symlink |
| `test_stat.sv` | stat (structured return) |
| `test_glob.sv` | glob, rglob (DPI mode only) |
| `test_resolve.sv` | resolve (.. and . resolution) |
| `test_cwd.sv` | cwd |

## 7. Makefile Adaptation

```makefile
# VCS mode (default)
test_path_parse:
    $(VERILATOR) $(VERILATOR_FLAGS) \
        src/sv_pathlib_pkg.sv \
        tests/test_path_parse.sv \
        tests/main_path_parse.cpp \
        --top-module test_path_parse \
        --Mdir obj_dir_path_parse \
        -o test_path_parse

# DPI mode
test_path_dpi:
    $(VERILATOR) $(VERILATOR_FLAGS) \
        +define+SV_PATHLIB_USE_DPI \
        src/sv_pathlib_pkg.sv \
        tests/test_path_parse.sv \
        tests/main_path_parse.cpp \
        src/dpi/sv_pathlib_dpi.cc \
        --top-module test_path_parse \
        --Mdir obj_dir_path_dpi \
        -o test_path_dpi
```

## 8. Implementation Order

1. Create `src/` directory structure
2. Write `sv_pathlib_define.svh`
3. Port path parsing to both impl files (copy from existing, identical)
4. Port VCS file operations to `sv_pathlib_vcs_impl.svh`
5. Port DPI file operations to `sv_pathlib_dpi_impl.svh`
6. Write `sv_pathlib_pkg.sv` top-level package
7. Add new functions: resolve, stat, cwd, iterdir, glob/rglob
8. Update DPI-C implementation file
9. Write tests for new functions
10. Update Makefile
11. Update README
12. Clean up old files
