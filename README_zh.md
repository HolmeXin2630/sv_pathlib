# sv_pathlib

[English](README.md)

仿照 Python [pathlib](https://docs.python.org/3/library/pathlib.html) 的 SystemVerilog 路径操作库，提供文件判断、目录操作、文件读写、路径解析和目录遍历功能，采用简洁的静态方法接口。

## 功能特性

- **统一接口** — 所有操作通过 `Path::` 静态方法调用，与后端无关
- **路径解析** — `name()`、`stem()`、`extension()`、`parent()`、`join_path()`、`with_name()`、`with_suffix()`、`is_absolute()`、`resolve()`
- **文件判断** — `exists()`、`is_file()`、`is_dir()`、`is_symlink()`、`is_empty()`
- **目录操作** — `mkdir()`、`rmdir()`、`iterdir()`
- **文件读写** — `read_text()`、`write_text()`、`copy()`、`rename()`、`unlink()`
- **文件信息** — `size()`、`modified()`、`stat()`
- **模式匹配** — `glob()`、`rglob()`（DPI 模式）
- **工具函数** — `cwd()`
- **错误处理** — 使用 `$warning()` 报告错误，无全局状态，fork/join 并发安全
- **两种后端** — VCS（零依赖，`$system` 调用）、DPI-C（高性能，POSIX 直接调用）

## 目录结构

```
sv_pathlib/
  src/
    sv_pathlib_pkg.sv           -- 顶层包，通过宏选择后端
    sv_pathlib_define.svh       -- 宏定义
    sv_pathlib_vcs_impl.svh     -- VCS 后端实现（$system）
    sv_pathlib_dpi_impl.svh     -- DPI 后端实现（DPI-C 封装）
    dpi/
      sv_pathlib_dpi.cc         -- DPI-C 实现（POSIX）
  tests/                        -- 测试套件
  Makefile                      -- 构建与测试自动化
```

## 快速上手

导入包并使用 `Path::` 接口：

```systemverilog
import sv_pathlib_pkg::*;  // VCS 模式（默认）

module example;
  initial begin
    // 路径解析
    $display("文件名: %s", Path::name("/home/user/project/main.sv"));     // main.sv
    $display("主名:   %s", Path::stem("/home/user/project/main.sv"));     // main
    $display("扩展名: %s", Path::extension("/home/user/project/main.sv"));// .sv
    $display("父目录: %s", Path::parent("/home/user/project/main.sv"));   // /home/user/project

    // 路径拼接和解析
    string full = Path::join_path("/home/user", "project/src/main.sv");
    $display("完整路径: %s", full);  // /home/user/project/src/main.sv
    $display("解析后: %s", Path::resolve("/a/b/../c/./d"));  // /a/c/d

    // 目录操作
    void'(Path::mkdir("/tmp/my_project/src"));
    $display("是目录: %b", Path::is_dir("/tmp/my_project/src"));

    // 文件读写
    Path::write_text("/tmp/my_project/README.md", "# My Project");
    string content = Path::read_text("/tmp/my_project/README.md");

    // 文件信息
    $display("大小: %0d 字节", Path::size("/tmp/my_project/README.md"));
    $display("修改时间: %0d", Path::modified("/tmp/my_project/README.md"));

    // 目录遍历
    string entries = Path::iterdir("/tmp/my_project");

    // 当前工作目录
    $display("cwd: %s", Path::cwd());

    // 清理
    Path::unlink("/tmp/my_project/README.md");
    void'(Path::rmdir("/tmp/my_project/src"));
    void'(Path::rmdir("/tmp/my_project"));
  end
endmodule
```

### 错误处理

错误通过 `$warning()` 报告——无全局状态，fork/join 并发安全。

```systemverilog
import sv_pathlib_pkg::*;

module example_error;
  initial begin
    string content;

    // 尝试读取不存在的文件
    // $warning 打印: "sv_pathlib: file not found: /tmp/nonexistent.txt"
    content = Path::read_text("/tmp/nonexistent.txt");

    // 尝试复制不存在的源文件
    // $warning 打印: "sv_pathlib: source file not found: /tmp/no_such_file.txt"
    Path::copy("/tmp/no_such_file.txt", "/tmp/dest.txt");
  end
endmodule
```

## 后端选择

通过 `+define+SV_PATHLIB_USE_DPI` 宏选择 DPI 后端：

| 模式 | 宏 | 后端 | 特性 |
|------|-----|------|------|
| VCS (默认) | (无) | `$system` 调用 | 所有路径操作、iterdir、stat、cwd |
| DPI | `+define+SV_PATHLIB_USE_DPI` | DPI-C (POSIX) | VCS 所有功能 + glob、rglob，更高性能 |

### VCS 模式（默认）

```bash
# Verilator
verilator --cc --exe --build -Isrc \
    src/sv_pathlib_pkg.sv your_module.sv your_main.cpp \
    --top-module your_module

# VCS
vcs -sverilog src/sv_pathlib_pkg.sv your_module.sv -full64
```

### DPI 模式

```bash
# Verilator
verilator --cc --exe --build -Isrc +define+SV_PATHLIB_USE_DPI \
    src/sv_pathlib_pkg.sv your_module.sv your_main.cpp \
    src/dpi/sv_pathlib_dpi.cc \
    --top-module your_module
```

## 构建与测试

### 环境要求

- [Verilator](https://www.veripool.org/verilator/) v5.020+（推荐 pip 安装：`pip install verilator`）
- GCC/G++（DPI 后端需要）

### 运行全部测试

```bash
make test_all          # 运行全部 VCS + DPI 测试
make test_vcs_all      # 运行 VCS 模式测试
make test_dpi_all      # 运行 DPI 模式测试
```

### 运行单个测试

```bash
make test_vcs_path_parse   # 路径解析（VCS）
make test_vcs_resolve      # 路径解析（VCS）
make test_vcs_stat         # 文件信息（VCS）
make test_vcs_cwd          # 当前目录（VCS）
make test_vcs_dir_ops      # 目录操作（VCS）
make test_vcs_file_io      # 文件读写（VCS）
make test_vcs_file_ops     # 文件操作（VCS）
make test_vcs_path_check   # 文件判断（VCS）
make test_dpi_glob         # Glob/rglob（DPI）
```

### 清理构建产物

```bash
make test_clean    # 清除 obj_dir_* 构建目录
make clean         # 清除所有构建产物
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
| `resolve` | `static string resolve(string path)` | 解析 `.` 和 `..` 组件 |

#### 文件操作

| 方法 | 签名 | 说明 |
|------|------|------|
| `exists` | `static bit exists(string path)` | 判断路径是否存在 |
| `is_file` | `static bit is_file(string path)` | 判断是否为普通文件 |
| `is_dir` | `static bit is_dir(string path)` | 判断是否为目录 |
| `is_symlink` | `static bit is_symlink(string path)` | 判断是否为符号链接 |
| `is_empty` | `static bit is_empty(string path)` | 判断文件是否为空 |
| `mkdir` | `static int mkdir(string path)` | 创建目录（递归），返回 0 表示成功 |
| `rmdir` | `static int rmdir(string path)` | 删除空目录，返回 0 表示成功 |
| `read_text` | `static string read_text(string path)` | 读取文件内容为字符串 |
| `write_text` | `static void write_text(string path, string content)` | 将字符串写入文件 |
| `copy` | `static void copy(string src, string dst)` | 复制文件 |
| `rename` | `static void rename(string old_path, string new_path)` | 重命名 / 移动文件 |
| `unlink` | `static void unlink(string path)` | 删除文件 |
| `symlink` | `static int symlink(string target, string linkpath)` | 创建符号链接 |
| `size` | `static longint size(string path)` | 获取文件大小（字节），不存在返回 -1 |
| `modified` | `static longint modified(string path)` | 获取最后修改时间（unix 时间戳） |
| `stat` | `static stat_t stat(string path)` | 获取完整文件信息（size, mtime, atime, ctime, mode） |
| `iterdir` | `static string iterdir(string path)` | 列出目录内容（换行分隔） |
| `cwd` | `static string cwd()` | 获取当前工作目录 |

#### 模式匹配（仅 DPI 模式）

| 方法 | 签名 | 说明 |
|------|------|------|
| `glob` | `static string glob(string path, string pattern)` | 非递归模式匹配 |
| `rglob` | `static string rglob(string path, string pattern)` | 递归模式匹配 |

### stat_t 结构体

```systemverilog
typedef struct {
  longint st_size;    // 文件大小（字节）
  longint st_mtime;   // 最后修改时间
  longint st_atime;   // 最后访问时间
  longint st_ctime;   // 最后状态变更时间
  int     st_mode;    // 文件模式（权限）
} stat_t;
```

## 许可证

MIT
