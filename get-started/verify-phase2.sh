#!/bin/bash
# KMT-2364 Phase 2: Comprehensive Cross-Framework Type Identity Tests
set -e

DEVICE=93C1CE99-BB65-4FB8-874C-48BD1056E350
BUNDLE=com.exampe.kmp.getstarted.KMPGetStartedCodelab
WORKSPACE=/Users/bytedance/codelab-android-kmp/get-started/iosApp/KMPGetStartedCodelab.xcworkspace

echo "=== KMT-2364 Phase 2: Build & Verify ==="
echo ""

# 1. Build the app
echo "--- Building app (this may take a minute) ---"
xcodebuild -workspace "$WORKSPACE" -scheme KMPGetStartedCodelab \
  -destination "id=$DEVICE" \
  -derivedDataPath /tmp/xcode-dd-p2 \
  build 2>&1 | grep -E "BUILD|error:|warning:" | tail -10

echo ""

# 2. Install & launch
echo "--- Installing and launching ---"
xcrun simctl install $DEVICE /tmp/xcode-dd-p2/Build/Products/Debug-iphonesimulator/KMPGetStartedCodelab.app
xcrun simctl terminate $DEVICE $BUNDLE 2>/dev/null || true
xcrun simctl launch $DEVICE $BUNDLE
echo ""

# 3. Wait for launch, then simulate "Phase 2 Tests" button tap
# The tests are triggered by the button, but we can also check auto-run
sleep 5

# 4. Capture logs
echo "--- Phase 2 test results ---"
xcrun simctl spawn $DEVICE log show --last 8s 2>/dev/null \
    | grep "KMT-2364" \
    | grep -v "^Filtering" \
    | tail -40

echo ""
echo "If tests didn't run automatically, tap 'Phase 2 Tests' button in the app, then re-run:"
echo "  xcrun simctl spawn $DEVICE log show --last 10s | grep KMT-2364-P2"
