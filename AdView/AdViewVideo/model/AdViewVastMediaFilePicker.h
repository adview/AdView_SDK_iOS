//
//  ADVASTMediaFilePicker.h
//  AdViewVideoSample
//
//  Created by AdView on 16/10/9.
//  Copyright © 2016年 AdView. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AdViewVastMediaFile.h"
@interface AdViewVastMediaFilePicker : NSObject

+ (AdViewVastMediaFile *)pick:(NSArray*)mediaFiles;
+ (BOOL)isMIMETypeCompatible:(AdViewVastMediaFile *)vastMediaFile;

@end
