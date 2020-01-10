//
//  AdViewVPAIDClient.m
//  AdViewSDK
//
//  Copyright (c) 2016 AdView. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "AdViewDefines.h"
#import "AdViewVPAIDClient.h"

const struct AdViewVPAIDViewModeStruct AdViewVPAIDViewMode = {
    .normal = @"normal",
    .thumbnail = @"thumbnail",
    .fullscreen = @"thumbnail"
};

#pragma mark - Class AdViewVPAIDClientProxy
@implementation AdViewVPAIDClientProxy
+ (instancetype)proxyWithTarget:(id)target
{
    return [[self alloc] initWithTarget:target];
}

- (instancetype)initWithTarget:(id)target
{
    _target = target;
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [self.target methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL sel = [invocation selector];
    if ([self.target respondsToSelector:sel])
    {
        [invocation invokeWithTarget:self.target];
    }
}

//重写几个反射机制方法.不然会有问题.比如判断isKindOfClass.消息转发传递进去的参数就是一个NSProxy.解决办法是这里改,或者消息转发时候把invocation的参数index = 2,修改为NSObject.class
- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [self.target respondsToSelector:aSelector];
}

- (BOOL)isKindOfClass:(Class)aClass
{
    if ([aClass isKindOfClass:[NSProxy class]])
        return YES;
    return [self.target isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass
{
    if ([aClass isMemberOfClass:[NSProxy class]])
        return YES;
    return [self.target isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return [self.target conformsToProtocol:aProtocol];
}
@end

#pragma mark - Class AdViewVPAIDClient
@interface AdViewVPAIDClient ()
@property (nonatomic, strong) JSContext *jsContext;
@property (nonatomic, strong) JSValue *vpaidWrapper;
@property (nonatomic, strong) NSTimer *actionTimeOutTimer;
@property (nonatomic, weak) id<AdViewVpaidProtocol> delegate;
@property (nonatomic, strong) AdViewVPAIDClientProxy * clientProxy;
@end

@implementation AdViewVPAIDClient

- (instancetype)initWithDelegate:(id<AdViewVpaidProtocol>)deleagate jsContext:(JSContext *)context
{
    if (self = [super init])
    {
        _delegate = deleagate;
        _jsContext = context;
        
        id log = ^(JSValue *msg) {AdViewLogDebug(@"JS Log: %@", msg);};
        _jsContext[@"console"][@"log"] = log;
        _jsContext[@"console"][@"info"] = log;
        _jsContext[@"console"][@"debug"] = log;
        _jsContext[@"console"][@"error"] = log;
        [_jsContext setExceptionHandler:^(JSContext *context, JSValue *value) {AdViewLogInfo(@"JS exception: %@", [value toString]);}];
        
        JSValue *getVPAIDWrapperFunc = _jsContext[@"getVPAIDWrapper"];
        _vpaidWrapper = [getVPAIDWrapperFunc callWithArguments:nil];
        
        /*
         * 防止内存泄漏、无法释放VideoGeneralView 和 VPAIDClient 两种方式:
         * 1.NSObject重写 - (id)forwardingTargetForSelector 并且遵循delegate的协议.但是会产生警告 协议未实现
         * 2.NSProxy 重写 - (void)forwardInvocation:(NSInvocation *)invocation.并且遵循delegate协议,不会产生警告
         */
        self.clientProxy = [AdViewVPAIDClientProxy proxyWithTarget:_delegate];
        [_vpaidWrapper invokeMethod:@"setVpaidClient" withArguments:@[_clientProxy]];
    }
    return self;
}

#pragma mark - Public

- (double)handshakeVersion {
    JSValue *version = [self.vpaidWrapper invokeMethod:@"handshakeVersion" withArguments:@[@"2.0"]];
    return [version toDouble];
}

- (void)initAdWithWidth:(int)width height:(int)height viewMode:(NSString *)viewMode desiredBitrate:(double)desiredBitrate creativeData:(NSDictionary *)creativeData environmentVars:(NSDictionary *)environmentVars {
    
    [self invokeVpaidMethod:@"initAd" withArguments:[NSArray arrayWithObjects:@(width), @(height), viewMode, @(desiredBitrate), creativeData, environmentVars, nil]];
}

- (void)resizeAdWithWidth:(int)width height:(int)height viewMode:(NSString *)viewMode {
    [self.vpaidWrapper invokeMethod:@"resizeAd" withArguments:[NSArray arrayWithObjects:@(width), @(height), viewMode, nil]];
}

- (void)startAd {
    [self invokeVpaidMethod:@"startAd" withArguments:nil];
}

- (void)stopAd {
    [self invokeVpaidMethod:@"stopAd" withArguments:nil];
}

- (void)pauseAd {
    [self.vpaidWrapper invokeMethod:@"pauseAd" withArguments:nil];
}

- (void)resumeAd {
    [self.vpaidWrapper invokeMethod:@"resumeAd" withArguments:nil];
}

- (void)expandAd {
    [self.vpaidWrapper invokeMethod:@"expandAd" withArguments:nil];
}

- (void)collapseAd {
    [self.vpaidWrapper invokeMethod:@"collapseAd" withArguments:nil];
}

- (void)skipAd {
    [self.vpaidWrapper invokeMethod:@"skipAd" withArguments:nil];
}

- (BOOL)getAdExpanded {
    return [[self.vpaidWrapper invokeMethod:@"getAdExpanded" withArguments:nil] toBool];
}

- (BOOL)getAdSkippableState {
    return [[self.vpaidWrapper invokeMethod:@"getAdSkippableState" withArguments:nil] toBool];
}

- (BOOL)getAdLinear {
    return [[self.vpaidWrapper invokeMethod:@"getAdLinear" withArguments:nil] toBool];
}

- (NSInteger)getAdWidth {
    return [[self.vpaidWrapper invokeMethod:@"getAdWidth" withArguments:nil] toInt32];
}

- (NSInteger)getAdHeight {
    return [[self.vpaidWrapper invokeMethod:@"getAdHeight" withArguments:nil] toInt32];
}

- (NSInteger)getAdRemainingTime {
    return [[self.vpaidWrapper invokeMethod:@"getAdRemainingTime" withArguments:nil] toInt32];
}

- (NSInteger)getAdDuration {
    return [[self.vpaidWrapper invokeMethod:@"getAdDuration" withArguments:nil] toInt32];
}

- (double)getAdVolume {
    return [[self.vpaidWrapper invokeMethod:@"getAdVolume" withArguments:nil] toDouble];
}

- (void)setAdVolume:(double)volume {
    [self.vpaidWrapper invokeMethod:@"setAdVolume" withArguments:@[@(volume)]];
}

- (NSString *)getAdViewanions {
    return [[self.vpaidWrapper invokeMethod:@"getAdViewanions" withArguments:nil] toString];
}

- (BOOL)getAdIcons {
    return [[self.vpaidWrapper invokeMethod:@"getAdIcons" withArguments:nil] toBool];
}

- (void)stopActionTimeOutTimer {
    [self.actionTimeOutTimer invalidate];
    self.actionTimeOutTimer = nil;
}
#pragma mark - private

- (JSValue *)invokeVpaidMethod:(NSString *)method withArguments:(NSArray *)arguments {
    self.actionTimeOutTimer = [NSTimer scheduledWeakTimerWithTimeInterval:5 target:self selector:@selector(actionTimeOut:) userInfo:method repeats:NO];
    return [self.vpaidWrapper invokeMethod:method withArguments:arguments];
}

- (void)actionTimeOut:(NSString *)userInfo
{
    NSString *action = userInfo;
    if ([action isEqualToString:@"initAd"] || [action isEqualToString:@"stoptAd"])
    {
        [self.delegate vpaidJSError:[NSString stringWithFormat:@"%@ timeout", action]];
    }
    else if ([action isEqualToString:@"startAd"])
    {
        [self stopAd];
    }
    else
    {
        [self.delegate vpaidAdStopped];
    }
}

- (void)dealloc
{
    AdViewLogDebug(@"%s",__FUNCTION__);
    self.delegate = nil;
    self.clientProxy = nil;
    self.jsContext = nil;
    self.vpaidWrapper = nil;
    self.actionTimeOutTimer = nil;
}

@end
