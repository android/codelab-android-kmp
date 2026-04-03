/**
 * AppAuthDelegate.h
 *
 * Concrete ObjC implementation of KMPAuthDelegate.
 * Returns demo/stub auth values to businessKit's Kotlin code.
 * Replace the stub implementations with your real account/session manager in production.
 */

#import <Foundation/Foundation.h>
#import <businessBridge/KMPBusinessBridgeAuth.h>

NS_ASSUME_NONNULL_BEGIN

/// Stub auth delegate — returns hardcoded demo values.
/// Create one instance and pass it to BusinessBridgeSetupKt.configureBusinessBridge.
@interface AppAuthDelegate : NSObject <KMPAuthDelegate>
@end

NS_ASSUME_NONNULL_END
