/**
 * AppPlatformProvider.h
 *
 * Concrete ObjC implementation of KMPPlatformInfoProvider.
 * Returns real device/app metadata to foundationKit's Kotlin code.
 */

#import <Foundation/Foundation.h>
#import <foundationBridge/KMPFoundationBridge.h>

NS_ASSUME_NONNULL_BEGIN

/// Provides live device and app metadata.
/// Create one instance and pass it to BridgeSetupKt.configureFoundationBridge(provider:).
@interface AppPlatformProvider : NSObject <KMPPlatformInfoProvider>
@end

NS_ASSUME_NONNULL_END
