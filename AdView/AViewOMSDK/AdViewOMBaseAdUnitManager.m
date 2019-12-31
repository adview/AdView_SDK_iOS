//
//  ADVGOMBaseAdUnitManager.m
//  AdViewHello
//
//  Created by unakayou on 7/24/19.
//

#import "AdViewOMBaseAdUnitManager.h"

NSString * const ADVGOSDKPartnerNameString = @"Adview";
NSString * VendorKey = @"iabtechlab.com-omid";
NSString * VerificationScriptURLString = @"http://s3-us-west-2.amazonaws.com/omsdk-files/demo/creative/omid-validation-verification-script-v1.js";
NSString * VerificationParameters = @"";
NSString * const OMIDSDKVersion = @"{\"v\":\"1.2.15\",\"a\":\"1\"}";

@interface AdViewOMBaseAdUnitManager()
@property (nonatomic, strong, readwrite) OMIDAdviewAdEvents * OMIDAdEvent;
@property (nonatomic, strong, readwrite) OMIDAdviewAdSession * OMIDAdSession;
@end

@implementation AdViewOMBaseAdUnitManager

+ (BOOL)isActive {
    Class OMIDAdViewSDKClass = NSClassFromString(@"OMIDAdviewSDK");
    return [[OMIDAdViewSDKClass sharedInstance] isActive];
}

+ (BOOL)activateOMIDSDK {
    Class OMIDAdViewSDKClass = NSClassFromString(@"OMIDAdviewSDK");
    if (OMIDAdViewSDKClass) {
        OMIDAdviewSDK * OMIDSDK = [OMIDAdViewSDKClass sharedInstance];
        if (![OMIDSDK isActive]) {
            NSError * activeError = nil;
            BOOL bActive = [OMIDSDK activateWithOMIDAPIVersion:OMIDSDKAPIVersionString error:&activeError];
            if (!bActive) {
                AdViewLogInfo(@"%@",activeError);
            }
            return bActive;
        }
        return [OMIDSDK isActive];
    } else {
        AdViewLogInfo(@"%s - OMDSK does not exits",__FUNCTION__);
        return NO;
    }
}

+ (NSString *)OMIDService {
    NSString * omsdkJSPath = [self pathForFrameworkResource:@"omsdk-v1" ofType:@"js"];
    NSString * omsdkJSString = [[NSString alloc] initWithContentsOfFile:omsdkJSPath encoding:NSUTF8StringEncoding error:nil];
    return omsdkJSString;
}

- (instancetype)init {
    Class OMIDAdViewSDKClass = NSClassFromString(@"OMIDAdviewSDK");
    if (OMIDAdViewSDKClass) {
        if (![OMIDAdViewSDKClass isCompatibleWithOMIDAPIVersion:OMIDSDKVersion]) nil;
        
        if (self = [super init]) {
            if (OMIDAdViewSDKClass) {
                _OMAdViewSDK = [OMIDAdViewSDKClass sharedInstance];
            }
        }
    } else {
        AdViewLogInfo(@"%s - OMDSK does not exits",__FUNCTION__);
    }
    return self;
}

- (void)setMainAdview:(UIView *)adview {
    if (adview) {
        self.OMIDAdSession.mainAdView = adview;
    }
}

- (void)setFriendlyObstruction:(UIView *)view {
    if (view) {
        [self.OMIDAdSession addFriendlyObstruction:view];
    }
}

//设置video的event,开始监测,发送展示
- (void)startMeasurement {
    //这个顺序可以吗?先初始化video的event,再start,再设置普通event,发送展示
    [self setupAdditionalAdEvents:self.OMIDAdSession];
    [self.OMIDAdSession start];
    [self reportimpression];
}

//监测完毕
- (void)finishMeasurement {
    [self.OMIDAdSession finish];
    [NSThread sleepForTimeInterval:0.5];
}

//发送展示
- (BOOL)reportimpression {
    NSError * impressionError = nil;
    BOOL success = [self.OMIDAdEvent impressionOccurredWithError:&impressionError];
    if (!success) {
        AdViewLogInfo(@"%s - %@",__FUNCTION__, impressionError);
    }
    return success;
}

- (OMIDAdviewVerificationScriptResource *)createVerificationScriptResourceVendorKey:(NSString *)vendorKeyString
                                                              verificationScriptURL:(NSString *)verificationScriptURLString
                                                                         parameters:(NSString *)parametersString {
    verificationScriptURLString = [verificationScriptURLString stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSURL * verificationScriptURL = [NSURL URLWithString:verificationScriptURLString];
    if (!verificationScriptURL) return nil;
    
    Class OMIDAdviewVerificationScriptResourceClass = NSClassFromString(@"OMIDAdviewVerificationScriptResource");
    if (OMIDAdviewVerificationScriptResourceClass) {
        if (vendorKeyString && parametersString && vendorKeyString.length && parametersString.length) {
            return [[OMIDAdviewVerificationScriptResourceClass alloc] initWithURL:verificationScriptURL vendorKey:vendorKeyString parameters:parametersString];
        } else {
            return [[OMIDAdviewVerificationScriptResourceClass alloc] initWithURL:verificationScriptURL];
        }
    }
    return nil;
}

- (OMIDAdviewAdSessionContext *)createAdSessionContextWithPartner:(OMIDAdviewPartner *)partner {
    return nil;
}

- (OMIDAdviewAdSessionConfiguration *)createAdSessionConfiguration {
    return nil;
}

- (void)setupAdditionalAdEvents:(OMIDAdviewAdSession *)addSession {
    return;
}

- (void)logErrorWithType:(OMIDErrorType)errorType message:(nonnull NSString *)message {
    [_OMIDAdSession logErrorWithType:errorType message:message];
}

#pragma mark - getter
- (OMIDAdviewAdSession *)OMIDAdSession {
    if (!_OMIDAdSession) {
        Class OMIDAdViewSDKClass = NSClassFromString(@"OMIDAdviewSDK");
        Class OMIDAdviewPartnerClass = NSClassFromString(@"OMIDAdviewPartner");
        Class OMIDAdviewAdSessionClass = NSClassFromString(@"OMIDAdviewAdSession");

        BOOL bCompatible = [OMIDAdViewSDKClass isCompatibleWithOMIDAPIVersion:OMIDSDKVersion];
        if (!bCompatible) {
            AdViewLogInfo(@"OMSDK - not compatible");
            return nil;
        }

        if (OMIDAdviewPartnerClass && OMIDAdviewAdSessionClass) {
            OMIDAdviewPartner * partner = [[OMIDAdviewPartnerClass alloc] initWithName:ADVGOSDKPartnerNameString
                                                                         versionString:ADVIEWSDK_PARTENER_VERSION];
            OMIDAdviewAdSessionContext * adSessionContext = [self createAdSessionContextWithPartner:partner];
            OMIDAdviewAdSessionConfiguration * adSessionConfiguration = [self createAdSessionConfiguration];
            
            NSError * sessionError = nil;
            _OMIDAdSession = [[OMIDAdviewAdSessionClass alloc] initWithConfiguration:adSessionConfiguration
                                                                    adSessionContext:adSessionContext
                                                                               error:&sessionError];
            if (sessionError) {
                _OMIDAdSession = nil;
                AdViewLogInfo(@"%s - %@", __FUNCTION__, sessionError);
            }
        } else {
            AdViewLogInfo(@"%s - OMDSK does not exits",__FUNCTION__);
        }
    }
    return _OMIDAdSession;
}

- (OMIDAdviewAdEvents *)OMIDAdEvent {
    if (!_OMIDAdEvent) {
        Class OMIDAdviewAdEventsClass = NSClassFromString(@"OMIDAdviewAdEvents");
        if (OMIDAdviewAdEventsClass) {
            NSError * eventError = nil;
            _OMIDAdEvent = [[OMIDAdviewAdEventsClass alloc] initWithAdSession:self.OMIDAdSession error:&eventError];
            
            if (eventError) {
                _OMIDAdEvent = nil;
                AdViewLogInfo(@"%s - %@",__FUNCTION__, eventError);
            }
        } else {
            AdViewLogInfo(@"%s - OMDSK does not exits",__FUNCTION__);
        }
    }
    return _OMIDAdEvent;
}

@end
