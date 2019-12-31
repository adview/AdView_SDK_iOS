//
//  ADVGURLSessionManager.h
//  AdViewHello
//
//  Created by unakayou on 7/14/19.
//  请求管理器

#import <Foundation/Foundation.h>
#import "AdViewDefines.h"
#import "ADVGResponseSerializer.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 回调Block
/**
 请求回调Block

 @param response 响应
 @param object 模型
 @param error 错误
 */
typedef void (^ADVGSessionTaskCompletionHandler)(NSURLResponse *response, id object, NSError *error);

/**
 下载位置Block

 @param downloadTask 任务
 @param location 临时位置
 @return 保存位置
 */
typedef NSURL * _Nullable (^ADVGSessionDownloadTaskDestinationBlock)(NSURLSessionDownloadTask *downloadTask, NSURL *location);

#pragma mark - Session协议
@protocol ADVGURLSessionManagerProtocol <NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>

@end

#pragma mark - SessionManager
@interface ADVGURLSessionManager : NSObject <NSURLSessionDataDelegate, NSURLSessionDownloadDelegate,NSCopying>

/**
 接收delegate回调
 */
@property (nonatomic, weak) id <ADVGURLSessionManagerProtocol> delegate;

/**
 负责解析的对象 必须遵循协议
 */
@property (nonatomic, strong) id <ADVGResponseSerializationProcotol> responseSerializer;

/**
 管理的sesiion
 */
@property (nonatomic, strong, readonly) NSURLSession * session;

/**
 delegate回调所在队列(主 or 其他)
 */
@property (nonatomic, strong, readonly) NSOperationQueue * operationQueue;

/**
 完成回调时所在线程队列
 */
@property (nonatomic, strong, nullable) dispatch_queue_t completionQueue;

/**
 完成回调时的组
 */
@property (nonatomic, strong, nullable) dispatch_group_t completionGroup;


/**
 不同类型的任务 暂无上传任务
 */
@property (readonly, nonatomic, strong) NSArray <NSURLSessionTask *> *tasks;
@property (readonly, nonatomic, strong) NSArray <NSURLSessionDataTask *> *dataTasks;
@property (readonly, nonatomic, strong) NSArray <NSURLSessionUploadTask *> *uploadTasks;
@property (readonly, nonatomic, strong) NSArray <NSURLSessionDownloadTask *> *downloadTasks;

/**
 初始化方法

 @param configuration 被Manager管理的session需要的设置
 @return 返回Manager
 */
- (instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

/**
 停止任务 重制session

 @param cancelPendingTasks 停止任务
 @param resetSession 重制session
 */
- (void)invalidateSessionCancelingTasks:(BOOL)cancelPendingTasks resetSession:(BOOL)resetSession;

/**
 数据数据

 @param request NSURLRequest
 @param completionHandler 完成回调
 @return DataTask
 */
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(ADVGSessionTaskCompletionHandler)completionHandler;

/**
 下载请求

 @param request NSURLRequest
 @param destination 设置下载文件保存路径 URL:返回一个需要移动到的目录位置 targetPath:当前文件所处位置 response:请求信息
 @param completionHandler 完成回调
 @return DownloadTask
 */
- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                          destination:(ADVGSessionDownloadTaskDestinationBlock)destination
                                    completionHandler:(ADVGSessionTaskCompletionHandler)completionHandler;
@end

NS_ASSUME_NONNULL_END
