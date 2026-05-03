# sv_pathlib

仿照 Python [pathlib](https://docs.python.org/3/library/pathlib.html) 的 SystemVerilog 路径操作库，提供文件判断、目录操作、文件读写和路径解析功能，采用简洁的静态方法接口。

## 功能特性

- **路径解析** — `name()`、`stem()`、`extension()`、`parent()`、`join_path()`、`with_name()`、`with_suffix()`、`is_absolute()`
- **文件判断** — `exists()`、`is_file()`、`is_dir()`、`is_symlink()`、`is_empty()`
- **目录操作** — `mkdir()`、`rmdir()`
- **文件读写** — `read_text()`、`write_text()`、`copy()`、`rename()`、`unlink()`
- **文件信息** — `size()`、`modified()`
- **错误处理** — `get_last_error()`、`get_last_error_code()`、`clear_error()`
- **两种后端** — DPI-C（高性能）和 $system（集成简单）

## 目录结构

```
sv_pathlib/
  sv_pathlib_pkg.sv            -- 包定义（包含 Path 类）
  path.sv                      -- Path 类，提供静态方法
  sv_pathlib_dpi/
    path_dpi.sv                -- DPI 后端（SV 封装）
    path_dpi_impl.cc           -- DPI-C 实现（POSIX 系统调用）
    dpi_system.c               -- C 封装的 system() 函数
  sv_pathlib_sys/
    path_sys.sv                -- $system 后端
  sv_pathlib_tests/            -- 测试套件（81 个断言）
  Makefile                     -- 构建与测试自动化
```

## 快速上手

### 路径解析（无需后端）

```systemverilog
import sv_pathlib_pkg::*;

module example;
  initial begin
    $display("文件名: %s", Path::name("/home/user/project/main.sv"));     // main.sv
    $display("主名:   %s", Path::stem("/home/user/project/main.sv"));     // main
    $display("扩展名: %s", Path::extension("/home/user/project/main.sv"));// .sv
    $display("父目录: %s", Path::parent("/home/user/project/main.sv"));   // /home/user/project

    // 路径拼接
    string full = Path::join_path("/home/user", "project/src/main.sv");
    $display("完整路径: %s", full);  // /home/user/project/src/main.sv

    // 替换文件名 / 扩展名
    $display("新文件名: %s", Path::with_name("/tmp/old.txt", "new.txt"));  // /tmp/new.txt
    $display("新扩展名: %s", Path::with_suffix("/tmp/file.txt", ".sv"));  // /tmp/file.sv

    // 判断是否为绝对路径
    $display("绝对路径: %b", Path::is_absolute("/tmp/test"));  // 1
    $display("绝对路径: %b", Path::is_absolute("tmp/test"));   // 0
  end
endmodule
```

### 文件与目录操作

#### $system 后端

```systemverilog
import path_sys::*;

module example_sys;
  initial begin
    // 目录操作
    void'(path_sys::mkdir("/tmp/my_project/src"));
    $display("目录存在: %b", path_sys::is_dir("/tmp/my_project/src"));

    // 文件读写
    path_sys::write_text("/tmp/my_project/README.md", "# My Project");
    string content = path_sys::read_text("/tmp/my_project/README.md");
    $display("文件内容: %s", content);

    // 文件判断
    $display("存在: %b", path_sys::exists("/tmp/my_project/README.md"));
    $display("是文件: %b", path_sys::is_file("/tmp/my_project/README.md"));
    $display("为空: %b", path_sys::is_empty("/tmp/my_project/README.md"));

    // 文件操作
    path_sys::copy("/tmp/my_project/README.md", "/tmp/my_project/README.bak");
    path_sys::rename("/tmp/my_project/README.bak", "/tmp/my_project/README.old");
    $display("文件大小: %0d 字节", path_sys::size("/tmp/my_project/README.md"));

    // 清理
    path_sys::unlink("/tmp/my_project/README.md");
    path_sys::unlink("/tmp/my_project/README.old");
    void'(path_sys::rmdir("/tmp/my_project/src"));
    void'(path_sys::rmdir("/tmp/my_project"));
  end
endmodule
```

#### DPI 后端

```systemverilog
import path_dpi::*;

module example_dpi;
  initial begin
    // 与 path_sys 相同的 API，但使用 DPI-C 获得更高性能
    void'(path_dpi::mkdir("/tmp/my_project/src"));
    path_dpi::write_text("/tmp/my_project/data.txt", "hello");
    $display("文件大小: %0d", path_dpi::size("/tmp/my_project/data.txt"));

    // DPI 特有功能：创建符号链接
    void'(path_dpi::symlink("/tmp/my_project/data.txt", "/tmp/my_project/link.txt"));
    $display("是符号链接: %b", path_dpi::is_symlink("/tmp/my_project/link.txt"));
  end
endmodule
```

### 错误处理

```systemverilog
import path_sys::*;

module example_error;
  initial begin
    string content;

    // 尝试读取不存在的文件
    content = path_sys::read_text("/tmp/nonexistent.txt");
    if (path_sys::get_last_error_code() != 0) begin
      $display("错误: %s", path_sys::get_last_error());
    end

    // 清除错误状态后再执行下一个操作
    path_sys::clear_error();

    // 尝试复制不存在的源文件
    path_sys::copy("/tmp/no_such_file.txt", "/tmp/dest.txt");
    if (path_sys::get_last_error_code() != 0) begin
      $display("错误: %s", path_sys::get_last_error());
    end
  end
endmodule
```

### 路径解析与文件操作结合使用

```systemverilog
import sv_pathlib_pkg::*;
import path_sys::*;

module example_combined;
  initial begin
    string base_dir = "/tmp/project";
    string src_file = Path::join_path(base_dir, "src/main.sv");
    string backup  = Path::with_suffix(src_file, ".sv.bak");

    // 确保目录存在
    void'(path_sys::mkdir(Path::parent(src_file)));

    // 写入文件
    path_sys::write_text(src_file, "module main; endmodule");

    // 备份
    path_sys::copy(src_file, backup);

    // 验证
    $display("源文件存在: %b", path_sys::exists(src_file));
    $display("备份扩展名: %s", Path::extension(backup));  // .sv.bak
    $display("源文件大小: %0d 字节", path_sys::size(src_file));

    // 清理
    path_sys::unlink(src_file);
    path_sys::unlink(backup);
  end
endmodule
```

## 后端对比

| 特性 | path_sys ($system) | path_dpi (DPI-C) |
|------|-------------------|------------------|
| 集成方式 | 仅需 import | 需要 DPI 编译 |
| 性能 | 较低（shell 调用） | 较高（直接 POSIX 调用） |
| 平台 | Linux | Linux / Unix |
| 符号链接 | 不支持 | 支持 `symlink()` |
| 依赖 | 无 | C++ 编译器 |

### 如何选择后端

- **选择 `path_sys`**：想要简单集成，不需要额外编译步骤
- **选择 `path_dpi`**：需要更好的性能或符号链接支持

## 构建与测试

### 环境要求

- [Verilator](https://www.veripool.org/verilator/)（已在 v5.020 上测试通过）
- GCC/G++（DPI 后端需要）

### 运行全部测试

```bash
make test_all
```

### 运行单个测试

```bash
make test_path_parse      # 路径解析（无需后端）
make test_path_check_sys  # 文件判断（system 后端）
make test_dir_ops_sys     # 目录操作
make test_file_io_sys     # 文件读写
make test_file_ops_sys    # 文件操作
make test_error_sys       # 错误处理
make test_path_dpi        # DPI 后端
make test_unified         # 综合使用
```

### 清理构建产物

```bash
make clean
```

## API 参考

### Path 类（`sv_pathlib_pkg`）

| 方法 | 签名 | 说明 |
|------|------|------|
| `name` | `static string name(string path)` | 获取文件名 |
| `stem` | `static string stem(string path)` | 获取不含扩展名的文件名 |
| `extension` | `static string extension(string path)` | 获取扩展名（含 `.`） |
| `parent` | `static string parent(string path)` | 获取父目录 |
| `join_path` | `static string join_path(string base, string other)` | 拼接两个路径 |
| `with_name` | `static string with_name(string path, string new_name)` | 替换文件名 |
| `with_suffix` | `static string with_suffix(string path, string new_suffix)` | 替换扩展名 |
| `is_absolute` | `static bit is_absolute(string path)` | 判断是否为绝对路径 |

### path_sys / path_dpi 函数

| 函数 | 签名 | 说明 |
|------|------|------|
| `exists` | `bit exists(string path)` | 判断路径是否存在 |
| `is_file` | `bit is_file(string path)` | 判断是否为普通文件 |
| `is_dir` | `bit is_dir(string path)` | 判断是否为目录 |
| `is_symlink` | `bit is_symlink(string path)` | 判断是否为符号链接（仅 DPI） |
| `is_empty` | `bit is_empty(string path)` | 判断文件是否为空 |
| `mkdir` | `int mkdir(string path)` | 创建目录（递归，相当于 `mkdir -p`） |
| `rmdir` | `int rmdir(string path)` | 删除空目录 |
| `read_text` | `string read_text(string path)` | 读取文件内容为字符串 |
| `write_text` | `void write_text(string path, string content)` | 将字符串写入文件 |
| `copy` | `void copy(string src, string dst)` | 复制文件 |
| `rename` | `void rename(string old_path, string new_path)` | 重命名 / 移动文件 |
| `unlink` | `void unlink(string path)` | 删除文件 |
| `size` | `longint size(string path)` | 获取文件大小（字节），不存在返回 -1 |
| `modified` | `longint modified(string path)` | 获取最后修改时间（unix 时间戳） |
| `symlink` | `int symlink(string target, string linkpath)` | 创建符号链接（仅 DPI） |

### 错误处理（仅 path_sys）

| 函数 | 签名 | 说明 |
|------|------|------|
| `get_last_error` | `string get_last_error()` | 获取最后的错误信息 |
| `get_last_error_code` | `int get_last_error_code()` | 获取最后的错误码（0 = 成功） |
| `clear_error` | `void clear_error()` | 清除错误状态 |

## 集成方式

### 方式一：仅使用路径解析（无需后端）

```makefile
VERILATOR_FLAGS = --cc --exe --build

your_target:
    $(VERILATOR) $(VERILATOR_FLAGS) \
        sv_pathlib_pkg.sv path.sv \
        your_module.sv \
        your_main.cpp \
        --top-module your_module
```

### 方式二：使用 $system 后端

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

### 方式三：使用 DPI 后端

```makefile
your_target:
    $(VERILATOR) $(VERILATOR_FLAGS) \
        sv_pathlib_dpi/path_dpi.sv \
        your_module.sv \
        your_main.cpp \
        sv_pathlib_dpi/path_dpi_impl.cc \
        --top-module your_module
```

## 许可证

MIT
