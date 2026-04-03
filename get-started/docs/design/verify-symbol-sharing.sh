#!/usr/bin/env bash
# verify-symbol-sharing.sh
#
# 静态验证 Producer/Consumer framework 的符号共享是否正确配置。
# 不需要运行任何 Kotlin/ObjC 代码，秒级完成。
#
# 用法：
#   ./verify-symbol-sharing.sh <FoundationSDK.framework> <BusinessKit.framework>
#
# 示例：
#   ./verify-symbol-sharing.sh \
#     build/XCFrameworks/release/FoundationSDK.xcframework/ios-arm64/FoundationSDK.framework \
#     build/XCFrameworks/release/BusinessKit.xcframework/ios-arm64/BusinessKit.framework

set -euo pipefail

FOUNDATION_FW="${1:-}"
BUSINESS_FW="${2:-}"

if [[ -z "$FOUNDATION_FW" || -z "$BUSINESS_FW" ]]; then
    echo "Usage: $0 <FoundationSDK.framework> <BusinessKit.framework>"
    exit 1
fi

FOUNDATION_BIN="$FOUNDATION_FW/$(basename "$FOUNDATION_FW" .framework)"
BUSINESS_BIN="$BUSINESS_FW/$(basename "$BUSINESS_FW" .framework)"

if [[ ! -f "$FOUNDATION_BIN" ]]; then
    echo "❌ Foundation binary not found: $FOUNDATION_BIN"
    exit 1
fi

if [[ ! -f "$BUSINESS_BIN" ]]; then
    echo "❌ Business binary not found: $BUSINESS_BIN"
    exit 1
fi

PASS=0
FAIL=0

pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }
section() { echo; echo "── $1 ──"; }

# ── 1. Foundation 必须 export Kotlin TypeInfo 符号 ──────────────────────────
section "1. Foundation exports Kotlin TypeInfo (kclass:/kfun:/ktypew:)"

FOUNDATION_KTYPE=$(nm -gU "$FOUNDATION_BIN" 2>/dev/null | grep -E " T _k(class|fun|typew|ifacetable):" || true)
if [[ -n "$FOUNDATION_KTYPE" ]]; then
    COUNT=$(echo "$FOUNDATION_KTYPE" | wc -l | tr -d ' ')
    pass "Found $COUNT exported Kotlin TypeInfo/function symbols"
else
    fail "No exported kclass:/kfun: symbols found — did you set exportKlibSymbols?"
fi

# ── 2. Foundation 必须 export 运行时 C 符号 ──────────────────────────────────
section "2. Foundation exports K/N runtime C symbols (AllocInstance etc.)"

FOUNDATION_RUNTIME=$(nm -gU "$FOUNDATION_BIN" 2>/dev/null | grep -E "^[0-9a-f]+ T _[A-Z][a-zA-Z]" | grep -v "__" || true)
if [[ -n "$FOUNDATION_RUNTIME" ]]; then
    COUNT=$(echo "$FOUNDATION_RUNTIME" | wc -l | tr -d ' ')
    pass "Found $COUNT exported runtime C symbols"
    # 检查几个关键符号是否在场
    for SYM in "_AllocInstance" "_InitRuntime" "_Kotlin_ObjCExport_refToObjC"; do
        if echo "$FOUNDATION_RUNTIME" | grep -q "$SYM"; then
            pass "  Key symbol present: $SYM"
        else
            fail "  Key symbol missing: $SYM — makeRuntimeSymbolsExported may be incomplete"
        fi
    done
else
    fail "No exported runtime C symbols — did you set exportRuntimeSymbols=true?"
fi

# ── 3. Business 不能有自己定义的 Kotlin TypeInfo 符号 ──────────────────────
section "3. Business has NO defined Kotlin TypeInfo (all must be undefined)"

BUSINESS_DEFINED_KTYPE=$(nm "$BUSINESS_BIN" 2>/dev/null | grep -E " [Tt] _k(class|fun|typew|ifacetable):" || true)
if [[ -z "$BUSINESS_DEFINED_KTYPE" ]]; then
    pass "No defined kclass:/kfun: symbols in Business — correct"
else
    COUNT=$(echo "$BUSINESS_DEFINED_KTYPE" | wc -l | tr -d ' ')
    fail "$COUNT defined Kotlin TypeInfo symbols found in Business — externalKlibs not working:"
    echo "$BUSINESS_DEFINED_KTYPE" | head -10
    [[ $(echo "$BUSINESS_DEFINED_KTYPE" | wc -l) -gt 10 ]] && echo "  ... (truncated)"
fi

# ── 4. Business 不能有自己定义的运行时 C 符号 ──────────────────────────────
section "4. Business has NO defined runtime C symbols (embedRuntime=false check)"

BUSINESS_DEFINED_RUNTIME=$(nm "$BUSINESS_BIN" 2>/dev/null \
    | grep -E "^[0-9a-f]+ [Tt] _[A-Z][a-zA-Z]" \
    | grep -v "__" \
    | grep -v "_OBJC_" \
    | grep -v "_NS" \
    || true)
if [[ -z "$BUSINESS_DEFINED_RUNTIME" ]]; then
    pass "No defined runtime C symbols in Business — embedRuntime=false working"
else
    COUNT=$(echo "$BUSINESS_DEFINED_RUNTIME" | wc -l | tr -d ' ')
    fail "$COUNT runtime C symbols defined in Business — did you set embedRuntime=false?"
    echo "$BUSINESS_DEFINED_RUNTIME" | head -10
fi

# ── 5. Business 的 undefined 符号必须都能在 Foundation 里找到 ─────────────
section "5. All Business undefined K/N symbols resolvable from Foundation"

BUSINESS_UNDEF=$(nm -u "$BUSINESS_BIN" 2>/dev/null \
    | awk '{print $2}' \
    | grep -E "^_k(class|fun|typew|ifacetable):|^_[A-Z][a-zA-Z]" \
    | grep -v "__" \
    | sort -u || true)

FOUNDATION_EXPORTS=$(nm -gU "$FOUNDATION_BIN" 2>/dev/null \
    | awk '{print $3}' \
    | sort -u || true)

UNRESOLVED=$(comm -23 \
    <(echo "$BUSINESS_UNDEF") \
    <(echo "$FOUNDATION_EXPORTS") || true)

if [[ -z "$UNRESOLVED" ]]; then
    TOTAL=$(echo "$BUSINESS_UNDEF" | grep -c . || echo 0)
    pass "All $TOTAL K/N undefined symbols in Business can be resolved from Foundation"
else
    COUNT=$(echo "$UNRESOLVED" | wc -l | tr -d ' ')
    fail "$COUNT symbols in Business cannot be resolved from Foundation:"
    echo "$UNRESOLVED" | head -20
    [[ $(echo "$UNRESOLVED" | wc -l) -gt 20 ]] && echo "  ... (truncated)"
fi

# ── 结果汇总 ─────────────────────────────────────────────────────────────────
echo
echo "════════════════════════════════"
echo " Result: $PASS passed, $FAIL failed"
echo "════════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
    echo " dyld load WILL fail or runtime sharing is misconfigured."
    exit 1
else
    echo " Symbol sharing looks correct. Proceed to runtime validation."
    exit 0
fi
