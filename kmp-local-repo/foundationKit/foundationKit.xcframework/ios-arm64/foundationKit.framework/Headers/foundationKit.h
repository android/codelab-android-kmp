#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

@class FoundationKitKMPLogger, FoundationKitNetworkStateError, FoundationKitNetworkStateLoading, FoundationKitNetworkStateSuccess, FoundationKitRequestPayload, FoundationKitResponseResult, FoundationKitSharedData;

@protocol FoundationKitNetworkState, KMPLoggerDelegate, KMPPlatformInfoProvider;

NS_ASSUME_NONNULL_BEGIN
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunknown-warning-option"
#pragma clang diagnostic ignored "-Wincompatible-property-type"
#pragma clang diagnostic ignored "-Wnullability"

#pragma push_macro("_Nullable_result")
#if !__has_feature(nullability_nullable_result)
#undef _Nullable_result
#define _Nullable_result _Nullable
#endif

__attribute__((swift_name("KotlinBase")))
@interface FoundationKitBase : NSObject
- (instancetype)init __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));
+ (void)initialize __attribute__((objc_requires_super));
@end

@interface FoundationKitBase (FoundationKitBaseCopying) <NSCopying>
@end

__attribute__((swift_name("KotlinMutableSet")))
@interface FoundationKitMutableSet<ObjectType> : NSMutableSet<ObjectType>
@end

__attribute__((swift_name("KotlinMutableDictionary")))
@interface FoundationKitMutableDictionary<KeyType, ObjectType> : NSMutableDictionary<KeyType, ObjectType>
@end

@interface NSError (NSErrorFoundationKitKotlinException)
@property (readonly) id _Nullable kotlinException;
@end

__attribute__((swift_name("KotlinNumber")))
@interface FoundationKitNumber : NSNumber
- (instancetype)initWithChar:(char)value __attribute__((unavailable));
- (instancetype)initWithUnsignedChar:(unsigned char)value __attribute__((unavailable));
- (instancetype)initWithShort:(short)value __attribute__((unavailable));
- (instancetype)initWithUnsignedShort:(unsigned short)value __attribute__((unavailable));
- (instancetype)initWithInt:(int)value __attribute__((unavailable));
- (instancetype)initWithUnsignedInt:(unsigned int)value __attribute__((unavailable));
- (instancetype)initWithLong:(long)value __attribute__((unavailable));
- (instancetype)initWithUnsignedLong:(unsigned long)value __attribute__((unavailable));
- (instancetype)initWithLongLong:(long long)value __attribute__((unavailable));
- (instancetype)initWithUnsignedLongLong:(unsigned long long)value __attribute__((unavailable));
- (instancetype)initWithFloat:(float)value __attribute__((unavailable));
- (instancetype)initWithDouble:(double)value __attribute__((unavailable));
- (instancetype)initWithBool:(BOOL)value __attribute__((unavailable));
- (instancetype)initWithInteger:(NSInteger)value __attribute__((unavailable));
- (instancetype)initWithUnsignedInteger:(NSUInteger)value __attribute__((unavailable));
+ (instancetype)numberWithChar:(char)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedChar:(unsigned char)value __attribute__((unavailable));
+ (instancetype)numberWithShort:(short)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedShort:(unsigned short)value __attribute__((unavailable));
+ (instancetype)numberWithInt:(int)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedInt:(unsigned int)value __attribute__((unavailable));
+ (instancetype)numberWithLong:(long)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedLong:(unsigned long)value __attribute__((unavailable));
+ (instancetype)numberWithLongLong:(long long)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedLongLong:(unsigned long long)value __attribute__((unavailable));
+ (instancetype)numberWithFloat:(float)value __attribute__((unavailable));
+ (instancetype)numberWithDouble:(double)value __attribute__((unavailable));
+ (instancetype)numberWithBool:(BOOL)value __attribute__((unavailable));
+ (instancetype)numberWithInteger:(NSInteger)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedInteger:(NSUInteger)value __attribute__((unavailable));
@end

__attribute__((swift_name("KotlinByte")))
@interface FoundationKitByte : FoundationKitNumber
- (instancetype)initWithChar:(char)value;
+ (instancetype)numberWithChar:(char)value;
@end

__attribute__((swift_name("KotlinUByte")))
@interface FoundationKitUByte : FoundationKitNumber
- (instancetype)initWithUnsignedChar:(unsigned char)value;
+ (instancetype)numberWithUnsignedChar:(unsigned char)value;
@end

__attribute__((swift_name("KotlinShort")))
@interface FoundationKitShort : FoundationKitNumber
- (instancetype)initWithShort:(short)value;
+ (instancetype)numberWithShort:(short)value;
@end

__attribute__((swift_name("KotlinUShort")))
@interface FoundationKitUShort : FoundationKitNumber
- (instancetype)initWithUnsignedShort:(unsigned short)value;
+ (instancetype)numberWithUnsignedShort:(unsigned short)value;
@end

__attribute__((swift_name("KotlinInt")))
@interface FoundationKitInt : FoundationKitNumber
- (instancetype)initWithInt:(int)value;
+ (instancetype)numberWithInt:(int)value;
@end

__attribute__((swift_name("KotlinUInt")))
@interface FoundationKitUInt : FoundationKitNumber
- (instancetype)initWithUnsignedInt:(unsigned int)value;
+ (instancetype)numberWithUnsignedInt:(unsigned int)value;
@end

__attribute__((swift_name("KotlinLong")))
@interface FoundationKitLong : FoundationKitNumber
- (instancetype)initWithLongLong:(long long)value;
+ (instancetype)numberWithLongLong:(long long)value;
@end

__attribute__((swift_name("KotlinULong")))
@interface FoundationKitULong : FoundationKitNumber
- (instancetype)initWithUnsignedLongLong:(unsigned long long)value;
+ (instancetype)numberWithUnsignedLongLong:(unsigned long long)value;
@end

__attribute__((swift_name("KotlinFloat")))
@interface FoundationKitFloat : FoundationKitNumber
- (instancetype)initWithFloat:(float)value;
+ (instancetype)numberWithFloat:(float)value;
@end

__attribute__((swift_name("KotlinDouble")))
@interface FoundationKitDouble : FoundationKitNumber
- (instancetype)initWithDouble:(double)value;
+ (instancetype)numberWithDouble:(double)value;
@end

__attribute__((swift_name("KotlinBoolean")))
@interface FoundationKitBoolean : FoundationKitNumber
- (instancetype)initWithBool:(BOOL)value;
+ (instancetype)numberWithBool:(BOOL)value;
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KMPLogger")))
@interface FoundationKitKMPLogger : FoundationKitBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)kMPLogger __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) FoundationKitKMPLogger *shared __attribute__((swift_name("shared")));
- (void)debugTag:(NSString *)tag message:(NSString *)message __attribute__((swift_name("debug(tag:message:)")));
- (void)errorTag:(NSString *)tag message:(NSString *)message __attribute__((swift_name("error(tag:message:)")));
- (void)infoTag:(NSString *)tag message:(NSString *)message __attribute__((swift_name("info(tag:message:)")));
- (void)verboseTag:(NSString *)tag message:(NSString *)message __attribute__((swift_name("verbose(tag:message:)")));
- (void)warnTag:(NSString *)tag message:(NSString *)message __attribute__((swift_name("warn(tag:message:)")));
@end

__attribute__((swift_name("NetworkState")))
@protocol FoundationKitNetworkState
@required
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("NetworkStateError")))
@interface FoundationKitNetworkStateError : FoundationKitBase <FoundationKitNetworkState>
- (instancetype)initWithMessage:(NSString *)message retryable:(BOOL)retryable __attribute__((swift_name("init(message:retryable:)"))) __attribute__((objc_designated_initializer));
- (FoundationKitNetworkStateError *)doCopyMessage:(NSString *)message retryable:(BOOL)retryable __attribute__((swift_name("doCopy(message:retryable:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *message __attribute__((swift_name("message")));
@property (readonly) BOOL retryable __attribute__((swift_name("retryable")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("NetworkStateLoading")))
@interface FoundationKitNetworkStateLoading : FoundationKitBase <FoundationKitNetworkState>
- (instancetype)initWithProgress:(float)progress __attribute__((swift_name("init(progress:)"))) __attribute__((objc_designated_initializer));
- (FoundationKitNetworkStateLoading *)doCopyProgress:(float)progress __attribute__((swift_name("doCopy(progress:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) float progress __attribute__((swift_name("progress")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("NetworkStateSuccess")))
@interface FoundationKitNetworkStateSuccess : FoundationKitBase <FoundationKitNetworkState>
- (instancetype)initWithData:(FoundationKitResponseResult *)data __attribute__((swift_name("init(data:)"))) __attribute__((objc_designated_initializer));
- (FoundationKitNetworkStateSuccess *)doCopyData:(FoundationKitResponseResult *)data __attribute__((swift_name("doCopy(data:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) FoundationKitResponseResult *data __attribute__((swift_name("data")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RequestPayload")))
@interface FoundationKitRequestPayload : FoundationKitBase
- (instancetype)initWithEndpoint:(NSString *)endpoint params:(NSDictionary<NSString *, NSString *> *)params __attribute__((swift_name("init(endpoint:params:)"))) __attribute__((objc_designated_initializer));
- (FoundationKitRequestPayload *)doCopyEndpoint:(NSString *)endpoint params:(NSDictionary<NSString *, NSString *> *)params __attribute__((swift_name("doCopy(endpoint:params:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *endpoint __attribute__((swift_name("endpoint")));
@property (readonly) NSDictionary<NSString *, NSString *> *params __attribute__((swift_name("params")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ResponseResult")))
@interface FoundationKitResponseResult : FoundationKitBase
- (instancetype)initWithCode:(int32_t)code body:(NSString *)body source:(FoundationKitRequestPayload * _Nullable)source __attribute__((swift_name("init(code:body:source:)"))) __attribute__((objc_designated_initializer));
- (FoundationKitResponseResult *)doCopyCode:(int32_t)code body:(NSString *)body source:(FoundationKitRequestPayload * _Nullable)source __attribute__((swift_name("doCopy(code:body:source:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *body __attribute__((swift_name("body")));
@property (readonly) int32_t code __attribute__((swift_name("code")));
@property (readonly) FoundationKitRequestPayload * _Nullable source __attribute__((swift_name("source")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SharedData")))
@interface FoundationKitSharedData : FoundationKitBase
- (instancetype)initWithId:(int32_t)id message:(NSString *)message __attribute__((swift_name("init(id:message:)"))) __attribute__((objc_designated_initializer));
- (FoundationKitSharedData *)doCopyId:(int32_t)id message:(NSString *)message __attribute__((swift_name("doCopy(id:message:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) NSString *message __attribute__((swift_name("message")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BridgeSetupKt")))
@interface FoundationKitBridgeSetupKt : FoundationKitBase
+ (void)configureFoundationBridgeProvider:(id<KMPPlatformInfoProvider>)provider __attribute__((swift_name("configureFoundationBridge(provider:)")));
+ (void)configureFoundationLoggerDelegate:(id<KMPLoggerDelegate>)delegate __attribute__((swift_name("configureFoundationLogger(delegate:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("GCTestKitKt")))
@interface FoundationKitGCTestKitKt : FoundationKitBase
+ (FoundationKitRequestPayload *)createGCTestPayload __attribute__((swift_name("createGCTestPayload()")));
+ (void)gcCollect __attribute__((swift_name("gcCollect()")));
+ (BOOL)testStrongRefSurvivesGC __attribute__((swift_name("testStrongRefSurvivesGC()")));
+ (BOOL)testWeakRefClearedAfterGC __attribute__((swift_name("testWeakRefClearedAfterGC()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Platform_iosKt")))
@interface FoundationKitPlatform_iosKt : FoundationKitBase
+ (NSString *)platform __attribute__((swift_name("platform()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SharedDataKt")))
@interface FoundationKitSharedDataKt : FoundationKitBase
+ (FoundationKitSharedData *)createSharedDataId:(int32_t)id message:(NSString *)message __attribute__((swift_name("createSharedData(id:message:)")));
+ (NSString *)describeSharedDataData:(FoundationKitSharedData *)data __attribute__((swift_name("describeSharedData(data:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TypeTestModelsKt")))
@interface FoundationKitTypeTestModelsKt : FoundationKitBase
+ (id<FoundationKitNetworkState>)createErrorStateMessage:(NSString *)message retryable:(BOOL)retryable __attribute__((swift_name("createErrorState(message:retryable:)")));
+ (id<FoundationKitNetworkState>)createLoadingStateProgress:(float)progress __attribute__((swift_name("createLoadingState(progress:)")));
+ (FoundationKitRequestPayload *)createRequestEndpoint:(NSString *)endpoint __attribute__((swift_name("createRequest(endpoint:)")));
+ (FoundationKitResponseResult *)createResponseCode:(int32_t)code body:(NSString *)body source:(FoundationKitRequestPayload * _Nullable)source __attribute__((swift_name("createResponse(code:body:source:)")));
+ (id<FoundationKitNetworkState>)createSuccessStateResult:(FoundationKitResponseResult *)result __attribute__((swift_name("createSuccessState(result:)")));
+ (NSString *)errorGetMessageS:(FoundationKitNetworkStateError *)s __attribute__((swift_name("errorGetMessage(s:)")));
+ (BOOL)errorGetRetryableS:(FoundationKitNetworkStateError *)s __attribute__((swift_name("errorGetRetryable(s:)")));
+ (float)loadingGetProgressS:(FoundationKitNetworkStateLoading *)s __attribute__((swift_name("loadingGetProgress(s:)")));
+ (NSString *)requestGetEndpointR:(FoundationKitRequestPayload *)r __attribute__((swift_name("requestGetEndpoint(r:)")));
+ (NSDictionary<NSString *, NSString *> *)requestGetParamsR:(FoundationKitRequestPayload *)r __attribute__((swift_name("requestGetParams(r:)")));
+ (NSString *)responseGetBodyR:(FoundationKitResponseResult *)r __attribute__((swift_name("responseGetBody(r:)")));
+ (int32_t)responseGetCodeR:(FoundationKitResponseResult *)r __attribute__((swift_name("responseGetCode(r:)")));
+ (FoundationKitRequestPayload * _Nullable)responseGetSourceR:(FoundationKitResponseResult *)r __attribute__((swift_name("responseGetSource(r:)")));
+ (FoundationKitResponseResult *)successGetDataS:(FoundationKitNetworkStateSuccess *)s __attribute__((swift_name("successGetData(s:)")));
@end

#pragma pop_macro("_Nullable_result")
#pragma clang diagnostic pop
NS_ASSUME_NONNULL_END
