# KMT-2364：多 Framework 共享运行时 — 根因分析与正确执行路径

> 写于 2026-04-01
> 目的：阻止在错误层面打补丁，建立正确的技术认知和执行计划

---

## 一、问题背景

TikTok iOS 用多个独立 XCFramework 交付 KMP 代码（FoundationSDK + BusinessKit）。
两个 framework 都用 Kotlin/Native 编写，都依赖相同的 KMP 库。

标准 K/N 编译器产生的问题：

| 症状 | 根因 |
|------|------|
| 跨 framework `is`/`as` 返回 false | 两套独立的 TypeInfo，地址不同，指针比较失败 |
| ObjC → Kotlin 回桥 crash | TypeInfo 地址不一致导致 ObjC dispatch 走到错误实现 |
| 两套 GC 线程并行运行 | 每个 framework 各自嵌入了完整 runtime.bc |
| 内存异常、对象被提前回收 | 两个 GC 各自维护独立的对象图，不知道对方持有的引用 |

---

## 二、K/N 编译模型的根本约束

理解为什么这个问题"不好解"，需要先理解 K/N 的编译模型。

### Runtime 的嵌入方式

```
.kt 源码
    ↓ 前端编译
IR（中间表示）
    ↓ 后端：collectLlvmModules()
┌─────────────────────────────────┐
│  Bucket 1: runtime.bc           │  ← 预编译的 C++ runtime（GC、MM、ObjC桥）
│            gc.bc / mm.bc        │
│  Bucket 2: klib bitcode         │  ← kotlinx-coroutines 等依赖库
│  Bucket 3: 用户代码 bitcode     │
└─────────────────────────────────┘
    ↓ 合并成一个大 LLVM Module
    ↓ LTO 优化
      - internalize：把所有非 API 符号改成 local (t)
      - DCE：删除死代码
      - 函数调用变成 direct branch (bl)，不再是符号跳转
    ↓ llc 生成机器码
    ↓ 链接 → .framework
```

关键结论：

- **runtime 在 LTO 前就已经被合并进 binary**，不是链接时才进来的
- **LTO 后函数调用变成 bl（直接跳转）**，不通过符号，链接层无法干预
- **internalize 把所有 runtime 符号变成 `t`（local）**，外部完全不可见

这就是为什么"改链接参数"、"改 binary"都无效——问题发生在编译流水线内部，唯一的介入点是编译器本身。

---

## 三、已实现的编译器改动（KMT-2364 POC）

我们已经修改了 Kotlin/Native 编译器，新增以下 BinaryOption：

| Option | 类型 | 用途 |
|--------|------|------|
| `embedRuntime` | Boolean | `false` = Consumer 模式，跳过 Bucket 1，不嵌入 runtime.bc |
| `exportRuntimeSymbols` | Boolean | `true` = Producer 模式，LTO 后把运行时 C 符号重置为 DEFAULT visibility |
| `excludedRuntimeLibraries` | String | 逗号分隔的 klib 名，这些 klib 的 bitcode 不进 Bucket 2 |
| `externalKlibs` | String | 逗号分隔的包名前缀，这些包的 TypeInfo/函数符号在 LTO 前改为外部引用 |
| `exportKlibSymbols` | String | 逗号分隔的包名前缀，这些包的 TypeInfo/函数符号在 LTO 后重置 DEFAULT visibility |

工具链位置：`~/tiktok-kn/v2.1.20-shared-runtime`（symlink 到 worktree dist）

---

## 四、当前错误的修法：在汇编层面打补丁

### 为什么是错的

ObjC → Kotlin 回桥断掉，crash 现场是汇编层面的错误。
直觉反应是"改汇编让 test 过"。

**这是在错误的层面修症状。**

```
根因：TypeInfo 有两份（地址不同），runtime 有两套（GC 独立）
        ↓
症状：ObjC dispatch 找不到正确的 Kotlin 对象
        ↓
隔壁在做：改汇编让这一个 test 过
        ↓
后果：下一个 test 继续挂，继续改，叠加无法解释的 patch
      每次 K/N 版本升级，所有 patch 全部失效
      无法区分"真正的边界 case"和"错误基础上的假问题"
```

### 正确的判断

**只要 TypeInfo 不一致、runtime 不是同一个实例，所有的 ObjC 回桥修法都是沙上建塔。**

应当立即停止 assembly patch，转向从根上解决 TypeInfo 共享和 runtime 共享。

---

## 五、正确的技术方案

### 核心洞察

Foundation 和 Business 都链接 Apple 系统 framework。
Business 完全可以把 Foundation **当作另一个"系统 framework"**，在链接时声明依赖：

```
Business 里的 undefined symbol
    ↓ dyld load time
从 FoundationSDK 的 export trie 解析
```

这样：
- Business 的 `kclass:com.example.Foo` 地址 = Foundation 的 `kclass:com.example.Foo` 地址
- 指针比较成立，`is`/`as` 天然正确
- 不需要改 runtime 内部实现

### 两个关键前提（TikTok 已满足）

```
✅ 相同工具链  → 对象 layout 完全一致，TypeInfo 结构完全一致
✅ Foundation 先构建，产物作为 Business 构建的输入 → 构建和加载顺序确定
```

这两个前提消除了大量变量，让方案从"理论可行"变成"工程可行"。

### 完整的 Gradle 配置

```kotlin
// Foundation（Producer）
binaries.framework("FoundationSDK") {
    binaryOption("exportRuntimeSymbols", "true")     // 运行时 C 符号可见
    binaryOption("exportKlibSymbols", "com.example.kmp.shared")  // TypeInfo 进 export trie
}

// Business（Consumer）
binaries.framework("BusinessKit") {
    binaryOption("embedRuntime", "false")             // 不带自己的 runtime
    binaryOption("excludedRuntimeLibraries", "com.example.kmp.shared")  // 不进 Bucket 2
    binaryOption("externalKlibs", "com.example.kmp.shared")  // TypeInfo 变为 undefined
    linkerOpts("-framework", "FoundationSDK")         // 链接时声明依赖
    linkerOpts("-F", "\$SRCROOT/../FoundationSDK.xcframework/ios-arm64")
}
```

### 为什么这能解决所有已知的系统性问题

| 问题 | 解法 | 原理 |
|------|------|------|
| `is`/`as` 跨框架失败 | externalKlibs + exportKlibSymbols | TypeInfo 地址统一，指针比较成立 |
| ObjC 回桥 crash | 同上，TypeInfo 一致后自愈 | ObjC dispatch 找到正确的 Kotlin 对象 |
| 两套 GC | embedRuntime=false | Business 不带 runtime，共用 Foundation 的 |
| GC 对象图分裂 | 同上 | 所有 Kotlin 对象在同一个堆 |
| TLS 槽位冲突 | 同上 | 统一用 Foundation 的 TLS |
| ObjC class 重复注册 | excludedRuntimeLibraries | 共享 klib 的 bitcode 不进 Business |

---

## 六、需要警惕的 runtime 深层假设

K/N runtime 的整个设计是"一个进程 = 一份 runtime"，这个假设弥漫在 C++ 实现里。
上面的方案通过"符号层面的共享"解决了大部分问题，但以下几点需要端到端验证：

1. **makeRuntimeSymbolsExported 的覆盖范围**
   我们通过"大写开头 C 符号"过滤规则归纳出运行时符号集合，不是从规范推导。
   可能有遗漏，需要 `nm` 对比验证。

2. **跨框架 ObjC 继承**
   Business 继承 Foundation 的 Kotlin class，ObjC superclass 引用需要 dyld 跨 framework 解析。
   这是标准 ObjC 行为，理论上 OK，需要测试覆盖。

3. **Exception 跨框架 unwind**
   我们已经 export 了 `ExceptionObjHolder` 的 RTTI，但完整的 unwind 链路未验证。

---

## 七、执行计划

**前提：立即停止 assembly patch，转向以下步骤。**

### Phase 0：静态验证基线（今天开始，1-2天）

不跑任何代码，只验证编译产物是否符合预期。

验证脚本：[`verify-symbol-sharing.sh`](./verify-symbol-sharing.sh)

```bash
./verify-symbol-sharing.sh \
  path/to/FoundationSDK.framework \
  path/to/BusinessKit.framework
```

脚本做五项检查：
1. Foundation export trie 里有 `kclass:`/`kfun:` 等 Kotlin TypeInfo 符号
2. Foundation export trie 里有运行时 C 符号（`AllocInstance`、`InitRuntime` 等关键符号逐一验证）
3. Business 里**没有**自己定义的 Kotlin TypeInfo 符号（全是 `U`）
4. Business 里**没有**自己定义的运行时 C 符号（`embedRuntime=false` 验证）
5. Business 所有 undefined 的 K/N 符号都能在 Foundation 里找到（差集为空）

任何一项失败则退出码非零，输出明确的失败原因和建议。

---

### Phase 1：TypeInfo 共享验证（3-5天，最高优先级）

目标：跨框架 `is`/`as` 在 Simulator 上跑通。

最小验证用例：

```kotlin
// 共享 klib
class SharedToken(val value: String)

// Foundation 暴露
fun createToken(): SharedToken = SharedToken("hello")

// Business 验证（这个必须返回 true）
fun verifyToken(obj: Any): Boolean = obj is SharedToken
```

测试方式：在 iOS Simulator 上用 `dlopen` 加载两个 framework，调用跨框架函数。

**这一步通过后，隔壁正在修的大部分 ObjC 回桥问题应当自动消失。**

---

### Phase 2：Runtime 共享验证（3-5天）

目标：确认 GC/MM 是同一个实例。

在 Phase 1 基础上加 `embedRuntime=false`。

验证方式：
- Instruments 里只有一套 Kotlin GC 线程（不是两套）
- 两个 framework 之间大量传递对象，触发 GC，无内存异常
- 弱引用跨框架正常工作

---

### Phase 3：ObjC 回桥完整验证（2-3天）

目标：ObjC → Kotlin → ObjC 完整链路。

**此时如果 Phase 1 和 Phase 2 都干净，之前的 ObjC 回桥问题很可能已经自愈。**
如果仍有问题，在干净的基础上 debug，问题是真实的边界 case，不是假问题。

---

## 八、关于"runtime 完全插件化"方向

在讨论过程中，曾经考虑过更彻底的方案：把 runtime 所有接口抽象成 vtable，Business 通过 vtable 调用 Foundation 的 runtime。

这个方向技术上正确，但工程代价极高：
- runtime 里几百处全局状态访问都要改成接口调用
- 引入间接调用性能回归
- vtable API surface 设计难以稳定
- 每次 K/N 升级需要 rebase

**在相同工具链 + Foundation 先构建这两个前提下，vtable 插件化不是必要的。**
符号层面的共享（本文方案）已经足以解决所有已知的系统性问题，工程代价可控。

---

## 九、长期视角

JetBrains 官方在 [KT-42254](https://youtrack.jetbrains.com/issue/KT-42254) 跟进这个问题，预计 1-2 年内不会作为高优先级。

我们的方案定位：
- **不是 hack**：通过编译器 BinaryOptions 正式接入，有完整的 Gradle DSL
- **有上限**：符号层面能解决的都解决了，runtime C++ 内部假设依赖端到端测试覆盖
- **可升级**：官方做完后，切换到官方实现，我们的 BinaryOptions 可以作为过渡期的标准接口

一旦 Phase 0-2 跑通，应当建立 CI 门禁（nm 静态检查 + Simulator dlopen 测试），防止后续改动引入回归。
