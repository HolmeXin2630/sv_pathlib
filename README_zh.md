# sv_pathlib

[English](README.md)

仿照 Python [pathlib](https://docs.python.org/3/library/pathlib.html) 的 SystemVerilog 路径操作库，提供文件判断、目录操作、文件读写和路径解析功能，采用简洁的静态方法接口。

## 功能特性

- **统一接口** — 所有操作通过 `Path::` 静态方法调用，与后端无关
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
  sv_pathlib_sys_pkg.sv        -- $system 后端包（完整 Path 类）
  sv_pathlib_dpi_pkg.sv        -- DPI 后端包（完整 Path 类）
  sv_pathlib_dpi/
    path_dpi_impl.cc           -- DPI-C 实现（POSIX 系统调用）
    dpi_system.c               -- C 封装的 system() 函数
  sv_pathlib_tests/            -- 测试套件（81 个断言）
  Makefile                     -- 构建与测试自动化
```

## 快速上手

只需选择一个后端包并 import：

```systemverilog
// 方式 A：$system 后端（集成简单）
import sv_pathlib_sys_pkg::*;

// 方式 B：DPI 后端（性能更好）
import sv_pathlib_dpi_pkg::*;
```

然后使用统一的 `Path::` 接口：

```systemverilog
import sv_pathlib_sys_pkg::*;

module example;
  initial begin
    // 路径解析
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

    // 目录操作
    void'(Path::mkdir("/tmp/my_project/src"));
    $display("是目录: %b", Path::is_dir("/tmp/my_project/src"));

    // 文件读写
    Path::write_text("/tmp/my_project/README.md", "# My Project");
    string content = Path::read_text("/tmp/my_project/README.md");
    $display("文件内容: %s", content);

    // 文件判断
    $display("存在: %b", Path::exists("/tmp/my_project/README.md"));
    $display("是文件: %b", Path::is_file("/tmp/my_project/README.md"));
    $display("为空: %b", Path::is_empty("/tmp/my_project/README.md"));

    // 文件操作
    Path::copy("/tmp/my_project/README.md", "/tmp/my_project/README.bak");
    Path::rename("/tmp/my_project/README.bak", "/tmp/my_project/README.old");
    $display("文件大小: %0d 字节", Path::size("/tmp/my_project/README.md"));

    // 清理
    Path::unlink("/tmp/my_project/README.md");
    Path::unlink("/tmp/my_project/README.old");
    void'(Path::rmdir("/tmp/my_project/src"));
    void'(Path::rmdir("/tmp/my_project"));
  end
endmodule
```

### 错误处理

```systemverilog
import sv_pathlib_sys_pkg::*;

module example_error;
  initial begin
    string content;

    // 尝试读取不存在的文件
    content = Path::read_text("/tmp/nonexistent.txt");
    if (Path::get_last_error_code() != 0) begin
      $display("错误: %s", Path::get_last_error());
    end

    // 清除错误状态后再执行下一个操作
    Path::clear_error();

    // 尝试复制不存在的源文件
    Path::copy("/tmp/no_such_file.txt", "/tmp/dest.txt");
    if (Path::get_last_error_code() != 0) begin
      $display("错误: %s", Path::get_last_error());
    end
  end
endmodule
```

### 路径解析与文件操作结合使用

```systemverilog
import sv_pathlib_sys_pkg::*;

module example_combined;
  initial begin
    string base_dir = "/tmp/project";
    string src_file = Path::join_path(base_dir, "src/main.sv");
    string backup  = Path::with_suffix(src_file, ".sv.bak");

    // 确保目录存在
    void'(Path::mkdir(Path::parent(src_file)));

    // 写入文件
    Path::write_text(src_file, "module main; endmodule");

    // 备份
    Path::copy(src_file, backup);

    // 验证
    $display("源文件存在: %b", Path::exists(src_file));
    $display("备份扩展名: %s", Path::extension(backup));  // .sv.bak
    $display("源文件大小: %0d 字节", Path::size(src_file));

    // 清理
    Path::unlink(src_file);
    Path::unlink(backup);
  end
endmodule
```

## 后端对比

| 特性 | sv_pathlib_sys_pkg ($system) | sv_pathlib_dpi_pkg (DPI-C) |
|------|------------------------------|----------------------------|
| 集成方式 | 仅需 import | 需要 DPI 编译 |
| 性能 | 较低（shell 调用） | 较高（直接 POSIX 调用） |
| 平台 | Linux | Linux / Unix |
| 符号链接 | 不支持 | 支持 `symlink()` |
| 错误处理 | 支持 | 不支持 |
| 依赖 | 无 | C++ 编译器 |

### 如何选择后端

- **选择 `sv_pathlib_sys_pkg`**：想要简单集成，不需要额外编译步骤
- **选择 `sv_pathlib_dpi_pkg`**：需要更好的性能或符号链接支持

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
make test_path_parse      # 路径解析
make test_path_check_sys  # 文件判断
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

### Path 类

所有方法均为静态方法，通过 `Path::方法名()` 调用。

#### 路径解析

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

#### 文件操作

| 方法 | 签名 | 说明 |
|------|------|------|
| `exists` | `static bit exists(string path)` | 判断路径是否存在 |
| `is_file` | `static bit is_file(string path)` | 判断是否为普通文件 |
| `is_dir` | `static bit is_dir(string path)` | 判断是否为目录 |
| `is_symlink` | `static bit is_symlink(string path)` | 判断是否为符号链接 |
| `is_empty` | `static bit is_empty(string path)` | 判断文件是否为空 |
| `mkdir` | `static int mkdir(string path)` | 创建目录（递归，相当于 `mkdir -p`） |
| `rmdir` | `static int rmdir(string path)` | 删除空目录 |
| `read_text` | `static string read_text(string path)` | 读取文件内容为字符串 |
| `write_text` | `static void write_text(string path, string content)` | 将字符串写入文件 |
| `copy` | `static void copy(string src, string dst)` | 复制文件 |
| `rename` | `static void rename(string old_path, string new_path)` | 重命名 / 移动文件 |
| `unlink` | `static void unlink(string path)` | 删除文件 |
| `size` | `static longint size(string path)` | 获取文件大小（字节），不存在返回 -1 |
| `modified` | `static longint modified(string path)` | 获取最后修改时间（unix 时间戳） |
| `symlink` | `static int symlink(string target, string linkpath)` | 创建符号链接（仅 DPI） |

#### 错误处理

| 方法 | 签名 | 说明 |
|------|------|------|
| `get_last_error` | `static string get_last_error()` | 获取最后的错误信息 |
| `get_last_error_code` | `static int get_last_error_code()` | 获取最后的错误码（0 = 成功） |
| `clear_error` | `static void clear_error()` | 清除错误状态 |

## 集成方式

### 方式一：$system 后端

```makefile
your_target:
    $(VERILATOR) $(VERILATOR_FLAGS) \
        sv_pathlib_sys_pkg.sv \
        your_module.sv \
        your_main.cpp \
        sv_pathlib_dpi/dpi_system.c \
        --top-module your_module
```

### 方式二：DPI 后端

```makefile
your_target:
    $(VERILATOR) $(VERILATOR_FLAGS) \
        sv_pathlib_dpi_pkg.sv \
        your_module.sv \
        your_main.cpp \
        sv_pathlib_dpi/path_dpi_impl.cc \
        --top-module your_module
```

## 许可证

MIT
