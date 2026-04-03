/**
 * KMPFoundationBridgeLogger.h
 *
 * Structured logging bridge: Kotlin code calls into the host app's native log pipeline
 * (e.g., CocoaLumberjack, os_log, or an in-house SDK) instead of writing to stdout.
 *
 * Register a delegate via foundationKit's `configureFoundationLogger(delegate:)` at startup.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Severity levels that mirror the host app's log taxonomy.
typedef NS_ENUM(NSInteger, KMPLogLevel) {
    KMPLogLevelVerbose = 0,
    KMPLogLevelDebug   = 1,
    KMPLogLevelInfo    = 2,
    KMPLogLevelWarning = 3,
    KMPLogLevelError   = 4,
};

/**
 * Receives log records emitted by Kotlin/foundation code.
 * Implement this in your iOS app and register it via configureFoundationLogger(delegate:).
 */
@protocol KMPLoggerDelegate <NSObject>

/**
 * Called for every log statement in foundationKit.
 * @param message  Human-readable log body.
 * @param level    Severity.
 * @param tag      Source tag, e.g. "NetworkProcessor", "GCTestKit".
 */
- (void)logMessage:(NSString *)message
             level:(KMPLogLevel)level
               tag:(NSString *)tag;

@end

// ─── ObjC-side storage accessors ─────────────────────────────────────────────
// Accessed by Kotlin via cinterop function calls (PLT/GOT — cross-dylib safe).

/// Returns the currently registered logger delegate, or nil.
NS_SWIFT_NAME(kmpGetLoggerDelegate())
id<KMPLoggerDelegate> _Nullable KMPGetLoggerDelegate(void);

/// Registers a logger delegate. Call from App.init() before any Kotlin code runs.
NS_SWIFT_NAME(kmpSetLoggerDelegate(_:))
void KMPSetLoggerDelegate(id<KMPLoggerDelegate> _Nullable delegate);

NS_ASSUME_NONNULL_END
