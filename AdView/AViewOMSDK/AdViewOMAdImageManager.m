//
//  ADVGOMAdImageManager.m
//  AdViewHello
//
//  Created by unakayou on 7/24/19.
//

#import "AdViewOMAdImageManager.h"
@interface AdViewOMAdImageManager()
@property (nonatomic, copy, readwrite) NSString * vendorKey;
@property (nonatomic, copy, readwrite) NSString * verificationScriptURLString;
@property (nonatomic, copy, readwrite) NSString * verificationParameters;
@end

@implementation AdViewOMAdImageManager

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
    }
    return self;
}

- (void)dealloc {
    AdViewLogInfo(@"%s",__FUNCTION__);
}

- (OMIDAdviewAdSessionConfiguration *)createAdSessionConfiguration {
    Class OMIDAdviewAdSessionConfigurationClass = NSClassFromString(@"OMIDAdviewAdSessionConfiguration");
    if (!OMIDAdviewAdSessionConfigurationClass) {
        return nil;
    }
    NSError * configError = nil;
    OMIDAdviewAdSessionConfiguration * configuration = [[OMIDAdviewAdSessionConfigurationClass alloc] initWithImpressionOwner:OMIDNativeOwner
                                                                                                             videoEventsOwner:OMIDNoneOwner
                                                                                                   isolateVerificationScripts:NO
                                                                                                                        error:&configError];
    if (configError) {
        AdViewLogInfo(@"%s - %@",__FUNCTION__,configError);
    }
    return configuration;
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
                                                                                             script:[AdViewOMAdImageManager OMIDService]
                                                                                          resources:@[verficationScriptRes]
                                                                          customReferenceIdentifier:nil
                                                                                              error:&contextError];
    return context;
}

@end
