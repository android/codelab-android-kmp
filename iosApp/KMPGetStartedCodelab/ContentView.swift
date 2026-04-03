//
//  ContentView.swift
//  KMPGetStartedCodelab
//

import SwiftUI
import foundationKit
import businessKit
import Darwin

struct ContentView: View {
    @State private var results: [String] = []
    @State private var kmt2364Status: String = "⏳ checking..."
    @State private var kmt2364Color: Color = .gray

    // Bridge round-trip demo state
    @State private var bridgeResult: String = "tap the button to start"
    @State private var bridgeLoading: Bool = false
    @State private var bridgeSuccess: Bool? = nil

    var platformString: String {
        foundationKit.Platform_iosKt.platform()
    }
    var userTagString: String {
        let svc = businessKit.UserService()
        let user = svc.currentUser()
        return svc.formatUserTag(user: user)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "globe")
                            .imageScale(.large)
                            .foregroundStyle(.tint)
                        Text("Hello, \(platformString)!")
                    }

                    Text("User: \(userTagString)")
                        .font(.caption)

                    Divider()

                    // ── Bridge Round-Trip Demo ─────────────────────────────
                    GroupBox(label: Text("Bridge Round-Trip Demo").font(.headline)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Swift → Kotlin → ObjC bridge → Kotlin → Swift")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Button(action: runBridgeRoundTrip) {
                                HStack {
                                    if bridgeLoading {
                                        ProgressView().scaleEffect(0.8)
                                    } else {
                                        Image(systemName: bridgeSuccess == true ? "checkmark.circle.fill"
                                                        : bridgeSuccess == false ? "xmark.circle.fill"
                                                        : "arrow.triangle.2.circlepath")
                                    }
                                    Text(bridgeLoading ? "Calling ObjC bridge..." : "Fetch Profile via Bridge")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(bridgeSuccess == true ? .green : bridgeSuccess == false ? .red : .blue)
                            .disabled(bridgeLoading)

                            Text(bridgeResult)
                                .font(.system(.caption, design: .monospaced))
                                .padding(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                        }
                    }

                    Divider()

                    GroupBox(label: Text("KMT-2364 externalKlibs Fix").font(.headline)) {
                        Text(kmt2364Status)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(kmt2364Color)
                    }
                    .onAppear {
                        checkKmt2364()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            runPhase2Tests()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            runGCTests()
                        }
                    }

                    Divider()

                    Text("Cross-Framework Tests")
                        .font(.headline)
                        .padding(.top)

                    HStack {
                        Button("Type Tests") { runPhase2Tests() }
                            .buttonStyle(.borderedProminent)
                        Button("GC Tests") { runGCTests() }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        Button("All Tests") { runAllTests() }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                    }

                    ForEach(Array(results.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(.caption2, design: .monospaced))
                            .padding(2)
                    }
                }
                .padding()
            }
            .navigationTitle("KMP V3 Demo")
        }
    }

    // ─── Bridge Round-Trip ────────────────────────────────────────────────────
    //
    // 完整调用链：
    //   [Swift] 点击按钮
    //   → [Kotlin] ProfileLoader.loadProfile()
    //     → [ObjC] AppAuthDelegate.currentUserId()    (桥调用①)
    //     → [ObjC] AppAuthDelegate.authToken()         (桥调用②)
    //     → [ObjC] AppNetworkDelegate.reachability()   (桥调用③)
    //     → [ObjC] AppNetworkDelegate.requestURL(...)  (桥调用④，async)
    //       ← [ObjC block 在后台线程回调 Kotlin]
    //         ← [Kotlin onComplete 回调 Swift]
    //   [Swift] DispatchQueue.main 更新 UI
    //
    func runBridgeRoundTrip() {
        bridgeLoading = true
        bridgeSuccess = nil
        bridgeResult = "① Swift → Kotlin: calling ProfileLoader.loadProfile()..."

        let loader = businessKit.ProfileLoader()

        // 步骤1：Swift 调用 Kotlin
        loader.loadProfile { result in
            // 步骤8：Kotlin 回调到 Swift（可能在后台线程）
            DispatchQueue.main.async {
                self.bridgeLoading = false
                self.bridgeSuccess = result.success
                if result.success {
                    self.bridgeResult = """
                    ✅ Round-trip complete!

                    Call chain:
                    ① Swift → Kotlin (ProfileLoader.loadProfile)
                    ② Kotlin → ObjC  (authDelegate.currentUserId)
                    ③ Kotlin → ObjC  (authDelegate.authToken)
                    ④ Kotlin → ObjC  (networkDelegate.reachability)
                    ⑤ Kotlin → ObjC  (networkDelegate.requestURL, async)
                    ⑥ ObjC block → Kotlin callback
                    ⑦ Kotlin → Swift (onComplete)
                    ⑧ Swift → main thread → UI update ✅

                    Result:
                    \(result.summary())
                    """
                } else {
                    self.bridgeResult = "❌ Failed: \(result.errorMessage ?? "unknown")"
                }
            }
        }
    }

    func checkKmt2364() {
        let processor = businessKit.SharedDataProcessor()
        let fromFoundation: Any = foundationKit.SharedDataKt.createSharedData(id: 42, message: "cross-fw test")

        // Kotlin 'is SharedData' check via Any
        let isCheck = processor.validateAsSharedData(data: fromFoundation)

        // Verify kclass descriptor address is identical across both frameworks (single shared runtime)
        let symName = "kclass:com.example.kmp.foundation.SharedData"
        let kclassFnd = dlsym(UnsafeMutableRawPointer(bitPattern: -2), symName)
        let fndHandle = dlopen("@rpath/foundationKit.framework/foundationKit", RTLD_NOLOAD)
        let bizHandle = dlopen("@rpath/businessKit.framework/businessKit", RTLD_NOLOAD)
        let kclassFndDirect = fndHandle != nil ? dlsym(fndHandle, symName) : nil
        let kclassBizDirect = bizHandle != nil ? dlsym(bizHandle, symName) : nil
        if fndHandle != nil { dlclose(fndHandle) }
        if bizHandle != nil { dlclose(bizHandle) }

        var castResult = ""
        if isCheck {
            let cast = processor.forceProcessAny(data: fromFoundation)
            castResult = "\n  as-cast: ✅ \(cast)"
        }

        let fndAddr = kclassFnd.map { String(format: "0x%014llx", UInt(bitPattern: $0)) } ?? "nil"
        let fndDirect = kclassFndDirect.map { String(format: "0x%014llx", UInt(bitPattern: $0)) } ?? "nil"
        let bizDirect = kclassBizDirect.map { String(format: "0x%014llx", UInt(bitPattern: $0)) } ?? "nil"
        let addrMatch = kclassFnd != nil && kclassFnd == kclassBizDirect

        kmt2364Status = """
        is-check(Kotlin): \(isCheck ? "✅ true" : "❌ false")\(castResult)
        kclass(RTLD_DEFAULT): \(fndAddr)
        kclass(foundationKit): \(fndDirect)
        kclass(businessKit):   \(bizDirect)
        addrs match: \(addrMatch ? "✅ YES" : "❌ NO / nil")
        """
        NSLog("[KMT-2364] isCheck=%@ kclassFnd=%@ kclassBiz=%@ match=%@",
              isCheck ? "true" : "false", fndDirect, bizDirect, addrMatch ? "YES" : "NO")
        kmt2364Color = isCheck ? .green : (addrMatch ? .orange : .red)
    }

    func runAllTests() {
        results = []

        // === Runtime Duplication Tests ===
        results.append("══════ RUNTIME DUPLICATION ══════")
        for test in RuntimeDuplicateTest.runAll() {
            let icon = test.passed ? "EVIDENCE" : "FAILED"
            results.append("[\(icon)] \(test.testName)")
            for line in test.detail.split(separator: "\n") {
                results.append("  \(line)")
            }
            results.append("")
        }

        // === Cross-Framework Object Passing ===
        results.append("══════ CROSS-FRAMEWORK OBJECTS ══════")
        let processor = businessKit.SharedDataProcessor()

        let fromFoundation: Any = foundationKit.SharedDataKt.createSharedData(id: 1, message: "from foundation")
        let fromBusiness: Any = processor.createLocalSharedData(id: 2, message: "from business")

        let fType = String(describing: type(of: fromFoundation))
        let bType = String(describing: type(of: fromBusiness))
        results.append("[TYPE] Foundation obj: \(fType)")
        results.append("[TYPE] Business obj:   \(bType)")
        results.append("[TYPE] Same type? \(fType == bType)")
        results.append("")

        let valBusiness = processor.validateAsSharedData(data: fromBusiness)
        let valFoundation = processor.validateAsSharedData(data: fromFoundation)
        results.append("[IS CHECK] Business obj is SharedData?    \(valBusiness ? "✅ true" : "❌ false")")
        results.append("[IS CHECK] Foundation obj is SharedData?  \(valFoundation ? "✅ true" : "❌ false")")
        results.append("")

        let processOk = processor.forceProcessAny(data: fromBusiness)
        results.append("[CAST] Business->Business forceProcessAny: ✅ \(processOk)")

        if valFoundation {
            let processFnd = processor.forceProcessAny(data: fromFoundation)
            results.append("[CAST] Foundation->Business forceProcessAny: ✅ \(processFnd)")
        } else {
            results.append("[CAST] Foundation->Business forceProcessAny: ❌ SKIPPED (is-check failed)")
        }
        results.append("")

        let businessClassName = processor.getSharedDataClassName()
        results.append("[CLASS] Business runtime sees: \(businessClassName)")
        results.append("")

        let crossFrameworkFixed = valFoundation
        results.append("══════ SUMMARY ══════")
        results.append("Single K/N runtime (foundationKit): \(crossFrameworkFixed ? "✅ YES" : "❌ NO")")
        results.append("Cross-framework is/as works:        \(crossFrameworkFixed ? "✅ YES" : "❌ NO")")
        results.append("KMT-2364 phase 2 (externalKlibs):   \(crossFrameworkFixed ? "✅ FIXED" : "❌ NOT YET")")

        NSLog("[KMT-2364] ============================================")
        for line in results { NSLog("[KMT-2364] %@", line) }
        NSLog("[KMT-2364] ============================================")
    }

    func runPhase2Tests() {
        results = []
        results.append("══════ PHASE 2: CROSS-FRAMEWORK TYPE IDENTITY ══════")
        results.append("All objects created by foundationKit, passed as Any to businessKit")
        results.append("")

        let net = businessKit.NetworkProcessor()
        var passed = 0
        var total = 0

        let req: Any = foundationKit.TypeTestModelsKt.createRequest(endpoint: "/api/users")
        let resp200: Any = foundationKit.TypeTestModelsKt.createResponse(code: 200, body: "ok", source: nil)

        // --- T1: is-check on plain data classes ---
        total += 1
        let isReq = net.isRequest(obj: req)
        let isResp = net.isResponse(obj: resp200)
        let t1ok = isReq && isResp
        results.append("[\(t1ok ? "✅" : "❌")] T1: is-check on data classes")
        results.append("  isRequest(RequestPayload)=\(isReq)")
        results.append("  isResponse(ResponseResult)=\(isResp)")
        if t1ok { passed += 1 }
        results.append("")

        // --- T2: Takes A returns B (Any→as RequestPayload→execute→ResponseResult) ---
        total += 1
        let resp = net.processAnyRequest(obj: req)
        let t2ok = resp.body == "OK from /api/users"
        results.append("[\(t2ok ? "✅" : "❌")] T2: Takes A returns B")
        results.append("  Any→as RequestPayload→execute→ResponseResult")
        results.append("  resp.body=\"\(resp.body)\"")
        if t2ok { passed += 1 }
        results.append("")

        // --- T3: Nested cross-framework reference ---
        total += 1
        let srcEndpoint = net.getSourceEndpoint(obj: resp)
        let t3ok = srcEndpoint == "/api/users"
        results.append("[\(t3ok ? "✅" : "❌")] T3: Nested reference round-trip")
        results.append("  resp.source.endpoint=\"\(srcEndpoint)\"")
        if t3ok { passed += 1 }
        results.append("")

        // --- T4: Double cast round-trip ---
        total += 1
        let step1 = net.processAnyRequest(obj: req)
        let step2 = net.isResponse(obj: step1)
        let step3 = net.getSourceEndpoint(obj: step1)
        let t4ok = step2 && step3 == "/api/users"
        results.append("[\(t4ok ? "✅" : "❌")] T4: Double cast round-trip")
        results.append("  req(fnd)→resp(biz)→isResponse=\(step2), source=\"\(step3)\"")
        if t4ok { passed += 1 }
        results.append("")

        // --- T5: Sealed class is-checks ---
        let loading: Any = foundationKit.TypeTestModelsKt.createLoadingState(progress: 0.5)
        let success: Any = foundationKit.TypeTestModelsKt.createSuccessState(result: resp200 as! foundationKit.ResponseResult)
        let err: Any = foundationKit.TypeTestModelsKt.createErrorState(message: "timeout", retryable: true)

        total += 1
        let sealedChecks: [(String, Bool)] = [
            ("isNetworkState(Loading)",  net.isNetworkState(obj: loading)),
            ("isLoadingState(Loading)",  net.isLoadingState(obj: loading)),
            ("isSuccessState(Success)",  net.isSuccessState(obj: success)),
            ("isErrorState(Error)",      net.isErrorState(obj: err)),
            ("isNetworkState(Success)",  net.isNetworkState(obj: success)),
            ("isNetworkState(Error)",    net.isNetworkState(obj: err)),
        ]
        let allSealed = sealedChecks.allSatisfy { $0.1 }
        results.append("[\(allSealed ? "✅" : "❌")] T5: Sealed class is-checks (6 checks)")
        for (name, ok) in sealedChecks {
            results.append("  \(ok ? "✅" : "❌") \(name)")
        }
        if allSealed { passed += 1 }
        results.append("")

        // --- T6: Collection type filtering ---
        total += 1
        let mixed: [Any] = [loading, success, err, success]
        let successCount = net.countSuccessInList(items: mixed)
        let t6ok = successCount == 2
        results.append("[\(t6ok ? "✅" : "❌")] T6: Collection filtering (is NetworkState.Success)")
        results.append("  [Loading, Success, Error, Success] → count=\(successCount) (expect 2)")
        if t6ok { passed += 1 }
        results.append("")

        // --- T7: Sealed class when-matching with field access ---
        total += 1
        let d1 = net.describeStateAny(obj: loading)
        let d2 = net.describeStateAny(obj: success)
        let d3 = net.describeStateAny(obj: err)
        let t7ok = d1.contains("loading") && d2.contains("success") && d3.contains("error")
        results.append("[\(t7ok ? "✅" : "❌")] T7: Sealed class when + field access")
        results.append("  Loading → \(d1)")
        results.append("  Success → \(d2)")
        results.append("  Error   → \(d3)")
        if t7ok { passed += 1 }
        results.append("")

        // --- Summary ---
        results.append("══════ RESULT: \(passed)/\(total) PASSED ══════")
        results.append(passed == total
            ? "✅ ALL CROSS-FRAMEWORK TYPE IDENTITY TESTS PASS"
            : "❌ SOME TESTS FAILED")

        NSLog("[KMT-2364-P2] Type tests: %d/%d passed", passed, total)
    }

    func runGCTests() {
        results = []
        results.append("══════ GC / MEMORY MANAGEMENT TESTS ══════")
        results.append("Verifying single shared GC across foundationKit + businessKit")
        results.append("")

        var passed = 0
        var total = 0

        // --- T8: Strong reference survives GC ---
        total += 1
        let t8 = foundationKit.GCTestKitKt.testStrongRefSurvivesGC()
        results.append("[\(t8 ? "✅" : "❌")] T8: Strong reference survives GC")
        results.append("  create RequestPayload → GC.collect() → field still readable")
        if t8 { passed += 1 }
        results.append("")

        // --- T9: Weak reference cleared after GC ---
        total += 1
        let t9 = foundationKit.GCTestKitKt.testWeakRefClearedAfterGC()
        results.append("[\(t9 ? "✅" : "❌")] T9: Weak reference cleared after GC")
        results.append("  WeakRef(obj) survives while held, cleared after strong ref released + GC")
        if t9 { passed += 1 }
        results.append("")

        // --- T10: Cross-framework object survives GC ---
        total += 1
        let gcProc = businessKit.GCCrossFrameworkProcessor()
        let payload: Any = foundationKit.GCTestKitKt.createGCTestPayload()
        let t10 = gcProc.holdThroughGC(obj: payload)
        results.append("[\(t10 ? "✅" : "❌")] T10: Cross-framework object survives GC")
        results.append("  foundationKit creates obj → businessKit holds ref → GC → is-check=\(t10)")
        if t10 { passed += 1 }
        results.append("")

        // --- T11: Field readable after cross-framework GC ---
        total += 1
        let payload2: Any = foundationKit.GCTestKitKt.createGCTestPayload()
        let endpoint = gcProc.readEndpointAfterGC(obj: payload2)
        let t11ok = endpoint == "/cross-fw-gc"
        results.append("[\(t11ok ? "✅" : "❌")] T11: Field readable after cross-framework GC")
        results.append("  foundationKit obj → businessKit GC → endpoint=\"\(endpoint)\" (expect /cross-fw-gc)")
        if t11ok { passed += 1 }
        results.append("")

        // --- Summary ---
        results.append("══════ GC RESULT: \(passed)/\(total) PASSED ══════")
        results.append(passed == total
            ? "✅ SINGLE SHARED GC RUNTIME VERIFIED"
            : "❌ GC SHARING ISSUE DETECTED")

        NSLog("[KMT-2364-GC] T8=%@ T9=%@ T10=%@ T11=%@ endpoint=%@ total=%d/%d",
              t8 ? "PASS" : "FAIL",
              t9 ? "PASS" : "FAIL",
              t10 ? "PASS" : "FAIL",
              t11ok ? "PASS" : "FAIL",
              endpoint,
              passed, total)
    }
}

#Preview {
    ContentView()
}
