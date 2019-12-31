//
//  ADConnectDataProcessor.h
//  AdViewVideoSample
//
//  Created by AdView on 15-4-8.
//  Copyright (c) 2015年 AdView. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADURLConnection.h"
#import "ADVideoData.h"

@interface ADConnectDataProcessor : NSObject

- (NSURLRequest*)getVideoRequest:(AVTemporaryData*)tempData;

- (BOOL)parseResponse:(NSData*)data Error:(NSError*)error withVideoData:(ADVideoData*)videoData;

@end
