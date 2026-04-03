/**
 * AppNetworkDelegate.m
 */

#import "AppNetworkDelegate.h"

@implementation AppNetworkDelegate

- (KMPNetworkReachability)reachability {
    // In production: query SCNetworkReachability or NWPathMonitor.
    return KMPNetworkReachabilityWiFi;
}

- (void)requestURL:(NSString *)url
            method:(NSString *)method
              body:(nullable NSString *)body
        completion:(void (^)(NSString * _Nullable responseBody,
                             NSInteger statusCode,
                             NSString * _Nullable errorMessage))completion {
    // Stub: call completion synchronously so the Kotlin lambda is still on the
    // call stack when it fires — avoids K/N GC prematurely collecting the lambda
    // when an async dispatch (background queue) holds the only ObjC retain.
    //
    // The "async" effect the UI sees comes from Swift's DispatchQueue.main.async
    // inside the Kotlin callback, which schedules the UI update on the next
    // run-loop turn regardless of which thread calls completion here.
    //
    // In production: perform a real URLSession request and call completion(...)
    // on the main queue from the URLSession completion handler.  Pass the
    // URLSessionTask back to the caller so it can be cancelled if needed.
    NSString *stub = [NSString stringWithFormat:
        @"{\"status\":\"ok\",\"url\":\"%@\",\"method\":\"%@\"}", url, method];
    completion(stub, 200, nil);
}

@end
