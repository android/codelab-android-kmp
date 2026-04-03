# KMP V3 分体交付：双运行时问题诊断与分析

> 工程：`codelab-android-kmp/get-started`（foundationKit + businessKit）
> Kotlin 版本：2.2.0
> 分析日期：2026-03-30

---

## 结论

**KMP V3 分体交付架构中存在严重的双运行时问题。** 当两个独立编译的 K/N XCFramework 同时被 iOS App 加载时：

1. **符号层面**：两个框架各自携带完整的 K/N runtime + stdlib，App 包中产生 **7821 个重复符号（98.2%）**
2. **GC 线程层面**：App 进程中同时运行 **4 个 K/N GC 线程**（2 组 × 2），分属 foundationKit 和 businessKit
3. **运行时层面**：两套独立的 K/N 运行时实例在进程中并行，各自维护独立的 GC、类型系统和 ObjC 类层次
4. **对象传递层面**：跨框架 Kotlin 对象不兼容——`is` 检查失败，`as` 强制转换触发 `ClassCastException` 崩溃

---

## 一、符号组成与重复分析

### 1.1 单 Framework 的符号组成（foundationKit，Release arm64）

| 类别 | Defined | 说明 |
|------|--------:|------|
| Kotlin/Native Runtime | **127** | GC、内存管理、线程挂起、ObjC 桥接层 |
| Kotlin Stdlib | **651** | `kfun:kotlin.*` 标准库 |
| kotlinx libraries | 4 | kotlinx 核心桥接 |
| ObjC Export | 69 | 24 个 class + metaclass + ivar |
| Kotlin User API | 1 | `platform()` 函数 |
| C++ RTTI | 43 | typeinfo / vtable（runtime 内部类） |
| C++ symbols | 101 | 静态链接的 libc++ 模板实例 |
| Other | 1320 | GCC 异常表、ObjC method selector 等 |
| **Total** | **2316** | Binary size: **618 KB** |

**运行时符号说明**：K/N runtime 的 C++ 实现大量使用匿名命名空间，符号 mangle 为 `__ZN12_GLOBAL__N_1...`（不含 "kotlin" 字符串），以及 `kotlin::` namespace 的 C++ symbols。24 个 ObjC 导出类中 23 个是 K/N 运行时强制生成的基础类型桥接，仅 1 个是真正的业务 API。

### 1.2 两个 Framework 的符号重复（Release XCFramework 级别）

| 类别 | foundationKit | businessKit | 重复数 | 重复率 |
|------|-------------|------------|--------|--------|
| K/N Runtime | 127 | 127 | **127** | **100%** |
| Kotlin Stdlib | 651 | 769 | **651** | **100%** |
| kotlinx | 4 | 4 | **4** | **100%** |
| C++ RTTI | 43 | 43 | **43** | **100%** |
| C++ symbols | 101 | 101 | **101** | **100%** |
| Kotlin User API | 15 | 58 | 15 | 100% |
| Other | 1354 | 1529 | 1189 | 88% |
| **Total** | **2368** | **2714** | **2130** | **90%** |

businessKit 的 702 KB 中，仅约 50–80 KB 是真正的业务代码增量，其余 ~620 KB（**91%**）是 foundationKit 已有的重复内容。

### 1.3 最终 App 包级别（Debug 构建）

使用 `app-binary-analyzer.py` 分析 `.app/Frameworks/` 内嵌入的 framework：

| 类别 | foundationKit | businessKit | 重复数 |
|------|-------------|------------|--------|
| K/N Runtime | 368 | 368 | **368** |
| Kotlin Stdlib | 2048 | 2179 | **2048** |
| kotlinx | 32 | 32 | **32** |
| C++ RTTI | 74 | 74 | **74** |
| C++ symbols | 213 | 213 | **213** |
| Other | 5144 | 5353 | 5062 |
| **Total** | **7961** | **8351** | **7821 (98.2%)** |

iOS dynamic linker 的 two-level namespace 机制保证了重复符号不会冲突（各自保持在自己的命名空间内），但这也意味着**内存中同时运行着两套完全独立的 K/N runtime**。

---

## 二、GC 线程证据

使用 `sample` 命令采样 App 进程的线程列表：

```
Thread_90456540   GC Timer thread        ← foundationKit runtime
Thread_90456541   Main GC Thread         ← foundationKit runtime
Thread_90456542   GC Timer thread        ← businessKit runtime
Thread_90456543   Main GC Thread         ← businessKit runtime
```

**4 个 GC 线程，2 组，分属两个框架**：

| 线程名 | 所属 dylib | K/N 函数 |
|--------|-----------|---------|
| `GC Timer thread` (#90456540) | `foundationKit` | `kotlin::RepeatedTimer<...GCSchedulerDataAdaptive...>` |
| `Main GC Thread` (#90456541) | `foundationKit` | `kotlin::gc::internal::MainGCThread::body()` |
| `GC Timer thread` (#90456542) | `businessKit` | `kotlin::RepeatedTimer<...GCSchedulerDataAdaptive...>` |
| `Main GC Thread` (#90456543) | `businessKit` | `kotlin::gc::internal::MainGCThread::body()` |

每个 K/N 运行时启动时都会创建自己的 GC 线程（一个 Timer 调度 + 一个主 GC 执行）。两套 GC 完全独立运行，各自管理各自框架创建的 Kotlin 对象——Foundation 创建的对象对 Business 的 GC "不可见"，反之亦然。

---

## 三、ObjC 运行时层证据

### 3.1 独立的 ObjC 类层次

每个 K/N 框架都生成自己的 ObjC root class：

- `foundationKit` → `FoundationKitBase`（26 个类）
- `businessKit` → `BusinessKitBase`（31 个类）

两者继承自各自的 `NSObject`，完全无关：

```swift
NSClassFromString("FoundationKitBase") === NSClassFromString("BusinessKitBase")  // → false
```

### 3.2 不同的动态库镜像

使用 `dladdr` 检查：

```
Foundation class image: foundationKit
Business class image:   businessKit
Different images: true
```

### 3.3 重复的 ObjC 类注册

`objc_copyClassList` 枚举可见两套完整的 K/N 基础类：

```
FoundationKit* (26 个): FoundationKitBase, FoundationKitNumber, FoundationKitKListAsNSArray...
BusinessKit*   (31 个): BusinessKitBase,   BusinessKitNumber,   BusinessKitKListAsNSArray...
```

两套运行时各自向 ObjC runtime 注册了完整的类层次，`BusinessKitBase` 不是 `FoundationKitBase` 的子类，两者完全独立。

---

## 四、跨框架 Kotlin 对象不兼容

### 4.1 实验设计

- Foundation 定义 `data class SharedData(val id: Int, val message: String)` 和工厂函数
- Business 定义 `SharedDataProcessor.validateAsSharedData(data: Any): Boolean`（执行 Kotlin `is SharedData` 检查）

### 4.2 实验结果

**Swift 类型层面**：
```swift
type(of: fromFoundation)  // → FoundationKitSharedData
type(of: fromBusiness)    // → BusinessKitSharedData（完全不同的类型！）
```

**Kotlin `is` 检查**：
```swift
processor.validateAsSharedData(data: fromBusiness)    // → true  ✅
processor.validateAsSharedData(data: fromFoundation)  // → false ❌
```

**Kotlin `as` 强制转换**：
```swift
processor.forceProcessAny(data: fromFoundation)  // → ClassCastException → crash ❌
```

### 4.3 根因分析

```
Foundation Runtime                    Business Runtime
┌──────────────────┐                 ┌──────────────────┐
│ SharedData class  │                 │ SharedData class  │
│ typeInfo: 0xA100  │                 │ typeInfo: 0xB200  │
└──────────────────┘                 └──────────────────┘

Business 的 `is SharedData` 检查：
  obj.typeInfo == 0xB200 ?
  Foundation obj: 0xA100 ≠ 0xB200 → false
  Business obj:   0xB200 == 0xB200 → true
```

每个 K/N 运行时为同一个 Kotlin 类生成了不同的 `typeInfo` 指针。跨运行时的对象携带"对方"的 typeInfo，在"本方"的类型检查中不被识别。

---

## 五、问题影响量化

| 指标 | 当前值 | 理想值（thin 框架） | 浪费比例 |
|------|--------|-----------------|---------|
| businessKit binary | 702 KB | ~60 KB | **91%** |
| App 总 framework 体积 | ~3.8 MB (Debug) | ~1.9 MB | **49%** |
| 重复符号数（Release） | 2130 | 0 | **100%** |
| GC 线程数 | 4 | 2 | — |
| 跨框架 `is`/`as` | 失败/崩溃 | 正常 | — |

N 个 Shell framework 每个浪费 ~620 KB，包大小线性膨胀。

---

## 六、复现步骤

```bash
cd get-started

# 1. 构建 XCFrameworks
./gradlew :foundation:buildIOSRelease :business:buildIOSRelease

# 2. XCFramework 级别符号分析
cd xcframework_viz
python3 xcframework-analyzer.py --project-config project.json

# 3. 构建 iOS App
cd ../iosApp
LANG=en_US.UTF-8 pod install
xcodebuild build -workspace KMPGetStartedCodelab.xcworkspace \
  -scheme KMPGetStartedCodelab -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath ./build-output

# 4. App 包符号分析
cd ../xcframework_viz
python3 app-binary-analyzer.py ../iosApp/build-output/Build/Products/Debug-iphonesimulator/KMPGetStartedCodelab.app

# 5. 运行 App → 点击 "Run All Tests" 查看运行时证据
```

---

## 七、分析工具

```bash
cd xcframework_viz

# 基础分析（project 模式）
python3 xcframework-analyzer.py --project-config project.json

# 查看 runtime 符号详情（含 C++ mangled 符号）
python3 xcframework-analyzer.py --project-config project.json \
  --filter "^(__ZN12_GLOBAL__N_1|__ZN6kotlin|__ZN5konan)" 2>/dev/null \
  | grep "\[DEF\]" | awk '{print $NF}' | c++filt | head -30

# Debug vs Release 对比
python3 xcframework-analyzer.py --project-config project.json --compare

# JSON 输出（CI 集成）
python3 xcframework-analyzer.py --project-config project.json --json 2>/dev/null
```

**注意**：K/N runtime 的 C++ 符号大量使用匿名命名空间，mangle 为 `__ZN12_GLOBAL__N_1...`，检测时需要匹配此前缀，否则会产生 false negative（误报"未嵌入 runtime"）。
