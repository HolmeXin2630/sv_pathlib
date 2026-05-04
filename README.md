# sv_pathlib

[中文文档](README_zh.md)

A Python [pathlib](https://docs.python.org/3/library/pathlib.html)-inspired path library for SystemVerilog, providing file checks, directory operations, file I/O, and path parsing with a clean static-method interface.

## Features

- **Unified API** — All operations via `Path::` static methods, backend-transparent
- **Path parsing** — `name()`, `stem()`, `extension()`, `parent()`, `join_path()`, `with_name()`, `with_suffix()`, `is_absolute()`
- **File checks** — `exists()`, `is_file()`, `is_dir()`, `is_symlink()`, `is_empty()`
- **Directory ops** — `mkdir()`, `rmdir()`
- **File I/O** — `read_text()`, `write_text()`, `copy()`, `rename()`, `unlink()`
- **File stats** — `size()`, `modified()`
- **Error handling** — `get_last_error()`, `get_last_error_code()`, `clear_error()`
- **Three backends** — VCS (zero-dependency), $system (simple integration), DPI-C (high performance)

## Project Structure

```
sv_pathlib/
  sv_pathlib_vcs_pkg.sv        -- VCS backend package (zero DPI dependency)
  sv_pathlib_sys_pkg.sv        -- $system backend package (requires dpi_system.c)
  sv_pathlib_dpi_pkg.sv        -- DPI backend package (requires path_dpi_impl.cc)
  sv_pathlib_dpi/
    path_dpi_impl.cc           -- DPI-C implementation (POSIX)
    dpi_system.c               -- C wrapper for system()
  sv_pathlib_tests/            -- Test suite (81 assertions)
  Makefile                     -- Build & test automation
```

## Quick Start

Just pick one backend package and import it:

```systemverilog
// Option A: VCS backend (zero DPI dependency, recommended for VCS)
import sv_pathlib_vcs_pkg::*;

// Option B: $system backend (simple integration, requires dpi_system.c)
import sv_pathlib_sys_pkg::*;

// Option C: DPI backend (better performance, requires path_dpi_impl.cc)
import sv_pathlib_dpi_pkg::*;
```

Then use the same `Path::` interface for everything:

```systemverilog
import sv_pathlib_sys_pkg::*;

module example;
  initial begin
    // Path parsing
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

    // Directory operations
    void'(Path::mkdir("/tmp/my_project/src"));
    $display("is_dir: %b", Path::is_dir("/tmp/my_project/src"));

    // File I/O
    Path::write_text("/tmp/my_project/README.md", "# My Project");
    string content = Path::read_text("/tmp/my_project/README.md");
    $display("content: %s", content);

    // File checks
    $display("exists:   %b", Path::exists("/tmp/my_project/README.md"));
    $display("is_file:  %b", Path::is_file("/tmp/my_project/README.md"));
    $display("is_empty: %b", Path::is_empty("/tmp/my_project/README.md"));

    // File operations
    Path::copy("/tmp/my_project/README.md", "/tmp/my_project/README.bak");
    Path::rename("/tmp/my_project/README.bak", "/tmp/my_project/README.old");
    $display("size: %0d bytes", Path::size("/tmp/my_project/README.md"));

    // Cleanup
    Path::unlink("/tmp/my_project/README.md");
    Path::unlink("/tmp/my_project/README.old");
    void'(Path::rmdir("/tmp/my_project/src"));
    void'(Path::rmdir("/tmp/my_project"));
  end
endmodule
```

### Error Handling

```systemverilog
import sv_pathlib_sys_pkg::*;

module example_error;
  initial begin
    string content;

    // Try to read a nonexistent file
    content = Path::read_text("/tmp/nonexistent.txt");
    if (Path::get_last_error_code() != 0) begin
      $display("Error: %s", Path::get_last_error());
    end

    // Clear error state before next operation
    Path::clear_error();

    // Try to copy a nonexistent source
    Path::copy("/tmp/no_such_file.txt", "/tmp/dest.txt");
    if (Path::get_last_error_code() != 0) begin
      $display("Error: %s", Path::get_last_error());
    end
  end
endmodule
```

### Combining Path Parsing with File Ops

```systemverilog
import sv_pathlib_sys_pkg::*;

module example_combined;
  initial begin
    string base_dir = "/tmp/project";
    string src_file = Path::join_path(base_dir, "src/main.sv");
    string backup  = Path::with_suffix(src_file, ".sv.bak");

    // Ensure directory exists
    void'(Path::mkdir(Path::parent(src_file)));

    // Write file
    Path::write_text(src_file, "module main; endmodule");

    // Backup
    Path::copy(src_file, backup);

    // Verify
    $display("src exists:  %b", Path::exists(src_file));
    $display("backup ext:  %s", Path::extension(backup));  // .sv.bak
    $display("src size:    %0d bytes", Path::size(src_file));

    // Cleanup
    Path::unlink(src_file);
    Path::unlink(backup);
  end
endmodule
```

## Backend Comparison

| Feature | sv_pathlib_vcs_pkg (VCS) | sv_pathlib_sys_pkg ($system) | sv_pathlib_dpi_pkg (DPI-C) |
|---------|--------------------------|------------------------------|----------------------------|
| Setup | Import only | Requires dpi_system.c | Requires path_dpi_impl.cc |
| Performance | Lower (shell calls) | Lower (shell calls) | Higher (direct POSIX) |
| Platform | Linux | Linux | Linux / Unix |
| Symbolic links | Not supported | Not supported | `symlink()` supported |
| Error handling | Supported | Supported | Not supported |
| Dependency | None | C file | C++ compiler |
| VCS compatible | Yes | Yes (needs DPI compile) | Yes (needs DPI compile) |

### Choosing a Backend

- **Use `sv_pathlib_vcs_pkg`** for VCS projects where you want zero external dependencies
- **Use `sv_pathlib_sys_pkg`** for Verilator projects with simple integration needs
- **Use `sv_pathlib_dpi_pkg`** when you need better performance or symbolic link support

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
make test_path_parse      # Path parsing
make test_path_check_sys  # File checks
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

#### File Operations

| Method | Signature | Description |
|--------|-----------|-------------|
| `exists` | `static bit exists(string path)` | Check if path exists |
| `is_file` | `static bit is_file(string path)` | Check if path is a regular file |
| `is_dir` | `static bit is_dir(string path)` | Check if path is a directory |
| `is_symlink` | `static bit is_symlink(string path)` | Check if path is a symlink |
| `is_empty` | `static bit is_empty(string path)` | Check if file is empty |
| `mkdir` | `static int mkdir(string path)` | Create directory (recursive with `-p`) |
| `rmdir` | `static int rmdir(string path)` | Remove empty directory |
| `read_text` | `static string read_text(string path)` | Read file as string |
| `write_text` | `static void write_text(string path, string content)` | Write string to file |
| `copy` | `static void copy(string src, string dst)` | Copy file |
| `rename` | `static void rename(string old_path, string new_path)` | Rename / move file |
| `unlink` | `static void unlink(string path)` | Delete file |
| `size` | `static longint size(string path)` | Get file size in bytes (-1 if not found) |
| `modified` | `static longint modified(string path)` | Get last modification time (unix timestamp) |
| `symlink` | `static int symlink(string target, string linkpath)` | Create symbolic link (DPI only) |

#### Error Handling

| Method | Signature | Description |
|--------|-----------|-------------|
| `get_last_error` | `static string get_last_error()` | Get last error message |
| `get_last_error_code` | `static int get_last_error_code()` | Get last error code (0 = OK) |
| `clear_error` | `static void clear_error()` | Clear error state |

## Integration

### Option 1: VCS (zero DPI dependency)

```bash
vcs -sverilog sv_pathlib_vcs_pkg.sv your_module.sv -full64
./simv
```

### Option 2: $system backend (Verilator)

```makefile
your_target:
    $(VERILATOR) $(VERILATOR_FLAGS) \
        sv_pathlib_sys_pkg.sv \
        your_module.sv \
        your_main.cpp \
        sv_pathlib_dpi/dpi_system.c \
        --top-module your_module
```

### Option 3: DPI backend (Verilator)

```makefile
your_target:
    $(VERILATOR) $(VERILATOR_FLAGS) \
        sv_pathlib_dpi_pkg.sv \
        your_module.sv \
        your_main.cpp \
        sv_pathlib_dpi/path_dpi_impl.cc \
        --top-module your_module
```

## License

MIT
