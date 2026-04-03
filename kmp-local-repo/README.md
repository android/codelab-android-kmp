# kmp-local-repo

本地二进制分发仓库，充当 Android/KMP 工程和 iOS 工程之间的隔离层。

## 目录结构（发布后）

```
kmp-local-repo/
  foundationBridge/           ← header-only pod（ObjC 协议声明）
    foundationBridge.podspec
    headers/
      KMPFoundationBridge.h
      KMPFoundationBridgeLogger.h
  foundationKit/              ← XCFramework 二进制 pod
    foundationKit.podspec
    foundationKit.xcframework/
  businessBridge/
    businessBridge.podspec
    headers/
      KMPBusinessBridgeAuth.h
      KMPBusinessBridgeNetwork.h
  businessKit/
    businessKit.podspec
    businessKit.xcframework/
```

## 发布（在 get-started/ 目录下执行）

```bash
# Debug
./gradlew publishKMPIOSDebug

# Release
./gradlew publishKMPIOSRelease
```

## iOS 工程消费

```bash
cd ../iosApp && pod install
```

## 注意

- 该目录下的内容是构建产物，**不应提交到 VCS**
- `.gitkeep` 文件仅用于追踪目录本身
- 在 `.gitignore` 中排除所有子目录内容（保留 .gitkeep 和 README.md）
