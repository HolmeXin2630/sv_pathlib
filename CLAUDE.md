# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

sv_pathlib 是一个仿 Python `pathlib` 的 SystemVerilog 路径操作库，提供静态 `Path` 类，支持路径解析、文件检查、目录操作、文件 I/O 等功能。有三个可互换的后端实现，暴露相同的 `Path::` 接口。

## 构建与测试

依赖：Verilator (v5.020+)，GCC/G++（DPI 后端需要）。

```bash
make test_all          # 运行全部测试
make test_<name>       # 运行单个测试（如 test_path_parse、test_path_dpi、test_unified）
make clean             # 清除所有 obj_dir* 构建目录
```

测试用 `verilator --cc --exe --build` 编译并立即运行，无需单独的 lint 步骤。测试输出 `[PASS]`/`[FAIL]`，失败时以 `$finish(1)` 退出。

## 架构

**三后端策略模式**：三个包实现相同接口，底层机制不同：

| 包 | 文件 | 特点 |
|---|---|---|
| `sv_pathlib_vcs_pkg` | `sv_pathlib_vcs_pkg.sv` | 纯 VCS `$system`/`$fopen`，无 DPI 依赖 |
| `sv_pathlib_sys_pkg` | `sv_pathlib_sys_pkg.sv` | DPI-C（`dpi_system.c`），shell `test` 做文件检查 |
| `sv_pathlib_dpi_pkg` | `sv_pathlib_dpi_pkg.sv` | DPI-C（`path_dpi_impl.cc`），POSIX 直接调用，最高性能 |

**路径解析**在三个包中是完全相同的纯 SystemVerilog 实现（`name()`、`stem()`、`extension()`、`parent()`、`join_path()` 等），每个包自包含。

**测试结构**：每个测试是 SV 模块 + 对应的 C++ `main.cpp`（Verilator 入口），临时文件在 `/tmp/sv_pathlib_*` 下创建并自清理。

## 编码规范

- 全部使用 snake_case 命名（非 IEEE 1800 camelCase）
- 所有方法为静态，`Path` 类不实例化：`Path::method_name()`
- 错误处理使用 `$warning()` 报告错误，不修改全局状态，fork/join 并发安全
- 函数返回值表示操作结果（如 `mkdir` 返回 0 表示成功，非 0 表示失败）
- DPI 后端：无错误处理，直接返回结果
- 新增后端需同时在三个包中实现相同接口；路径解析方法可直接复制
