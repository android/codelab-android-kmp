/**
 * AppLoggerDelegate.m
 */

#import "AppLoggerDelegate.h"

@implementation AppLoggerDelegate

- (void)logMessage:(NSString *)message
             level:(KMPLogLevel)level
               tag:(NSString *)tag {
    NSString *prefix;
    switch (level) {
        case KMPLogLevelVerbose: prefix = @"V"; break;
        case KMPLogLevelDebug:   prefix = @"D"; break;
        case KMPLogLevelInfo:    prefix = @"I"; break;
        case KMPLogLevelWarning: prefix = @"W"; break;
        case KMPLogLevelError:   prefix = @"E"; break;
        default:                 prefix = @"?"; break;
    }
    NSLog(@"[KMP/%@][%@] %@", prefix, tag, message);
}

@end
