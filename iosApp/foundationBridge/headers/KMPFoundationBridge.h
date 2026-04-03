/**
 * KMPFoundationBridge.h
 *
 * Platform/device capabilities exposed by the iOS host application to foundationKit.
 * Implement KMPPlatformInfoProvider in your iOS app and register it by calling
 * foundationKit's `configureFoundationBridge(provider:)` at startup.
 *
 * Pattern: Kotlin code holds a reference to the registered provider and calls it
 * whenever it needs host-app-level platform info (e.g., to build a richer `platform()`
 * string, attach device metadata to analytics events, etc.).
 *
 * Storage note: The provider reference is kept in ObjC-level C functions (not in a Kotlin
 * internal var) to avoid arm64_adrp_lo12 fixup errors when businessKit links against
 * foundationKit — K/N's externalKlibs generates PC-relative references to Kotlin internal
 * vars that cannot cross XCFramework dylib boundaries.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Device and app info provided by the iOS host application.
 * The host app implements this and registers it via configureFoundationBridge(provider:).
 */
@protocol KMPPlatformInfoProvider <NSObject>

/// iOS version string, e.g. "18.2.1"
- (NSString *)osVersion;

/// Device hardware model identifier, e.g. "iPhone17,1"
- (NSString *)deviceModel;

/// Host app marketing version string, e.g. "3.7.0"
- (NSString *)appVersion;

/// YES when running in a Debug / development build.
- (BOOL)isDebugMode;

@end

// ─── ObjC-side storage accessors ─────────────────────────────────────────────
// Accessed by Kotlin via cinterop function calls (PLT/GOT — cross-dylib safe).
// Do NOT replace with Kotlin internal var (arm64_adrp_lo12 is NOT cross-dylib safe).

/// Returns the currently registered platform provider, or nil.
NS_SWIFT_NAME(kmpGetPlatformProvider())
id<KMPPlatformInfoProvider> _Nullable KMPGetPlatformProvider(void);

/// Registers a platform provider. Call from App.init() before any Kotlin code runs.
NS_SWIFT_NAME(kmpSetPlatformProvider(_:))
void KMPSetPlatformProvider(id<KMPPlatformInfoProvider> _Nullable provider);

NS_ASSUME_NONNULL_END
