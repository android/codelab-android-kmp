#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

@class BusinessKitFeedItem, BusinessKitFoundationCommonRequestPayload, BusinessKitFoundationCommonResponseResult, BusinessKitFoundationCommonSharedData, BusinessKitProfileResult, BusinessKitUser, BusinessKitUserService;

@protocol KMPAuthDelegate, KMPNetworkDelegate;

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
@interface BusinessKitBase : NSObject
- (instancetype)init __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));
+ (void)initialize __attribute__((objc_requires_super));
@end

@interface BusinessKitBase (BusinessKitBaseCopying) <NSCopying>
@end

__attribute__((swift_name("KotlinMutableSet")))
@interface BusinessKitMutableSet<ObjectType> : NSMutableSet<ObjectType>
@end

__attribute__((swift_name("KotlinMutableDictionary")))
@interface BusinessKitMutableDictionary<KeyType, ObjectType> : NSMutableDictionary<KeyType, ObjectType>
@end

@interface NSError (NSErrorBusinessKitKotlinException)
@property (readonly) id _Nullable kotlinException;
@end

__attribute__((swift_name("KotlinNumber")))
@interface BusinessKitNumber : NSNumber
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
@interface BusinessKitByte : BusinessKitNumber
- (instancetype)initWithChar:(char)value;
+ (instancetype)numberWithChar:(char)value;
@end

__attribute__((swift_name("KotlinUByte")))
@interface BusinessKitUByte : BusinessKitNumber
- (instancetype)initWithUnsignedChar:(unsigned char)value;
+ (instancetype)numberWithUnsignedChar:(unsigned char)value;
@end

__attribute__((swift_name("KotlinShort")))
@interface BusinessKitShort : BusinessKitNumber
- (instancetype)initWithShort:(short)value;
+ (instancetype)numberWithShort:(short)value;
@end

__attribute__((swift_name("KotlinUShort")))
@interface BusinessKitUShort : BusinessKitNumber
- (instancetype)initWithUnsignedShort:(unsigned short)value;
+ (instancetype)numberWithUnsignedShort:(unsigned short)value;
@end

__attribute__((swift_name("KotlinInt")))
@interface BusinessKitInt : BusinessKitNumber
- (instancetype)initWithInt:(int)value;
+ (instancetype)numberWithInt:(int)value;
@end

__attribute__((swift_name("KotlinUInt")))
@interface BusinessKitUInt : BusinessKitNumber
- (instancetype)initWithUnsignedInt:(unsigned int)value;
+ (instancetype)numberWithUnsignedInt:(unsigned int)value;
@end

__attribute__((swift_name("KotlinLong")))
@interface BusinessKitLong : BusinessKitNumber
- (instancetype)initWithLongLong:(long long)value;
+ (instancetype)numberWithLongLong:(long long)value;
@end

__attribute__((swift_name("KotlinULong")))
@interface BusinessKitULong : BusinessKitNumber
- (instancetype)initWithUnsignedLongLong:(unsigned long long)value;
+ (instancetype)numberWithUnsignedLongLong:(unsigned long long)value;
@end

__attribute__((swift_name("KotlinFloat")))
@interface BusinessKitFloat : BusinessKitNumber
- (instancetype)initWithFloat:(float)value;
+ (instancetype)numberWithFloat:(float)value;
@end

__attribute__((swift_name("KotlinDouble")))
@interface BusinessKitDouble : BusinessKitNumber
- (instancetype)initWithDouble:(double)value;
+ (instancetype)numberWithDouble:(double)value;
@end

__attribute__((swift_name("KotlinBoolean")))
@interface BusinessKitBoolean : BusinessKitNumber
- (instancetype)initWithBool:(BOOL)value;
+ (instancetype)numberWithBool:(BOOL)value;
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("FeedService")))
@interface BusinessKitFeedService : BusinessKitBase
- (instancetype)initWithUserService:(BusinessKitUserService *)userService __attribute__((swift_name("init(userService:)"))) __attribute__((objc_designated_initializer));
- (NSArray<BusinessKitFeedItem *> *)generateFeedCount:(int32_t)count __attribute__((swift_name("generateFeed(count:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("GCCrossFrameworkProcessor")))
@interface BusinessKitGCCrossFrameworkProcessor : BusinessKitBase
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (BOOL)holdThroughGCObj:(id)obj __attribute__((swift_name("holdThroughGC(obj:)")));
- (NSString *)readEndpointAfterGCObj:(id)obj __attribute__((swift_name("readEndpointAfterGC(obj:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("NetworkProcessor")))
@interface BusinessKitNetworkProcessor : BusinessKitBase
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (int32_t)countSuccessInListItems:(NSArray<id> *)items __attribute__((swift_name("countSuccessInList(items:)")));
- (NSString *)describeStateAnyObj:(id)obj __attribute__((swift_name("describeStateAny(obj:)")));
- (BusinessKitFoundationCommonResponseResult *)executeRequestRequest:(BusinessKitFoundationCommonRequestPayload *)request __attribute__((swift_name("executeRequest(request:)")));
- (NSString *)getSourceEndpointObj:(id)obj __attribute__((swift_name("getSourceEndpoint(obj:)")));
- (BOOL)isErrorStateObj:(id)obj __attribute__((swift_name("isErrorState(obj:)")));
- (BOOL)isLoadingStateObj:(id)obj __attribute__((swift_name("isLoadingState(obj:)")));
- (BOOL)isNetworkStateObj:(id)obj __attribute__((swift_name("isNetworkState(obj:)")));
- (BOOL)isRequestObj:(id)obj __attribute__((swift_name("isRequest(obj:)")));
- (BOOL)isResponseObj:(id)obj __attribute__((swift_name("isResponse(obj:)")));
- (BOOL)isSuccessStateObj:(id)obj __attribute__((swift_name("isSuccessState(obj:)")));
- (BusinessKitFoundationCommonResponseResult *)processAnyRequestObj:(id)obj __attribute__((swift_name("processAnyRequest(obj:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ProfileLoader")))
@interface BusinessKitProfileLoader : BusinessKitBase
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (void)loadProfileOnComplete:(void (^)(BusinessKitProfileResult *))onComplete __attribute__((swift_name("loadProfile(onComplete:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ProfileResult")))
@interface BusinessKitProfileResult : BusinessKitBase
- (instancetype)initWithSuccess:(BOOL)success userId:(NSString *)userId token:(NSString *)token networkStatus:(NSString *)networkStatus httpStatus:(int32_t)httpStatus responseBody:(NSString *)responseBody errorMessage:(NSString * _Nullable)errorMessage __attribute__((swift_name("init(success:userId:token:networkStatus:httpStatus:responseBody:errorMessage:)"))) __attribute__((objc_designated_initializer));
- (BusinessKitProfileResult *)doCopySuccess:(BOOL)success userId:(NSString *)userId token:(NSString *)token networkStatus:(NSString *)networkStatus httpStatus:(int32_t)httpStatus responseBody:(NSString *)responseBody errorMessage:(NSString * _Nullable)errorMessage __attribute__((swift_name("doCopy(success:userId:token:networkStatus:httpStatus:responseBody:errorMessage:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)summary __attribute__((swift_name("summary()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable errorMessage __attribute__((swift_name("errorMessage")));
@property (readonly) int32_t httpStatus __attribute__((swift_name("httpStatus")));
@property (readonly) NSString *networkStatus __attribute__((swift_name("networkStatus")));
@property (readonly) NSString *responseBody __attribute__((swift_name("responseBody")));
@property (readonly) BOOL success __attribute__((swift_name("success")));
@property (readonly) NSString *token __attribute__((swift_name("token")));
@property (readonly) NSString *userId __attribute__((swift_name("userId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SharedDataProcessor")))
@interface BusinessKitSharedDataProcessor : BusinessKitBase
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (BusinessKitFoundationCommonSharedData *)createLocalSharedDataId:(int32_t)id message:(NSString *)message __attribute__((swift_name("createLocalSharedData(id:message:)")));
- (NSString *)forceProcessAnyData:(id)data __attribute__((swift_name("forceProcessAny(data:)")));
- (NSString *)getSharedDataClassName __attribute__((swift_name("getSharedDataClassName()")));
- (NSString *)processSharedDataData:(BusinessKitFoundationCommonSharedData *)data __attribute__((swift_name("processSharedData(data:)")));
- (BOOL)validateAsSharedDataData:(id)data __attribute__((swift_name("validateAsSharedData(data:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("UserService")))
@interface BusinessKitUserService : BusinessKitBase
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (BusinessKitUser *)currentUser __attribute__((swift_name("currentUser()")));
- (NSString *)formatUserTagUser:(BusinessKitUser *)user __attribute__((swift_name("formatUserTag(user:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("FeedItem")))
@interface BusinessKitFeedItem : BusinessKitBase
- (instancetype)initWithId:(NSString *)id title:(NSString *)title author:(BusinessKitUser *)author __attribute__((swift_name("init(id:title:author:)"))) __attribute__((objc_designated_initializer));
- (BusinessKitFeedItem *)doCopyId:(NSString *)id title:(NSString *)title author:(BusinessKitUser *)author __attribute__((swift_name("doCopy(id:title:author:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BusinessKitUser *author __attribute__((swift_name("author")));
@property (readonly) NSString *id __attribute__((swift_name("id")));
@property (readonly) NSString *title __attribute__((swift_name("title")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("User")))
@interface BusinessKitUser : BusinessKitBase
- (instancetype)initWithId:(NSString *)id name:(NSString *)name platform:(NSString *)platform __attribute__((swift_name("init(id:name:platform:)"))) __attribute__((objc_designated_initializer));
- (BusinessKitUser *)doCopyId:(NSString *)id name:(NSString *)name platform:(NSString *)platform __attribute__((swift_name("doCopy(id:name:platform:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *id __attribute__((swift_name("id")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) NSString *platform __attribute__((swift_name("platform")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BridgeClientKt")))
@interface BusinessKitBridgeClientKt : BusinessKitBase
+ (NSString * _Nullable)authToken __attribute__((swift_name("authToken()")));
+ (NSString * _Nullable)currentUserId __attribute__((swift_name("currentUserId()")));
+ (BOOL)isAuthenticated __attribute__((swift_name("isAuthenticated()")));
+ (NSString *)networkStatus __attribute__((swift_name("networkStatus()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BusinessBridgeSetupKt")))
@interface BusinessKitBusinessBridgeSetupKt : BusinessKitBase
+ (void)configureBusinessBridgeAuthDelegate:(id<KMPAuthDelegate>)authDelegate networkDelegate:(id<KMPNetworkDelegate>)networkDelegate __attribute__((swift_name("configureBusinessBridge(authDelegate:networkDelegate:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("FoundationCommonResponseResult")))
@interface BusinessKitFoundationCommonResponseResult : BusinessKitBase
- (instancetype)initWithCode:(int32_t)code body:(NSString *)body source:(BusinessKitFoundationCommonRequestPayload * _Nullable)source __attribute__((swift_name("init(code:body:source:)"))) __attribute__((objc_designated_initializer));
- (BusinessKitFoundationCommonResponseResult *)doCopyCode:(int32_t)code body:(NSString *)body source:(BusinessKitFoundationCommonRequestPayload * _Nullable)source __attribute__((swift_name("doCopy(code:body:source:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *body __attribute__((swift_name("body")));
@property (readonly) int32_t code __attribute__((swift_name("code")));
@property (readonly) BusinessKitFoundationCommonRequestPayload * _Nullable source __attribute__((swift_name("source")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("FoundationCommonRequestPayload")))
@interface BusinessKitFoundationCommonRequestPayload : BusinessKitBase
- (instancetype)initWithEndpoint:(NSString *)endpoint params:(NSDictionary<NSString *, NSString *> *)params __attribute__((swift_name("init(endpoint:params:)"))) __attribute__((objc_designated_initializer));
- (BusinessKitFoundationCommonRequestPayload *)doCopyEndpoint:(NSString *)endpoint params:(NSDictionary<NSString *, NSString *> *)params __attribute__((swift_name("doCopy(endpoint:params:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *endpoint __attribute__((swift_name("endpoint")));
@property (readonly) NSDictionary<NSString *, NSString *> *params __attribute__((swift_name("params")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("FoundationCommonSharedData")))
@interface BusinessKitFoundationCommonSharedData : BusinessKitBase
- (instancetype)initWithId:(int32_t)id message:(NSString *)message __attribute__((swift_name("init(id:message:)"))) __attribute__((objc_designated_initializer));
- (BusinessKitFoundationCommonSharedData *)doCopyId:(int32_t)id message:(NSString *)message __attribute__((swift_name("doCopy(id:message:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) NSString *message __attribute__((swift_name("message")));
@end

#pragma pop_macro("_Nullable_result")
#pragma clang diagnostic pop
NS_ASSUME_NONNULL_END
