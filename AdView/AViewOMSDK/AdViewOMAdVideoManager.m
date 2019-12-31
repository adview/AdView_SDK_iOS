//
//  ADVGOMAdVideoManager.m
//  AdViewHello
//
//  Created by unakayou on 7/24/19.
//

#import "AdViewOMAdVideoManager.h"

@interface AdViewOMAdVideoManager()
@property (nonatomic, strong, readwrite) OMIDAdviewVideoEvents * videoEvent;
@property (nonatomic, assign, readwrite) AdViewOMSDKVideoQuartile quartile;
@end

@implementation AdViewOMAdVideoManager

- (instancetype)init {
    if (self = [super init]) {
        self.vendorKey = _vendorKey;
        self.verificationScriptURLString = VerificationScriptURLString;
        self.verificationParameters = VerificationParameters;
    }
    return self;
}

- (instancetype)initWithVendorKey:(NSString *)vendor
           verificationParameters:(NSString *)verificationParameters
      verificationScriptURLString:(NSString *)verificationScriptURLString {
    if (self = [super init]) {
        self.vendorKey = vendor.length ? vendor : VendorKey;
        self.verificationParameters = verificationParameters.length ? verificationParameters : VerificationParameters;
        self.verificationScriptURLString = verificationScriptURLString.length ? verificationScriptURLString : VerificationScriptURLString;
        self.quartile = AdViewOMSDKVideoQuartile_None;
    }
    return self;
}

- (void)dealloc {
    AdViewLogInfo(@"%s",__FUNCTION__);
}

- (void)startMeasurement {
    Class OMIDAdviewVASTPropertiesClass = NSClassFromString(@"OMIDAdviewVASTProperties");
    if (!OMIDAdviewVASTPropertiesClass) {
        return;
    }

    [super startMeasurement];
    OMIDAdviewVASTProperties * properties = nil;
    if (_skipOffset) {
        properties = [[OMIDAdviewVASTPropertiesClass alloc] initWithSkipOffset:_skipOffset autoPlay:_autoPlay position:_position];
    } else {
        properties = [[OMIDAdviewVASTPropertiesClass alloc] initWithAutoPlay:_autoPlay position:_position];
    }
    [_videoEvent loadedWithVastProperties:properties];
}

- (void)reportQuartileChange:(AdViewOMSDKVideoQuartile)quartile {
    self.quartile = quartile;
    switch (self.quartile) {
        case AdViewOMSDKVideoQuartile_None:
            break;
        case AdViewOMSDKVideoQuartile_Start:
            [_videoEvent startWithDuration:_duration videoPlayerVolume:_volume];
            break;
        case AdViewOMSDKVideoQuartile_FirstQuartile:    // 1/4
            [_videoEvent firstQuartile];
            break;
        case AdViewOMSDKVideoQuartile_Midpoint:         // 1/2
            [_videoEvent midpoint];
            break;
        case AdViewOMSDKVideoQuartile_ThirdQuartile:    // 3/4
            [_videoEvent thirdQuartile];
            break;
        case AdViewOMSDKVideoQuartile_Complete:
            [_videoEvent complete];
            break;
        default:
            break;
    }
}

- (void)adUserInteractionWithType:(OMIDInteractionType)interactionType {
    [_videoEvent adUserInteractionWithType:interactionType];
}

- (void)skipped {
    [_videoEvent skipped];
}

- (void)pause {
    [_videoEvent pause];
}

- (void)resume {
    [_videoEvent resume];
}

- (void)volumeChangeTo:(CGFloat)playerVolume {
    [_videoEvent volumeChangeTo:playerVolume];
}

- (void)videoOrientation:(UIInterfaceOrientation)orientation {
    switch (orientation) {
        case UIInterfaceOrientationUnknown:
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            [_videoEvent playerStateChangeTo:OMIDPlayerStateNormal];
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            [_videoEvent playerStateChangeTo:OMIDPlayerStateFullscreen];
            break;
        default:
            break;
    }
}

//初始化videoEvent
- (void)setupAdditionalAdEvents:(OMIDAdviewAdSession *)addSession {
    Class OMIDAdviewVideoEventsClass = NSClassFromString(@"OMIDAdviewVideoEvents");
    if (!OMIDAdviewVideoEventsClass) {
        return;
    }
    NSError * videoEventError = nil;
    self.videoEvent = [[OMIDAdviewVideoEventsClass alloc] initWithAdSession:addSession error:&videoEventError];
    if (videoEventError) {
        AdViewLogInfo(@"%s - %@", __FUNCTION__, videoEventError);
    }
}

- (OMIDAdviewAdSessionConfiguration *)createAdSessionConfiguration {
    Class OMIDAdviewAdSessionConfigurationClass = NSClassFromString(@"OMIDAdviewAdSessionConfiguration");
    if (!OMIDAdviewAdSessionConfigurationClass) {
        return nil;
    }
    NSError * configError = nil;
    OMIDAdviewAdSessionConfiguration * config = [[OMIDAdviewAdSessionConfigurationClass alloc] initWithImpressionOwner:OMIDNativeOwner
                                                                                                      videoEventsOwner:OMIDNativeOwner isolateVerificationScripts:NO
                                                                                                                 error:&configError];
    if (configError) {
        AdViewLogInfo(@"%s - %@",__FUNCTION__, configError);
    }
    return config;
}

- (OMIDAdviewAdSessionContext *)createAdSessionContextWithPartner:(OMIDAdviewPartner *)partner {
    NSError * contextError = nil;
    OMIDAdviewVerificationScriptResource * verficationScriptRes = [self createVerificationScriptResourceVendorKey:_vendorKey
                                                                                            verificationScriptURL:_verificationScriptURLString
                                                                                                       parameters:_verificationParameters];
    Class OMIDAdviewAdSessionContextClass = NSClassFromString(@"OMIDAdviewAdSessionContext");
    if (!OMIDAdviewAdSessionContextClass) {
        return nil;
    }
    OMIDAdviewAdSessionContext * context = [[OMIDAdviewAdSessionContextClass alloc] initWithPartner:partner
                                                                                             script:[AdViewOMAdVideoManager OMIDService]
                                                                                          resources:@[verficationScriptRes]
                                                                          customReferenceIdentifier:nil
                                                                                              error:&contextError];
    if (contextError) {
        AdViewLogInfo(@"%s - %@",__FUNCTION__, contextError);
    }
    return context;
}

@end
