# sv_pathlib

[中文文档](README_zh.md)

A Python [pathlib](https://docs.python.org/3/library/pathlib.html)-inspired path library for SystemVerilog, providing file checks, directory operations, file I/O, path parsing, and directory iteration with a clean static-method interface.

## Features

- **Unified API** — All operations via `Path::` static methods, backend-transparent
- **Path parsing** — `name()`, `stem()`, `extension()`, `parent()`, `join_path()`, `with_name()`, `with_suffix()`, `is_absolute()`, `resolve()`
- **File checks** — `exists()`, `is_file()`, `is_dir()`, `is_symlink()`, `is_empty()`
- **Directory ops** — `mkdir()`, `rmdir()`, `iterdir()`
- **File I/O** — `read_text()`, `write_text()`, `copy()`, `rename()`, `unlink()`
- **File stats** — `size()`, `modified()`, `stat()`
- **Pattern matching** — `glob()`, `rglob()` (DPI mode)
- **Utilities** — `cwd()`
- **Error handling** — `$warning()` reports errors without global state (fork/join safe)
- **Two backends** — VCS (zero-dependency, `$system` calls), DPI-C (high performance, POSIX)

## Project Structure

```
sv_pathlib/
  src/
    sv_pathlib_pkg.sv           -- Top-level package with backend selection
    sv_pathlib_define.svh       -- Macro definitions
    sv_pathlib_common.svh       -- Shared path parsing & file I/O (both backends)
    sv_pathlib_vcs_impl.svh     -- VCS backend implementation ($system)
    sv_pathlib_dpi_impl.svh     -- DPI backend implementation (DPI-C wrappers)
    dpi/
      sv_pathlib_dpi.cc         -- DPI-C implementation (POSIX)
  tests/                        -- Test suite
  Makefile                      -- Build & test automation
```

## Quick Start

Import the package and use the `Path::` interface:

```systemverilog
import sv_pathlib_pkg::*;  // VCS mode (default)

module example;
  initial begin
    // Path parsing
    $display("filename: %s", Path::name("/home/user/project/main.sv"));  // main.sv
    $display("stem:     %s", Path::stem("/home/user/project/main.sv"));  // main
    $display("ext:      %s", Path::extension("/home/user/project/main.sv")); // .sv
    $display("parent:   %s", Path::parent("/home/user/project/main.sv"));    // /home/user/project

    // Path joining and resolve
    string full = Path::join_path("/home/user", "project/src/main.sv");
    $display("full:     %s", full);  // /home/user/project/src/main.sv
    $display("resolved: %s", Path::resolve("/a/b/../c/./d"));  // /a/c/d

    // Directory operations
    void'(Path::mkdir("/tmp/my_project/src"));
    $display("is_dir: %b", Path::is_dir("/tmp/my_project/src"));

    // File I/O
    Path::write_text("/tmp/my_project/README.md", "# My Project");
    string content = Path::read_text("/tmp/my_project/README.md");

    // File stats
    $display("size: %0d bytes", Path::size("/tmp/my_project/README.md"));
    $display("mtime: %0d", Path::modified("/tmp/my_project/README.md"));

    // Directory iteration
    string entries = Path::iterdir("/tmp/my_project");

    // Current working directory
    $display("cwd: %s", Path::cwd());

    // Cleanup
    Path::unlink("/tmp/my_project/README.md");
    void'(Path::rmdir("/tmp/my_project/src"));
    void'(Path::rmdir("/tmp/my_project"));
  end
endmodule
```

### Error Handling

Errors are reported via `$warning()` — no global state, safe for fork/join concurrency.

```systemverilog
import sv_pathlib_pkg::*;

module example_error;
  initial begin
    string content;

    // Try to read a nonexistent file
    // $warning prints: "sv_pathlib: file not found: /tmp/nonexistent.txt"
    content = Path::read_text("/tmp/nonexistent.txt");

    // Try to copy a nonexistent source
    // $warning prints: "sv_pathlib: source file not found: /tmp/no_such_file.txt"
    Path::copy("/tmp/no_such_file.txt", "/tmp/dest.txt");
  end
endmodule
```

## Backend Selection

Use the `+define+SV_PATHLIB_USE_DPI` macro to select the DPI backend:

| Mode | Macro | Backend | Features |
|------|-------|---------|----------|
| VCS (default) | (none) | `$system` calls | All path ops, iterdir, stat, cwd |
| DPI | `+define+SV_PATHLIB_USE_DPI` | DPI-C (POSIX) | All VCS features + glob, rglob, better performance |

### VCS Mode (Default)

```bash
# Verilator
verilator --cc --exe --build -Isrc \
    src/sv_pathlib_pkg.sv your_module.sv your_main.cpp \
    --top-module your_module

# VCS
vcs -sverilog src/sv_pathlib_pkg.sv your_module.sv -full64
```

### DPI Mode

```bash
# Verilator
verilator --cc --exe --build -Isrc +define+SV_PATHLIB_USE_DPI \
    src/sv_pathlib_pkg.sv your_module.sv your_main.cpp \
    src/dpi/sv_pathlib_dpi.cc \
    --top-module your_module
```

## Building & Testing

### Requirements

- [Verilator](https://www.veripool.org/verilator/) v5.020+ (pip install recommended: `pip install verilator`)
- GCC/G++ (for DPI backend)

### Build System

| Makefile | Usage |
|----------|-------|
| `Makefile` | `make <target>` (wrapper, recommended) |
| `Makefile.verilator` | `make -f Makefile.verilator <target>` (direct) |

### Run All Tests

```bash
make test_all          # Run all tests (VCS backend + DPI backend)
make test_vcs_all      # Run VCS backend mode tests ($system)
make test_dpi_all      # Run DPI backend mode tests (DPI-C)
```

### Run Individual Tests

```bash
make -f Makefile.verilator test_vcs_path_parse   # VCS backend mode
make -f Makefile.verilator test_dpi_glob          # DPI backend mode
```

### Clean Build Artifacts

```bash
make test_clean    # Remove obj_dir_* build directories
make clean         # Remove all build artifacts
```

## API Reference

### Path Class

All methods are static — call via `Path::method_name()`.

#### Path Parsing

| Method | Signature | Description |
|--------|-----------|-------------|
| `name` | `static string name(string path)` | Get filename from path |
| `stem` | `static string stem(string path)` | Get filename without extension |
| `extension` | `static string extension(string path)` | Get file extension (including `.`) |
| `parent` | `static string parent(string path)` | Get parent directory |
| `join_path` | `static string join_path(string base, string other)` | Join two path segments |
| `with_name` | `static string with_name(string path, string new_name)` | Replace filename |
| `with_suffix` | `static string with_suffix(string path, string new_suffix)` | Replace extension |
| `is_absolute` | `static bit is_absolute(string path)` | Check if path is absolute |
| `resolve` | `static string resolve(string path)` | Resolve `.` and `..` components |

#### File Operations

| Method | Signature | Description |
|--------|-----------|-------------|
| `exists` | `static bit exists(string path)` | Check if path exists |
| `is_file` | `static bit is_file(string path)` | Check if path is a regular file |
| `is_dir` | `static bit is_dir(string path)` | Check if path is a directory |
| `is_symlink` | `static bit is_symlink(string path)` | Check if path is a symlink |
| `is_empty` | `static bit is_empty(string path)` | Check if file is empty |
| `mkdir` | `static int mkdir(string path)` | Create directory (recursive with `-p`), returns 0 on success |
| `rmdir` | `static int rmdir(string path)` | Remove empty directory, returns 0 on success |
| `read_text` | `static string read_text(string path)` | Read file as string |
| `write_text` | `static void write_text(string path, string content)` | Write string to file |
| `copy` | `static void copy(string src, string dst)` | Copy file |
| `rename` | `static void rename(string old_path, string new_path)` | Rename / move file |
| `unlink` | `static void unlink(string path)` | Delete file |
| `symlink` | `static int symlink(string target, string linkpath)` | Create symbolic link |
| `size` | `static longint size(string path)` | Get file size in bytes (-1 if not found) |
| `modified` | `static longint modified(string path)` | Get last modification time (unix timestamp) |
| `stat` | `static stat_t stat(string path)` | Get full stat info (size, mtime, atime, ctime, mode) |
| `iterdir` | `static string iterdir(string path)` | List directory entries (newline-separated) |
| `cwd` | `static string cwd()` | Get current working directory |

#### Pattern Matching (DPI mode only)

| Method | Signature | Description |
|--------|-----------|-------------|
| `glob` | `static string glob(string path, string pattern)` | Non-recursive pattern matching |
| `rglob` | `static string rglob(string path, string pattern)` | Recursive pattern matching |

### stat_t Struct

```systemverilog
typedef struct {
  longint st_size;    // File size in bytes
  longint st_mtime;   // Last modification time
  longint st_atime;   // Last access time
  longint st_ctime;   // Last status change time
  int     st_mode;    // File mode (permissions)
} stat_t;
```

## License

MIT
