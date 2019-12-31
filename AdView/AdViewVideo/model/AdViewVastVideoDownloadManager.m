//
//  ADVASTVideoDownloadManager.m
//  AdViewVideoSample
//
//  Created by AdView on 17/2/17.
//  Copyright © 2017年 AdView. All rights reserved.
//

#import "AdViewVastVideoDownloadManager.h"
#import "AdViewVastRequestTask.h"
#import "AdViewVastFileHandle.h"

@interface AdViewVastVideoDownloadManager()<AdViewVastRequestTaskDelegate>

@property (nonatomic, assign) BOOL isFinished; // 数据缓存是否完成
@property (nonatomic, strong) NSMutableArray *taskArray;
@property (nonatomic, assign) int finishCount;

@end

@implementation AdViewVastVideoDownloadManager

- (instancetype)init {
    if (self = [super init]) {
        // 初始操作
        self.taskArray = [[NSMutableArray alloc] init];
        _finishCount = 0;
        _isMoreTask = NO;
    }
    return self;
}

- (void)dealloc {
    if (_taskArray != nil) {
        [_taskArray removeAllObjects];
    }
    _taskArray = nil;
}

- (void)addNewTastWithMediaFile:(AdViewVastMediaFile *)mediaFile {
    
    if (nil == mediaFile.url) {
        [self requestTaskDidFailWithError:nil task:nil]; // 如果url 为nil 则返回失败
        return;
    }
    
    NSString *cacheFilePath = [AdViewVastFileHandle cacheFileExistsWithURL:mediaFile.url];
    if (nil != cacheFilePath) {
        [self doWhenAllTaskFinished];
        return;
    }
    
    AdViewVastRequestTask *task = [[AdViewVastRequestTask alloc] init];
    task.requestUrl = mediaFile.url;
    task.type = mediaFile.fileType;
    task.requestOffset = 0;
    task.isCache = YES;
    task.delegate = self;
    [task start];
    [self.taskArray addObject:task];
}

- (void)addNewTaskWithUrl:(NSURL *)url {
    
    if (nil == url) {
        [self requestTaskDidFailWithError:nil task:nil]; // 如果url 为nil 则返回失败
        return;
    }
    
    NSString *cacheFilePath = [AdViewVastFileHandle cacheFileExistsWithURL:url];
    if (nil != cacheFilePath) {
        [self doWhenAllTaskFinished];
        return;
    }
    
    AdViewVastRequestTask *task = [[AdViewVastRequestTask alloc] init];
    task.requestUrl = url;
    task.requestOffset = 0;
    task.isCache = YES;
    task.delegate = self;
    [task start];
    [self.taskArray addObject:task];
}

- (void)addNewTaskWithArray:(NSArray *)array {
    _isMoreTask = YES;
    for (NSURL *url in array) {
        if (nil == url) {
            [self requestTaskDidFailWithError:nil task:nil]; // 如果url 为nil 则返回失败
            return;
        }
        
        NSString *cacheFilePath = [AdViewVastFileHandle cacheFileExistsWithURL:url];
        if (nil != cacheFilePath) {
            _finishCount++;
            if (_finishCount == array.count) {
                [self doWhenAllTaskFinished];
            }
            continue;
        }
        
        AdViewVastRequestTask *task = [[AdViewVastRequestTask alloc] init];
        task.requestUrl = url;
        task.requestOffset = 0;
        task.isCache = YES;
        task.delegate = self;
        [task start];
        [self.taskArray addObject:task];
    }
}

// 重置成员变量，以免下次使用造成误差
- (void)resetMembers {
    self.finishCount = 0;
    for (AdViewVastRequestTask *task in _taskArray) {
        [task setIsCancel:YES];
    }
    [self.taskArray removeAllObjects];
    self.taskArray = nil;
    _isMoreTask = NO;
}

// 检查所有任务是否都缓冲完毕，如果缓冲完执行响应操作操作
- (void)doWhenAllTaskFinished {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cacheTaskFinished)]) {
        [self resetMembers];
        [self.delegate cacheTaskFinished];
    }
}

#pragma mark - AdViewVastRequestTaskDelegate

- (void)requestTaskDidUpdateCache {}

- (void)requestTaskDidReceiveResponse {}

- (void)requestTaskDidFinishLoadingWithCache:(BOOL)cache task:(AdViewVastRequestTask *)task{
    _finishCount ++;
    if (self.finishCount == self.taskArray.count) {
        [self doWhenAllTaskFinished];
    }
    task = nil;
}

- (void)requestTaskDidFailWithError:(NSError *)error task:(AdViewVastRequestTask *)task{
    // 缓存失败(失败一个即认定为失败)
    if (self.delegate && [self.delegate respondsToSelector:@selector(cacheTaskFailedWithError:)]) {
        [self.delegate cacheTaskFailedWithError:error];
    }
    [self resetMembers];
}

@end
