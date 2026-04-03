#!/bin/bash
# KMT-2364 Runtime Verification Script
# Run this from a NEW terminal (not from Claude Code session)

DEVICE=93C1CE99-BB65-4FB8-874C-48BD1056E350
BUNDLE=com.exampe.kmp.getstarted.KMPGetStartedCodelab

echo "=== KMT-2364 Phase 2 Runtime Verification ==="
echo ""

# 1. Confirm frameworks have correct symbols
APP_DIR=$(xcrun simctl get_app_container $DEVICE $BUNDLE app 2>/dev/null)
if [ -z "$APP_DIR" ]; then
    echo "❌ Could not find app container. Is simulator booted?"
    exit 1
fi

echo "App container: $APP_DIR"
echo ""

echo "--- businessKit kclass (should be 'U' = undefined) ---"
nm -arch arm64 "$APP_DIR/Frameworks/businessKit.framework/businessKit" 2>/dev/null \
    | grep "kclass:com.example.kmp.foundation.SharedData"

echo "--- foundationKit kclass (should be 'S' = defined) ---"
nm -arch arm64 "$APP_DIR/Frameworks/foundationKit.framework/foundationKit" 2>/dev/null \
    | grep "kclass:com.example.kmp.foundation.SharedData"

echo ""

# 2. Launch the app
echo "--- Launching app ---"
xcrun simctl launch $DEVICE $BUNDLE
echo ""

# 3. Wait for app to run checkKmt2364()
sleep 4

# 4. Capture logs
echo "--- KMT-2364 log output ---"
xcrun simctl spawn $DEVICE log show --last 5s 2>/dev/null \
    | grep "KMT-2364" \
    | grep -v "^Filtering" \
    | tail -20

echo ""
echo "Expected: isCheck=true kclassFnd=0x... kclassBiz=0x... match=YES"
