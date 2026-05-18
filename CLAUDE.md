# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

sv_pathlib 是一个仿 Python `pathlib` 的 SystemVerilog 路径操作库，提供静态 `Path` 类，支持路径解析、文件检查、目录操作、文件 I/O、目录遍历等功能。有两种后端实现，通过宏 `+define+SV_PATHLIB_USE_DPI` 选择。

## 构建与测试

依赖：Verilator (v5.020+, 推荐 pip 安装)，GCC/G++（DPI 后端需要）。

```bash
make test_all          # 运行全部测试（VCS + DPI）
make test_vcs_all      # 运行 VCS 模式测试
make test_dpi_all      # 运行 DPI 模式测试
make test_vcs_<name>   # 运行单个 VCS 测试
make test_dpi_<name>   # 运行单个 DPI 测试
make clean             # 清除所有 obj_dir* 构建目录
```

测试用 `verilator --cc --exe --build` 编译并立即运行，无需单独的 lint 步骤。测试输出 `[PASS]`/`[FAIL]`，失败时以 `$finish(1)` 退出。

## 架构

**双后端策略模式**：通过 `+define+SV_PATHLIB_USE_DPI` 选择后端：

| 模式 | 宏 | 实现 | 特点 |
|---|---|---|---|
| VCS (默认) | (无) | `sv_pathlib_vcs_impl.svh` | 纯 `$system`/`$fopen`，无 DPI 依赖 |
| DPI | `+define+SV_PATHLIB_USE_DPI` | `sv_pathlib_dpi_impl.svh` + `dpi/sv_pathlib_dpi.cc` | DPI-C，POSIX 直接调用，支持 glob/rglob |

**文件结构**：
- `src/sv_pathlib_pkg.sv` — 顶层包，通过 `ifdef` 选择后端
- `src/sv_pathlib_define.svh` — 宏定义
- `src/sv_pathlib_common.svh` — 共享代码（路径解析、read_text、write_text），两个后端 `include` 引用
- `src/sv_pathlib_vcs_impl.svh` — VCS 后端实现（文件操作通过 `$system`）
- `src/sv_pathlib_dpi_impl.svh` — DPI 后端实现（DPI-C 包装）
- `src/dpi/sv_pathlib_dpi.cc` — DPI-C 实现（POSIX API）

**路径解析**在 `sv_pathlib_common.svh` 中实现，两个后端通过 `include` 共享同一份代码。

**测试结构**：每个测试是 SV 模块 + 对应的 C++ `main*.cpp`（Verilator 入口），临时文件在 `/tmp/sv_pathlib_*` 下创建并自清理。

## 编码规范

- 全部使用 snake_case 命名（非 IEEE 1800 camelCase）
- 所有方法为静态，`Path` 类不实例化：`Path::method_name()`
- 错误处理使用 `$warning()` 报告错误，不修改全局状态，fork/join 并发安全
- 函数返回值表示操作结果（如 `mkdir` 返回 0 表示成功，非 0 表示失败）
- iterdir/glob/rglob 返回 newline 分隔的 string（非 queue），因为 Verilator 不支持 `include` 文件中的 `queue<string>` 语法
- `stat()` 中使用 `stat -c` 格式（非 `--format`），因为 Verilator 的 `$system` 对后者返回非零
