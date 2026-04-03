/**
 * AppNetworkDelegate.h
 *
 * Concrete ObjC implementation of KMPNetworkDelegate.
 * Stub: always reports Wi-Fi and returns mock JSON responses.
 * Replace with real URLSession + reachability logic in production.
 */

#import <Foundation/Foundation.h>
#import <businessBridge/KMPBusinessBridgeNetwork.h>

NS_ASSUME_NONNULL_BEGIN

/// Stub network delegate — reports Wi-Fi and returns mock HTTP 200 responses.
/// Create one instance and pass it to BusinessBridgeSetupKt.configureBusinessBridge.
@interface AppNetworkDelegate : NSObject <KMPNetworkDelegate>
@end

NS_ASSUME_NONNULL_END
