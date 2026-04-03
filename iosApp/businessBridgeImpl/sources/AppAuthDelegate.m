/**
 * AppAuthDelegate.m
 */

#import "AppAuthDelegate.h"

@implementation AppAuthDelegate

- (nullable NSString *)currentUserId {
    return @"demo-user-001";
}

- (BOOL)isAuthenticated {
    return YES;
}

- (nullable NSString *)authToken {
    // In production: return a short-lived bearer token from your auth session.
    NSUInteger random = arc4random_uniform(9000) + 1000;
    return [NSString stringWithFormat:@"demo-bearer-token-%lu", (unsigned long)random];
}

@end
