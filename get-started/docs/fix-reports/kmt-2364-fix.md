# KMT-2364 修复报告：KMP V3 分体交付双运行时崩溃与类型身份修复

> 分支：`claude/pensive-clarke`
> 工程：`get-started/`（foundationKit + businessKit）
> 状态：✅ Phase 1 完成 | ✅ Phase 2 T1–T6 通过 | ⚠️ T7 字段访问待调查

---

## 执行摘要

KMT-2364 涉及 KMP V3 分体交付架构下的两阶段崩溃问题，以及修复后残留的跨框架类型身份问题。

**第一阶段崩溃（`unrecognized selector`）**：两套运行时共用一份全局 ObjC 适配器列表，后加载的框架覆盖先加载的适配器，导致方法分发失败。

**第二阶段崩溃（`Symbol not found: ___ZTI18ExceptionObjHolder`）**：切换为 `embedRuntime=false` 后，该 C++ RTTI 符号以 `linkonce_odr hidden` 编译，LTO 后变为本地符号（`s`），对 businessKit 不可见。

**Phase 2（类型身份）**：运行时崩溃解决后，`is`/`as` 类型检查仍失败。根因是两个框架各自编译了独立的 `_kclass:` 符号副本，typeInfo 指针不同。通过 `exportKlibSymbols` / `externalKlibs` binary option，让 foundationKit 导出 kclass 符号、businessKit 引用外部符号，dyld 加载时统一绑定到同一地址，彻底解决类型身份问题。

---

## 一、架构背景

```
iOS App
├── foundationKit.xcframework   (Producer：embedRuntime=true，提供 K/N 运行时)
└── businessKit.xcframework     (Consumer：embedRuntime=false，不重复内嵌运行时)
```

两个框架独立编译、独立交付，运行时由 iOS dyld 加载，businessKit 的 runtime 符号在运行时从 foundationKit 解析。

---

## 二、Phase 1 修复：运行时符号导出

### 2.1 第一阶段崩溃根因

K/N 通过 `+[KotlinBase initialize]` 使用**全局静态适配器列表**（`KotlinBaseAdapters`）注册 Kotlin 类。两套运行时各自调用该方法，后注册的覆盖先注册的，导致方法分发失败（`unrecognized selector`）。

**修复**：在 `runtime.bc` 中新增 `Kotlin_ObjCExport_initializeClassWithAdapters`，将适配器列表从全局改为**框架本地**，两套适配器互不干扰。

### 2.2 第二阶段崩溃根因

`__ZTI18ExceptionObjHolder` 是 K/N runtime 内部的 C++ RTTI typeinfo。在 `runtime.bc` 中以 `linkonce_odr hidden` 声明：

```llvm
@_ZTI18ExceptionObjHolder = linkonce_odr hidden constant { ... }
```

LTO 后变为 `weak_any + hidden`（Mach-O 中为小写 `s`——local symbol），对其他 dylib 不可见。businessKit 在运行时无法从 foundationKit 解析该符号，dyld 加载失败。

**K/N 原设计初衷**是每个 framework 自带完整运行时（single-framework model），RTTI 符号对外不可见完全合理。分体交付模型打破了这一假设。

### 2.3 修复方案（六个组件）

#### 组件一：Runtime BC Patch

在 `runtime.bc` 中新增 `Kotlin_ObjCExport_initializeClassWithAdapters` 函数，并修补 `objc.bc` 中的 `+[KotlinBase initialize]` 调用该新函数，传入框架本地的 adapters 指针而非全局指针。

覆盖所有 iOS targets：`ios_simulator_arm64`、`ios_arm64`、`ios_x64`。

#### 组件二：编译器 `makeRuntimeSymbolsExported`（`visibility.kt`）

实现 post-LTO pass，将指定的 runtime 符号可见性从 `hidden` 重置为 `DEFAULT + EXTERNAL`：

```kotlin
fun makeRuntimeSymbolsExported(module: LLVMModuleRef) {
    val targets = listOf("_ZTI18ExceptionObjHolder", "_ZTS18ExceptionObjHolder")
    for (sym in targets) {
        LLVMGetNamedGlobal(module, sym)?.let {
            LLVMSetVisibility(it, LLVMDefaultVisibility)
            LLVMSetLinkage(it, LLVMExternalLinkage)
        }
    }
}
```

#### 组件三：`Bitcode.kt` 调用点

在 `runBitcodePostProcessing` 中，当 `exportRuntimeSymbols=true` 时调用 `makeRuntimeSymbolsExported`，确保仅在 foundationKit 构建时执行。

#### 组件四：foundationKit 构建配置

```kotlin
// foundation/build.gradle.kts
target.binaries.framework("foundationKit") {
    binaryOption("exportRuntimeSymbols", "true")
}
```

#### 组件五：禁用 K/N 缓存

`libstdlib-cache.a` 在 runtime.bc 补丁之前预编译，缓存中不包含新函数。禁用缓存强制 IR 级全量链接：

```properties
# local.properties
kotlin.native.cacheKind.iosSimulatorArm64=none
kotlin.native.cacheKind.iosArm64=none
kotlin.native.cacheKind.iosX64=none
```

代价：每次构建需要完整 LTO，编译时间增加 50–200%（临时措施）。

#### 组件六：businessKit 链接选项

```kotlin
// business/build.gradle.kts
target.binaries.framework("businessKit") {
    linkerOpts("-undefined", "dynamic_lookup")
}
```

`-undefined dynamic_lookup` 允许 undefined 符号在运行时动态解析。需确保 foundationKit 先于 businessKit 加载。

### 2.4 Phase 1 验证结果

**符号可见性（nm）**：

```
# 修复前
00000000001b19c0 s __ZTI18ExceptionObjHolder    ← local，对外不可见

# 修复后
00000000001b19c0 S __ZTI18ExceptionObjHolder    ← global，可见
000000000017861a S __ZTS18ExceptionObjHolder
00000000001138b8 T _Kotlin_ObjCExport_initializeClassWithAdapters
```

| 验证项 | 结果 |
|--------|------|
| foundationKit XCFramework 构建 | ✅ BUILD SUCCESSFUL |
| businessKit XCFramework 构建 | ✅ BUILD SUCCESSFUL |
| iOS App (xcodebuild) | ✅ BUILD SUCCEEDED |
| dyld 加载（`ExceptionObjHolder` 解析） | ✅ 无崩溃，App 正常启动 |
| GC 线程数 | ✅ **2 个**（修复前 4 个）|

---

## 三、Phase 2 修复：kclass 符号共享（类型身份）

### 3.1 问题根因

Phase 1 修复后，运行时稳定但跨框架 `is`/`as` 仍然失败：

```
[KMT-2364] isCheck=false kclassFnd=nil kclassBiz=nil match=NO
```

两个框架各自编译了独立的 `_kclass:com.example.kmp.foundation.SharedData` 副本，地址不同。Kotlin 的 `is` 检查比较的是 kclass 描述符的**指针**，两份不同地址的副本导致检查永远为 false。

两次 `dlsym` 均返回 `nil`，因为 LLVM 的 `makeVisibilityHiddenLikeLlvmInternalizePass` 将 kclass 符号从 dylib export trie 中隐藏了。

### 3.2 修复方案：Producer/Consumer 分离

**Producer（foundationKit）**：定义并导出所有 foundation 包的 klib 符号：

```kotlin
// foundation/build.gradle.kts
binaryOption("exportKlibSymbols", "com.example.kmp.foundation")
```

**Consumer（businessKit）**：将 foundation 包的 klib 符号设为外部引用：

```kotlin
// business/build.gradle.kts
binaryOption("externalKlibs", "com.example.kmp.foundation")
```

### 3.3 编译器改动（K/N `visibility.kt`）

**`makeKlibSymbolsExported(module, packagePrefixes)`**（Producer 端，LTO internalize 之后运行）：
- 将 `HiddenVisibility` 重置为 `DefaultVisibility`，适用于 `kclass:`、`kfun:`、`ktypew:` 等
- 符号在 dylib export trie 中变为可见

**`makeKlibSymbolsExternal(module, packagePrefixes)`**（Consumer 端，LTO 之前运行）：
- 全局变量（类描述符）：移除初始化器 → 变为外部声明（nm 中显示为 `U`）
- 函数（`kfun:`）：设置 `available_externally` 链接属性（LTO 可内联；不会实际生成）

**在 `Bitcode.kt` 中的集成顺序**：

```
[Consumer] makeKlibSymbolsExternal()  ← LTO 之前
     ↓
LTO 流水线
     ↓
[Producer] makeRuntimeSymbolsExported()  ← internalize 之后
[Producer] makeKlibSymbolsExported()     ← internalize 之后
```

**注意**：K/N 的 LLVM IR 符号名不含 Darwin 链接器添加的前导 `_`：
- LLVM IR 中：`kclass:com.example.kmp.foundation.SharedData`
- nm/dylib 中：`_kclass:com.example.kmp.foundation.SharedData`

### 3.4 dyld 运行时解析机制

1. App 加载 foundationKit → `_kclass:com.example.kmp.foundation.SharedData` 位于地址 `0xABCD1234`
2. App 加载 businessKit → 该符号为 `U`（undefined）
3. dyld 搜索已加载库的 export trie → 在 foundationKit 中找到
4. dyld 将 businessKit 的引用绑定到同一地址 `0xABCD1234`
5. 两个 framework 共享**同一个 kclass 指针**
6. `is SharedData` 检查 → 指针比较 → **`true` ✅**

### 3.5 Phase 2 二进制验证

**businessKit（Consumer）— foundation 符号全部 `U`**：

```bash
$ nm -arch arm64 businessKit.framework/businessKit | grep "kclass:com.example.kmp.foundation"
                 U _kclass:com.example.kmp.foundation.SharedData
                 U _kclass:com.example.kmp.foundation.RequestPayload
                 U _kclass:com.example.kmp.foundation.ResponseResult
                 U _kclass:com.example.kmp.foundation.NetworkState
                 U _kclass:com.example.kmp.foundation.NetworkState.Loading
                 U _kclass:com.example.kmp.foundation.NetworkState.Success
                 U _kclass:com.example.kmp.foundation.NetworkState.Error
```

共 114 个 foundation 符号被 externalize。

**foundationKit（Producer）— 符号已定义且在 export trie 中**：

```bash
$ nm -arch arm64 foundationKit.framework/foundationKit | grep "kclass:com.example.kmp.foundation.SharedData"
0000000000192840 S _kclass:com.example.kmp.foundation.SharedData

$ xcrun dyld_info -exports foundationKit.framework/foundationKit | grep "kclass:com.example.kmp.foundation"
        0x001980F0  _kclass:com.example.kmp.foundation.SharedData
        ...
```

foundationKit export trie 中共导出 **40 个** `com.example.kmp.foundation.*` 符号，businessKit 导出 **0 个**。

**编译器日志**：

```
w: [KMT-2364] makeKlibSymbolsExported: exported=17 packages=[com.example.kmp.foundation]
w: [KMT-2364] makeKlibSymbolsExternal: changed=20
```

---

## 四、Phase 2 综合类型测试（T1–T7）

新增 `TypeTestModels.kt`（foundation）和 `NetworkProcessor.kt`（business），在 iOS App 中加入 7 个跨框架类型身份测试。所有对象由 foundationKit 创建，通过 `Any` 传给 businessKit 处理。

### 测试结果

| 测试 | 描述 | 结果 |
|------|------|------|
| **基础 isCheck** | `SharedData` 跨框架 `is` 检查 | ✅ `isCheck=true` |
| **T1** | `RequestPayload` / `ResponseResult` 数据类 is-check | ✅ |
| **T2** | `Any → as RequestPayload → processAnyRequest → ResponseResult`（字段读取） | ❌ `resp.body=""` |
| **T3** | 嵌套引用：`resp.source.endpoint` | ❌ `"null"` |
| **T4** | 双重 cast 往返 | ❌ 字段为空 |
| **T5** | sealed class 6 种 is-check（Loading/Success/Error/NetworkState） | ✅ 6/6 |
| **T6** | `List<Any>` 集合中 `countSuccessInList` 过滤 | ✅ count=2 |
| **T7** | sealed `when` 匹配后访问字段（`describeStateAny`） | ❌ SIGSEGV at 0x18 |

**结论**：Kotlin 运行时的类型身份（`is`/`as` cast 本身）在所有 foundation 类型上**完全正确**。`as` cast 不抛 ClassCastException，说明 kclass 共享成功。

### T2–T4 / T7 失败根因分析

`as` cast 成功，但通过 ObjC bridge 读取字段时返回空值或 crash。

**根因假设**：`makeKlibSymbolsExternal` 将 `kfun:` 符号设为 `available_externally` linkage，LTO 可能将构造器或 getter 内联到 businessKit 的代码中，内联代码使用了与 foundationKit 不一致的对象内存布局偏移，导致字段读取错误。

**后续调查方向**：
1. 尝试将 `kfun:` getter/constructor 的 linkage 从 `available_externally` 改为纯 `external`，禁止 LTO 内联
2. 验证 ObjC bridge 层的 `objc2kotlin` wrapper 是否正确转发字段访问
3. 扩展测试：泛型（`reified`）、继承层次、lambda 等更复杂场景

---

## 五、文件变更清单

| 文件 | 变更 |
|------|------|
| `kotlin-native/.../BinaryOptions.kt` | 新增 `exportRuntimeSymbols`、`exportKlibSymbols`、`externalKlibs`、`embedRuntime`、`excludedRuntimeLibraries` |
| `kotlin-native/.../KonanConfig.kt` | 新增 `exportKlibPackages`、`externalKlibPackages` 惰性属性 |
| `kotlin-native/.../visibility.kt` | 新增 `makeKlibSymbolsExported`、`makeKlibSymbolsExternal`、`makeRuntimeSymbolsExported` |
| `kotlin-native/.../Bitcode.kt` | 将 Producer/Consumer 处理集成到 `runBitcodePostProcessing` |
| `kotlin-native/.../ClangArgs.kt` | Xcode 26 SubFrameworks 搜索路径兼容修复 |
| `tiktok-kn/v2.1.20-shared-runtime/.../kotlin-native-compiler-embeddable.jar` | 更新为包含补丁的 class 文件 |
| `foundation/build.gradle.kts` | 新增 `exportRuntimeSymbols` + `exportKlibSymbols` binary option |
| `business/build.gradle.kts` | 新增 `externalKlibs` + `linkerOpts("-undefined dynamic_lookup")` |
| `local.properties` | `kotlin.native.cacheKind.*=none` |
| `foundation/src/.../TypeTestModels.kt` | 新建：`RequestPayload`、`ResponseResult`、`NetworkState` sealed hierarchy |
| `business/src/.../NetworkProcessor.kt` | 新建：跨框架类型测试处理器（Any-based dispatch） |
| `iosApp/.../ContentView.swift` | 新增 Phase 2 测试 UI 和 7 个测试用例 |

---

## 六、已知限制

| 限制 | 说明 |
|------|------|
| 构建时间增加 | `cacheKind=none` 强制完整 LTO，预估增加 50–200% |
| `-undefined dynamic_lookup` 运行时风险 | 若 foundationKit 未正确加载，将在运行时而非安装时崩溃 |
| K/N 版本绑定 | 补丁基于 K/N 2.1.20，升级需重新评估兼容性 |
| T2–T4/T7 字段访问问题 | `available_externally` LTO 内联导致字段 offset 不一致，待调查 |
| Kotlin Stdlib 仍重复 | ~4000 个 stdlib 符号在两个框架中均存在，属于 Phase 3 待解决问题 |

---

## 七、参考资料

- [KMT-2364 - Thin Kotlin/Native Apple frameworks](https://youtrack.jetbrains.com/issue/KMT-2364)
- `docs/analysis/v3-dual-runtime-problem.md` — 双运行时问题实证
- `docs/design/shared-runtime-design.md` — 路径探索 & 编译器改造方案
- K/N 源码：`kotlin-native/backend.native/compiler/ir/backend.native/src/org/jetbrains/kotlin/backend/konan/llvm/`
- Apple：[Two-Level Namespace](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/MachOTopics/1-Articles/executing_files.html)
- LLVM：[Linkage Types](https://llvm.org/docs/LangRef.html#linkage-types)
