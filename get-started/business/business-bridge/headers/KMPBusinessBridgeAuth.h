/**
 * KMPBusinessBridgeAuth.h
 *
 * User authentication state exposed by the iOS host application to businessKit.
 * This lets Kotlin business logic check login status and obtain short-lived tokens
 * without owning the auth session itself.
 *
 * Register a delegate via businessKit's `configureBusinessBridge(authDelegate:networkDelegate:)`.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Auth / identity info provided by the iOS host application.
 */
@protocol KMPAuthDelegate <NSObject>

/// The logged-in user's stable ID, or nil if no user is authenticated.
- (nullable NSString *)currentUserId;

/// YES when a user session is active.
- (BOOL)isAuthenticated;

/// Short-lived bearer token for backend calls, or nil if unauthenticated.
/// The token may be refreshed between calls; do not cache it in Kotlin.
- (nullable NSString *)authToken;

@end

NS_ASSUME_NONNULL_END
