# sv_pathlib

[中文文档](README_zh.md)

A Python [pathlib](https://docs.python.org/3/library/pathlib.html)-inspired path library for SystemVerilog, providing file checks, directory operations, file I/O, and path parsing with a clean static-method interface.

## Features

- **Path parsing** — `name()`, `stem()`, `extension()`, `parent()`, `join_path()`, `with_name()`, `with_suffix()`, `is_absolute()`
- **File checks** — `exists()`, `is_file()`, `is_dir()`, `is_symlink()`, `is_empty()`
- **Directory ops** — `mkdir()`, `rmdir()`
- **File I/O** — `read_text()`, `write_text()`, `copy()`, `rename()`, `unlink()`
- **File stats** — `size()`, `modified()`
- **Error handling** — `get_last_error()`, `get_last_error_code()`, `clear_error()`
- **Two backends** — DPI-C (high performance) and $system (simple integration)

## Project Structure

```
sv_pathlib/
  sv_pathlib_pkg.sv            -- Package (includes Path class)
  path.sv                      -- Path class with static methods
  sv_pathlib_dpi/
    path_dpi.sv                -- DPI backend (wrapper)
    path_dpi_impl.cc           -- DPI-C implementation (POSIX)
    dpi_system.c               -- C wrapper for system()
  sv_pathlib_sys/
    path_sys.sv                -- $system backend
  sv_pathlib_tests/            -- Test suite (81 assertions)
  Makefile                     -- Build & test automation
```

## Quick Start

### Path Parsing (no backend needed)

```systemverilog
import sv_pathlib_pkg::*;

module example;
  initial begin
    $display("filename: %s", Path::name("/home/user/project/main.sv"));  // main.sv
    $display("stem:     %s", Path::stem("/home/user/project/main.sv"));  // main
    $display("ext:      %s", Path::extension("/home/user/project/main.sv")); // .sv
    $display("parent:   %s", Path::parent("/home/user/project/main.sv"));    // /home/user/project

    // Path joining
    string full = Path::join_path("/home/user", "project/src/main.sv");
    $display("full:     %s", full);  // /home/user/project/src/main.sv

    // Replace name / suffix
    $display("new name: %s", Path::with_name("/tmp/old.txt", "new.txt"));    // /tmp/new.txt
    $display("new ext:  %s", Path::with_suffix("/tmp/file.txt", ".sv"));     // /tmp/file.sv

    // Absolute check
    $display("absolute: %b", Path::is_absolute("/tmp/test"));  // 1
    $display("absolute: %b", Path::is_absolute("tmp/test"));   // 0
  end
endmodule
```

### File & Directory Operations

#### $system Backend

```systemverilog
import path_sys::*;

module example_sys;
  initial begin
    // Directory operations
    void'(path_sys::mkdir("/tmp/my_project/src"));
    $display("dir exists: %b", path_sys::is_dir("/tmp/my_project/src"));

    // File I/O
    path_sys::write_text("/tmp/my_project/README.md", "# My Project");
    string content = path_sys::read_text("/tmp/my_project/README.md");
    $display("content: %s", content);

    // File checks
    $display("exists:  %b", path_sys::exists("/tmp/my_project/README.md"));
    $display("is_file: %b", path_sys::is_file("/tmp/my_project/README.md"));
    $display("is_empty: %b", path_sys::is_empty("/tmp/my_project/README.md"));

    // File operations
    path_sys::copy("/tmp/my_project/README.md", "/tmp/my_project/README.bak");
    path_sys::rename("/tmp/my_project/README.bak", "/tmp/my_project/README.old");
    $display("size: %0d bytes", path_sys::size("/tmp/my_project/README.md"));

    // Cleanup
    path_sys::unlink("/tmp/my_project/README.md");
    path_sys::unlink("/tmp/my_project/README.old");
    void'(path_sys::rmdir("/tmp/my_project/src"));
    void'(path_sys::rmdir("/tmp/my_project"));
  end
endmodule
```

#### DPI Backend

```systemverilog
import path_dpi::*;

module example_dpi;
  initial begin
    // Same API as path_sys, but uses DPI-C for better performance
    void'(path_dpi::mkdir("/tmp/my_project/src"));
    path_dpi::write_text("/tmp/my_project/data.txt", "hello");
    $display("size: %0d", path_dpi::size("/tmp/my_project/data.txt"));

    // DPI-specific: create symbolic link
    void'(path_dpi::symlink("/tmp/my_project/data.txt", "/tmp/my_project/link.txt"));
    $display("is symlink: %b", path_dpi::is_symlink("/tmp/my_project/link.txt"));
  end
endmodule
```

### Error Handling

```systemverilog
import path_sys::*;

module example_error;
  initial begin
    string content;

    // Try to read a nonexistent file
    content = path_sys::read_text("/tmp/nonexistent.txt");
    if (path_sys::get_last_error_code() != 0) begin
      $display("Error: %s", path_sys::get_last_error());
    end

    // Clear error state before next operation
    path_sys::clear_error();

    // Try to copy a nonexistent source
    path_sys::copy("/tmp/no_such_file.txt", "/tmp/dest.txt");
    if (path_sys::get_last_error_code() != 0) begin
      $display("Error: %s", path_sys::get_last_error());
    end
  end
endmodule
```

### Combining Path Parsing with File Ops

```systemverilog
import sv_pathlib_pkg::*;
import path_sys::*;

module example_combined;
  initial begin
    string base_dir = "/tmp/project";
    string src_file = Path::join_path(base_dir, "src/main.sv");
    string backup  = Path::with_suffix(src_file, ".sv.bak");

    // Ensure directory exists
    void'(path_sys::mkdir(Path::parent(src_file)));

    // Write file
    path_sys::write_text(src_file, "module main; endmodule");

    // Backup
    path_sys::copy(src_file, backup);

    // Verify
    $display("src exists:  %b", path_sys::exists(src_file));
    $display("backup ext:  %s", Path::extension(backup));  // .sv.bak
    $display("src size:    %0d bytes", path_sys::size(src_file));

    // Cleanup
    path_sys::unlink(src_file);
    path_sys::unlink(backup);
  end
endmodule
```

## Backend Comparison

| Feature | path_sys ($system) | path_dpi (DPI-C) |
|---------|-------------------|------------------|
| Setup | Import only | Requires DPI compilation |
| Performance | Lower (shell calls) | Higher (direct POSIX) |
| Platform | Linux | Linux / Unix |
| Symbolic links | Not supported | `symlink()` supported |
| Dependency | None | C++ compiler |

### Choosing a Backend

- **Use `path_sys`** when you want simple integration with no extra build steps
- **Use `path_dpi`** when you need better performance or symbolic link support

## Building & Testing

### Requirements

- [Verilator](https://www.veripool.org/verilator/) (tested with v5.020)
- GCC/G++ (for DPI backend)

### Run All Tests

```bash
make test_all
```

### Run Individual Tests

```bash
make test_path_parse      # Path parsing (no backend)
make test_path_check_sys  # File checks (system backend)
make test_dir_ops_sys     # Directory operations
make test_file_io_sys     # File I/O
make test_file_ops_sys    # File operations
make test_error_sys       # Error handling
make test_path_dpi        # DPI backend
make test_unified         # Combined usage
```

### Clean Build Artifacts

```bash
make clean
```

## API Reference

### Path Class (`sv_pathlib_pkg`)

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

### path_sys / path_dpi Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `exists` | `bit exists(string path)` | Check if path exists |
| `is_file` | `bit is_file(string path)` | Check if path is a regular file |
| `is_dir` | `bit is_dir(string path)` | Check if path is a directory |
| `is_symlink` | `bit is_symlink(string path)` | Check if path is a symlink (DPI only) |
| `is_empty` | `bit is_empty(string path)` | Check if file is empty |
| `mkdir` | `int mkdir(string path)` | Create directory (recursive with `-p`) |
| `rmdir` | `int rmdir(string path)` | Remove empty directory |
| `read_text` | `string read_text(string path)` | Read file as string |
| `write_text` | `void write_text(string path, string content)` | Write string to file |
| `copy` | `void copy(string src, string dst)` | Copy file |
| `rename` | `void rename(string old_path, string new_path)` | Rename / move file |
| `unlink` | `void unlink(string path)` | Delete file |
| `size` | `longint size(string path)` | Get file size in bytes (-1 if not found) |
| `modified` | `longint modified(string path)` | Get last modification time (unix timestamp) |
| `symlink` | `int symlink(string target, string linkpath)` | Create symbolic link (DPI only) |

### Error Handling (path_sys only)

| Function | Signature | Description |
|----------|-----------|-------------|
| `get_last_error` | `string get_last_error()` | Get last error message |
| `get_last_error_code` | `int get_last_error_code()` | Get last error code (0 = OK) |
| `clear_error` | `void clear_error()` | Clear error state |

## Integration

### Option 1: Path parsing only (no backend)

```makefile
VERILATOR_FLAGS = --cc --exe --build

your_target:
    $(VERILATOR) $(VERILATOR_FLAGS) \
        sv_pathlib_pkg.sv path.sv \
        your_module.sv \
        your_main.cpp \
        --top-module your_module
```

### Option 2: With $system backend

```makefile
your_target:
    $(VERILATOR) $(VERILATOR_FLAGS) \
        sv_pathlib_pkg.sv path.sv \
        sv_pathlib_sys/path_sys.sv \
        your_module.sv \
        your_main.cpp \
        sv_pathlib_dpi/dpi_system.c \
        --top-module your_module
```

### Option 3: With DPI backend

```makefile
your_target:
    $(VERILATOR) $(VERILATOR_FLAGS) \
        sv_pathlib_dpi/path_dpi.sv \
        your_module.sv \
        your_main.cpp \
        sv_pathlib_dpi/path_dpi_impl.cc \
        --top-module your_module
```

## License

MIT
