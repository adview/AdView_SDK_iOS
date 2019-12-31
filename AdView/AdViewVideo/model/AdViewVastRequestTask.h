//
//  ADVASTRequestTask.h
//  AdViewVideoSample
//
//  Created by AdView on 17/2/17.
//  Copyright © 2017年 AdView. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AdViewVastMediaFile.h"

@class AdViewVastRequestTask;

@protocol AdViewVastRequestTaskDelegate <NSObject>

@required
- (void)requestTaskDidUpdateCache; //更新缓冲进度代理方法

@optional
- (void)requestTaskDidReceiveResponse;
- (void)requestTaskDidFinishLoadingWithCache:(BOOL)cache task:(AdViewVastRequestTask*)task;
- (void)requestTaskDidFailWithError:(NSError *)error task:(AdViewVastRequestTask*)task;

@end

@interface AdViewVastRequestTask : NSObject

@property (nonatomic, weak) id<AdViewVastRequestTaskDelegate> delegate;
@property (nonatomic, strong) NSURL *requestUrl;        //请求地址
@property (nonatomic, assign) NSUInteger requestOffset; //请求起始位置
@property (nonatomic, assign) NSUInteger fileLength;    //文件长度
@property (nonatomic, assign) NSUInteger cacheLength;   //缓冲长度
@property (nonatomic, assign) BOOL isCache;             //是否缓存文件
@property (nonatomic, assign) BOOL isCancel;            //是否取消请求
@property (nonatomic, assign) ADVASTMediaFileType type; // 文件类型

- (void)start;

@end

