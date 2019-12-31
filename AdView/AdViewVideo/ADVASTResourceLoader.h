//
//  ADVASTResourceLoader.h
//  AdViewVideoSample
//
//  Created by maming on 17/2/21.
//  Copyright © 2017年 maming. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "ADVASTRequestTask.h"

#define MimeType @"video/mp4"

@class ADVASTResourceLoader;
@protocol ADVASTResourceLoaderDelegate <NSObject>

@required
- (void)loader:(ADVASTResourceLoader*)loader cacheProgress:(CGFloat)progress;

@optional
- (void)loader:(ADVASTResourceLoader*)loader failLoadingWithError:(NSError *)error;

@end

@interface ADVASTResourceLoader : NSObject<AVAssetResourceLoaderDelegate,ADVASTRequestTaskDelegate>

@property (nonatomic, weak) id<ADVASTResourceLoaderDelegate> delegate;
@property (atomic, assign) BOOL seekRequired; // seek标识
@property (nonatomic, assign) BOOL cacheFinished;

- (void)stopLoading;

@end
