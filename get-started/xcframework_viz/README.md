# xcframework-analyzer

分析 KMP/Kotlin Native XCFramework 结构、符号组成和依赖关系的命令行工具。

## 依赖

- Python 3
- macOS 系统工具（`nm`, `otool`, `lipo`, `size`，均内置无需安装）

---

## 快速开始

```bash
cd xcframework_viz

# 分析单个 XCFramework
python3 xcframework-analyzer.py path/to/Something.xcframework

# 用 project.json 分析多个 XCFramework（推荐）
python3 xcframework-analyzer.py --project-config project.json
```

---

## project.json 配置

```json
{
  "name": "MySDK",
  "frameworks": [
    { "path": "/path/to/Foundation.xcframework", "role": "foundation" },
    { "path": "/path/to/Business.xcframework",   "role": "business" }
  ]
}
```

- `role` 可选，仅用于报告展示，推荐填写方便区分
- `path` 支持绝对路径和相对路径（相对于执行目录）

---

## 常用命令

### 基础分析

```bash
# 单个 XCFramework
python3 xcframework-analyzer.py Something.xcframework

# 多个 XCFramework（project 模式）
python3 xcframework-analyzer.py --project-config project.json

# 自动发现目录下所有 xcframework
python3 xcframework-analyzer.py --project ./build/XCFrameworks/release/

# 保存自动发现的配置
python3 xcframework-analyzer.py --project ./build/XCFrameworks/release/ \
  --save-project project.json
```

### 符号查看

```bash
# 显示全部符号
python3 xcframework-analyzer.py --project-config project.json --symbols

# 过滤符号（支持正则，自动显示符号列表，无需加 --symbols）
python3 xcframework-analyzer.py --project-config project.json --filter "kotlinx"
python3 xcframework-analyzer.py --project-config project.json --filter "runtime"
python3 xcframework-analyzer.py --project-config project.json --filter "platform"

# 只看 C++ RTTI 符号
python3 xcframework-analyzer.py --project-config project.json \
  --filter "^(__ZTI|__ZTS|__ZTV)"

# 只看 C++ symbols（非 RTTI）
python3 xcframework-analyzer.py --project-config project.json \
  --filter "^__Z[^TI|TS|TV]"

# C++ 符号反解（human readable）
python3 xcframework-analyzer.py --project-config project.json \
  --symbols --filter "^__Z" 2>/dev/null \
  | grep "\[DEF\]" | awk '{print $NF}' | c++filt
```

### ObjC Header 分析

```bash
# 查看所有 @interface / @protocol 声明
python3 xcframework-analyzer.py --project-config project.json --headers
```

### 对比两个 XCFramework

```bash
# 检测重复符号（用于排查 runtime/stdlib 被多个 framework 重复 embed）
python3 xcframework-analyzer.py Foundation.xcframework \
  --compare Business.xcframework
```

### JSON 输出（脚本/CI 集成）

```bash
python3 xcframework-analyzer.py --project-config project.json --json
python3 xcframework-analyzer.py --project-config project.json --json | jq '.frameworks[].slices[].has_kotlin_runtime'
```

---

## 输出解读

### 符号分类说明

| 类别 | 含义 | 诊断意义 |
|------|------|---------|
| `Kotlin/Native Runtime` | K/N 运行时（GC、内存管理等） | 有 → runtime 被 embed；理想情况下只在 Foundation 里出现 |
| `Kotlin Stdlib` | Kotlin 标准库 | 多个 framework 都有 → stdlib 重复打包 |
| `kotlinx libraries` | kotlinx 系列（coroutines 等） | 多个 framework 都有 → 依赖重复打包 |
| `ObjC Export` | K/N 生成的 ObjC class/metaclass | 对应 Swift/ObjC 侧可见的 API 类 |
| `Kotlin User API` | 业务代码导出的 kfun/kclass | 用户自定义的跨平台 API |
| `cinterop bridges` | cinterop 桥接符号 | 与 native 框架的互操作层 |
| `C++ RTTI` | C++ 虚函数表和类型信息（`__ZTI/ZTS/ZTV`） | K/N runtime 内部类，正常存在 |
| `C++ symbols` | C++ name mangling 后的其他符号 | K/N/stdlib 的 C++ 实现层 |
| `Other` | 未分类符号 | 可能包含更多 runtime 符号，可用 `--filter` 深入 |

### 健康状态判断

```
✓  Kotlin/Native runtime NOT embedded  → 正常（thin framework）或 Foundation 负责持有
⚠️  Kotlin/Native runtime EMBEDDED      → 注意：多个 framework 同时 embed 会导致符号冲突
⚠️  Kotlin Stdlib EMBEDDED              → 注意：多个 framework 同时 embed 会导致重复打包
```

### Cross-Framework 重复分析

Project 模式下自动输出跨 framework 重复符号统计：

```
⚠️  856 symbols defined in multiple frameworks!

  Category                           Dup symbols
  ─────────────────────────────────────────────
  Kotlin Stdlib                              651
  Kotlin/Native Runtime                      120
  ...
```

这是 V3 分体交付架构要解决的核心问题。

---

## 本工程构建 XCFramework

```bash
cd ..  # 回到 get-started 根目录

# Debug
./gradlew :foundation:assembleFoundationKitDebugXCFramework

# Release
./gradlew :foundation:assembleFoundationKitReleaseXCFramework
```

产物路径：
```
foundation/build/XCFrameworks/debug/foundationKit.xcframework
foundation/build/XCFrameworks/release/foundationKit.xcframework
```

然后更新 `project.json` 里的路径，重新运行分析。
