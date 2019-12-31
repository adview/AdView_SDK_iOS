//
//  ADVASTVideoDownloadManager.h
//  AdViewVideoSample
//
//  Created by AdView on 17/2/17.
//  Copyright © 2017年 AdView. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AdViewVastRequestTask.h"
#import "AdViewVastMediaFile.h"

@protocol AdViewVastVideoDownloadManagerDelegate <NSObject>

// 任务缓存失败
- (void)cacheTaskFailedWithError:(NSError*)error;

// 任务缓存完成
- (void)cacheTaskFinished;

@end

@interface AdViewVastVideoDownloadManager : NSObject

@property (nonatomic, assign) BOOL isMoreTask; // 是否为多个任务；
@property (nonatomic, weak) id<AdViewVastVideoDownloadManagerDelegate> delegate;

- (instancetype)init;

- (void)addNewTastWithMediaFile:(AdViewVastMediaFile *)mediaFile;

// 添加新任务->url
- (void)addNewTaskWithUrl:(NSURL*)url;

// 添加新任务->多个url
- (void)addNewTaskWithArray:(NSArray*)array;

@end
