//
//  ADVGOMAdImageManager.h
//  AdViewHello
//
//  Created by unakayou on 7/24/19.
//

#import "AdViewOMBaseAdUnitManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface AdViewOMAdImageManager : AdViewOMBaseAdUnitManager
@property (nonatomic, copy, readonly) NSString * vendorKey;
@property (nonatomic, copy, readonly) NSString * verificationScriptURLString;
@property (nonatomic, copy, readonly) NSString * verificationParameters;

- (instancetype)initWithVendorKey:(NSString *)vendor
           verificationParameters:(NSString *)verificationParameters
      verificationScriptURLString:(NSString *)verificationScriptURLString;
@end

NS_ASSUME_NONNULL_END
