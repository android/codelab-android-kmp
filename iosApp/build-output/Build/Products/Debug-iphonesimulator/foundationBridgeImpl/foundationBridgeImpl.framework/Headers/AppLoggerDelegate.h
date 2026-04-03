/**
 * AppLoggerDelegate.h
 *
 * Concrete ObjC implementation of KMPLoggerDelegate.
 * Forwards Kotlin log records to NSLog (swap for os_log / CocoaLumberjack in production).
 */

#import <Foundation/Foundation.h>
#import <foundationBridge/KMPFoundationBridgeLogger.h>

NS_ASSUME_NONNULL_BEGIN

/// Receives log records from foundationKit's Kotlin code and writes them to NSLog.
/// Create one instance and pass it to BridgeSetupKt.configureFoundationLogger(delegate:).
@interface AppLoggerDelegate : NSObject <KMPLoggerDelegate>
@end

NS_ASSUME_NONNULL_END
