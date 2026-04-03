/**
 * AppPlatformProvider.m
 */

#import "AppPlatformProvider.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

@implementation AppPlatformProvider

- (NSString *)osVersion {
    return [UIDevice currentDevice].systemVersion;
}

- (NSString *)deviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

- (NSString *)appVersion {
    NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    return version ?: @"1.0";
}

- (BOOL)isDebugMode {
#ifdef DEBUG
    return YES;
#else
    return NO;
#endif
}

@end
