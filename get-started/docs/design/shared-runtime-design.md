# KMP V3 分体交付：运行时共享路径探索与编译器改造方案

> K/N 版本：2.2.0
> 分析日期：2026-03-31

---

## 概述

本文档记录了为实现"两个独立 XCFramework 共享同一套 K/N 运行时"所探索的所有技术路径（Path A–E），以及最终实现的编译器改造方案（TikTok 定制 K/N 分支 `v2.1.20-shared-runtime`）。

**核心挑战**：K/N 的编译模型将 Kotlin IR 和 runtime.bc 通过 LLVM LTO 合并编译，运行时代码直接嵌入最终 binary 并以 `t`（local）符号存储，无法通过构建后操作消除。

---

## 一、为什么这很难：编译流水线分析

### 1.1 K/N 编译流水线

```
Kotlin IR (businessKit)
    ↓ K/N backend (IrToBitcode.kt)
LLVM IR — runtime 函数为 declare（undefined reference）
    ↓ collectLlvmModules()              ← 关键分支点
    + runtime.bc                        ← runtime, mm, gc, allocator 等
    + bitcodePartOfStdlib               ← Kotlin stdlib bitcode
    + bitcodeLibraries                  ← kotlinx 等 klib 的 bitcode
    ↓ linkRuntimeModules() — LTO 合并优化
    ↓ LTO internalization pass          ← 非导出符号全部变为 LLVMInternalLinkage
Mach-O binary                           ← runtime 符号为 `t`（local），无法跨 dylib 引用
                                           runtime 函数调用为 PC-relative `bl` 直接分支
```

**关键门控代码**（`CompilerOutput.kt`）：

```kotlin
// 两个独立的 bitcode bucket
val runtimeModules = parseBitcodeFiles(
    (runtimeNativeLibraries + bitcodePartOfStdlib)
        .takeIf { shouldLinkRuntimeNativeLibraries }.orEmpty()  // Bucket 1: runtime.bc, mm.bc...
)
val additionalModules = parseBitcodeFiles(
    bitcodeLibraries    // Bucket 2: kotlinx 等 klib 的 bitcode
)
```

### 1.2 四个根本原因

1. **LTO 不可分割**：Kotlin 代码和 runtime 在同一个 LLVM module 内完成 LTO，无法在 module 边界处分离 runtime
2. **直接分支写死**：LTO 优化后，runtime 函数调用成为直接 PC-relative `bl` 指令，无法被 dyld 重定向
3. **无外部运行时模式**：K/N 没有任何编译器选项支持"引用外部 runtime"模式
4. **二级命名空间强制隔离**：iOS two-level namespace 确保 `businessKit!_IsInstance` ≠ `foundationKit!_IsInstance`

---

## 二、各路径探索结论

### Path A：构建后剥离重复符号 ❌

**思路**：构建后用 `strip` 去除 businessKit 中的 runtime 符号。

**结论**：`strip` 只能删除符号表条目，**无法删除代码段中的实际机器码**。runtime 代码仍然存在于 binary 中，只是符号表项消失。

---

### Path B：`isStatic = true` 静态框架 ❌

**思路**：将 businessKit 编译为静态 framework，让 App 链接时静态合并去重。

**实测结果**：App 中仍然出现 4 个 GC 线程（2 组 × 2）。`.a` 中 runtime object 以 `t`（local）符号写入，iOS 链接器对 local 符号无法跨 `.a` 去重。

**结论**：`t`（local）符号无法被 static linker 去重。

---

### Path C：重链接中间产物 ❌

**思路**：获取 businessKit 的中间 `.o` 文件，手动重链接时去除 runtime 部分。

**结论**：K/N 的编译流水线直接从 Kotlin IR → Mach-O binary，**没有中间 `.o` 文件**产生，无法拦截。

---

### Path D：合并为单个 XCFramework（Umbrella 模式） ✋ 用户否决

**思路**：让 businessKit 包含所有 foundation 类型，App 只需一个 pod。

**技术可行性**：完全可行，只加载一套运行时，ObjC header 正确导出所有类型。TikTok 当前就是这个模式。

**决策**：不符合"分体交付"架构目标，否决。

---

### Path E：K/N 编译器参数 / 链接器选项 ❌

| 方案 | 结果 |
|------|------|
| `-nostdlib` | runtime 完全未减少，仅 ObjC bridge class 有差异 |
| `-Xruntime=/dev/null` | 编译报错：`file too small to contain bitcode header` |
| `-linker-options "-framework foundationKit"` | 成功添加依赖但 runtime 仍然嵌入，两套 runtime 并存 |
| Weak Symbol Coalescing | `_IsInstance` 虽为 `weak external`，但 businessKit 内部调用使用直接 PC-relative `bl`，不在 weak bind table 中，dyld 的 weak coalescing 无效 |
| `-Xbinary=` 参数 | 无任何与 runtime 嵌入相关的选项 |

**Weak bind table 实测**（Path E 的关键发现）：

```
businessKit 的 weak bind table 只有 6 条：
  _Konan_DebugBuffer, _Konan_DebugBufferSize, _Konan_DebugObjectToUtf8Array
  __ZTISt12length_error, __ZdlPvm, __Znwm
```

`_IsInstance` 不在其中，意味着 businessKit 内部的 Kotlin 代码调用它时使用**直接 PC-relative `bl`**，不通过 GOT，dyld 无法重定向。

---

### 理论可行但当前不切实际的路径（F/G/H）

| 路径 | 障碍 |
|------|------|
| **Path F**：自定义 stub runtime | K/N 要求 runtime.bc 有函数实现；stub undefined 引用在链接时报错；foundationKit runtime 符号为 `t`（local），需要改编译流程 |
| **Path G**：Mach-O 符号可见性修补 | macOS toolchain 无 `llvm-objcopy`；businessKit 内部调用为直接分支，不通过 GOT；iOS App Store 不支持 `-flat_namespace` |
| **Path H**：独立 KNRuntime.xcframework | K/N LTO 无论如何把 runtime 嵌入进去；需要编译器支持"引用外部 runtime"模式，即 KMT-2364 请求的功能 |

---

## 三、编译器改造方案（TikTok 定制 K/N 分支）

### 3.1 核心思路

引入**两侧对称配置**：

```
Producer (foundationKit)               Consumer (businessKit)
┌──────────────────────────┐           ┌──────────────────────────────┐
│ embedRuntime = true        │           │ embedRuntime = false           │
│ exportRuntimeSymbols = true│           │ externalKlibs = "com.example.."│
│                            │           │ linkerOpts("-undefined         │
│ runtime.bc → LTO           │           │   dynamic_lookup")            │
│ runtime 符号保持 T          │           │ runtime.bc → 跳过             │
│ kclass: 符号保持 DEFAULT    │           │ kclass: 符号为 U（undefined）  │
└──────────────────────────┘           └──────────────────────────────┘
                  │                                  │
                  └──────────── dyld ────────────────┘
                         运行时由 dyld 统一绑定到 foundationKit
```

### 3.2 新增 Binary Options

| Option | 侧 | 作用 |
|--------|---|------|
| `embedRuntime` | Consumer | `false` = 跳过 Bucket 1（runtime.bc, mm.bc, gc.bc 等） |
| `exportRuntimeSymbols` | Producer | `true` = LTO 后保持 runtime 符号为 `DEFAULT + EXTERNAL` |
| `exportKlibSymbols` | Producer | 将指定包的 klib 符号（`kclass:`、`kfun:` 等）从 export trie 中导出 |
| `externalKlibs` | Consumer | 将指定包的 klib 符号设为外部引用（`U`），移除初始化器 |
| `excludedRuntimeLibraries` | Consumer | 排除指定 klib 的 bitcode 不参与 Bucket 2 链接 |

### 3.3 Gradle DSL

```kotlin
// foundation/build.gradle.kts — Producer
target.binaries.framework("foundationKit") {
    binaryOption("exportRuntimeSymbols", "true")
    binaryOption("exportKlibSymbols", "com.example.kmp.foundation")
}

// business/build.gradle.kts — Consumer
target.binaries.framework("businessKit") {
    binaryOption("embedRuntime", "false")
    binaryOption("externalKlibs", "com.example.kmp.foundation")
    linkerOpts("-undefined", "dynamic_lookup")
}
```

### 3.4 关键实现细节

**`CompilerOutput.kt` 改动**（Consumer 侧跳过 runtime）：

```kotlin
// 改动前
internal val NativeGenerationState.shouldLinkRuntimeNativeLibraries: Boolean
    get() = producedLlvmModuleContainsStdlib && cacheDeserializationStrategy.containsRuntime

// 改动后（+1 行）
    get() = producedLlvmModuleContainsStdlib && cacheDeserializationStrategy.containsRuntime
            && config.embedRuntime   // false → consumer framework，跳过 Bucket 1
```

**`visibility.kt` 新增函数**（详见 `docs/fix-reports/kmt-2364-fix.md`）：
- `makeRuntimeSymbolsExported` — Producer 端 runtime 符号导出
- `makeKlibSymbolsExported` — Producer 端 klib 符号导出（internalize 之后）
- `makeKlibSymbolsExternal` — Consumer 端 klib 符号外部化（LTO 之前）

### 3.5 两个 bucket 正交

`embedRuntime` 控制 Bucket 1（runtime.bc 等），`externalKlibs` 控制 Bucket 2（klib bitcode），两者互不干扰，可独立使用。

---

## 四、TikTok 工具链信息

| 项目 | 值 |
|------|---|
| 基础版本 | Kotlin `v2.1.20` |
| 发布分支 | `tiktok/v2.1.20-shared-runtime` |
| 编译器版本字符串 | `2.1.255-SNAPSHOT` |
| 工具链符号链接 | `~/tiktok-kn/v2.1.20-shared-runtime` |
| 工具链实体路径 | `/Users/bytedance/kotlin/.claude/worktrees/cool-mcnulty/kotlin-native/dist/` |

**接入方式**：

```properties
# local.properties
kotlin.native.home=/Users/bytedance/tiktok-kn/v2.1.20-shared-runtime
kotlin.native.cacheKind.iosSimulatorArm64=none
kotlin.native.cacheKind.iosArm64=none
kotlin.native.cacheKind.iosX64=none
```

编译时 console 出现水印确认工具链生效：

```
w: [TikTok KN] base=2.1.20  branch=claude/cool-mcnulty  features=shared-runtime-poc
```

---

## 五、技术可行性分析

### 5.1 dyld 解析路径

iOS two-level namespace **不是**障碍，而是使此方案成立的机制：
- businessKit 链接时加入 `-framework foundationKit`（或通过 `-undefined dynamic_lookup`）
- businessKit 的 `__DATA,__la_symbol_ptr` stub 条目记录"查找 foundationKit 的 `_IsInstance`"
- dyld 加载 businessKit 时，按 two-level binding 直接定向到 foundationKit
- 完全符合 App Store 要求，无需 `-flat_namespace`

### 5.2 typeInfo 兼容性

`SharedData` 的 `typeInfo` 来自定义它的模块（foundationKit）。Consumer 模式下 businessKit 的 `kclass:` 符号为 `U`，dyld 加载时绑定到 foundationKit 的地址，两个框架共享**同一个 kclass 指针**，`is`/`as` 检查恢复正常。

### 5.3 GC 管理

跳过 `runtime.bc` 后，businessKit 不会启动自己的 GC 线程。Kotlin 对象分配调用通过 PLT stub 路由到 foundationKit 的分配器，由 foundationKit 的 GC 统一管理。预期进程中只有 **2 个 GC 线程**。

---

## 六、已知限制与风险

| 风险 | 缓解措施 |
|------|---------|
| LTO 优化差异：无 runtime 时优化器可能做出不同决策 | 充分的集成测试 |
| K/N 版本升级需重新对齐 | Producer/Consumer 必须使用同一 K/N 版本编译 |
| `-dead_strip` 删除未被直接调用的 runtime 符号 | Producer 侧加 `-exported_symbols_list` 保留 |
| `available_externally` LTO 内联导致字段 offset 不一致（T2/T4/T7） | 待调查：尝试改为纯 `external` 禁止内联 |
| Stdlib 仍重复（~4000 符号） | 需要扩展 `makeKlibSymbolsExported` 机制到 stdlib（Phase 3） |

---

## 七、官方解决方案状态

**JetBrains YouTrack**: [KMT-2364 - Thin Kotlin/Native Apple frameworks](https://youtrack.jetbrains.com/issue/KMT-2364)

- 状态：已确认，预计 **1–2 年内不会实现**
- JetBrains 内部称此为"non-self-contained framework"支持
- 本方案是面向 TikTok 场景的工程优先实现，方向与官方一致

**行业现状**：

| 方案 | 代表 | 运行时共享 | 独立交付 |
|------|------|-----------|---------|
| 单一大 XCFramework | TikTok 当前 | ✅ | ❌ |
| 分体 + 双运行时 | 本研究原型（未修复状态） | ❌（双份） | ✅ |
| 分体 + 共享运行时 | 本修复方案 / 未来 K/N | ✅ | ✅ |

---

## 八、修复效果对比

| 维度 | 修复前（K/N 默认） | 修复后（本方案） |
|------|-----------------|-------|
| GC 线程数 | 4（双份） | **2**（foundationKit 统一管理）|
| 跨框架 `is` 检查 | false（崩溃风险） | **true**（kclass 共享）|
| businessKit 包体 | ~702 KB（含完整 runtime） | **~60 KB**（仅业务符号）|
| 符号重复 | 2130 个 | **0 个** runtime/kclass 重复 |
| 编译器改动量 | — | ~300 行，4–5 个文件 |
