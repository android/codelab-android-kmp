/**
 * KMPBusinessBridgeNetwork.h
 *
 * Network access delegated to the iOS host application's URLSession.
 * Using the host session means auth headers, certificate pinning, and proxy
 * configuration are applied automatically — Kotlin does not need to replicate them.
 *
 * Register via businessKit's `configureBusinessBridge(authDelegate:networkDelegate:)`.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Current network reachability state.
typedef NS_ENUM(NSInteger, KMPNetworkReachability) {
    KMPNetworkReachabilityNotReachable = 0,  ///< No connectivity.
    KMPNetworkReachabilityWiFi         = 1,  ///< Connected via Wi-Fi.
    KMPNetworkReachabilityCellular     = 2,  ///< Connected via cellular.
};

/**
 * Network capabilities provided by the iOS host application.
 */
@protocol KMPNetworkDelegate <NSObject>

/// Synchronously returns the current reachability state.
- (KMPNetworkReachability)reachability;

/**
 * Perform an HTTP request via the host app's URLSession.
 * @param url         Fully-qualified request URL.
 * @param method      HTTP method ("GET", "POST", etc.).
 * @param body        Optional UTF-8 encoded request body.
 * @param completion  Called on an arbitrary queue with the response body,
 *                    HTTP status code, and an error message (nil on success).
 */
- (void)requestURL:(NSString *)url
            method:(NSString *)method
              body:(nullable NSString *)body
        completion:(void (^)(NSString * _Nullable responseBody,
                             NSInteger statusCode,
                             NSString * _Nullable errorMessage))completion;

@end

NS_ASSUME_NONNULL_END
