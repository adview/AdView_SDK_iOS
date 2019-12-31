//
//  ADVGURLSessionManager.m
//  AdViewHello
//
//  Created by unakayou on 7/14/19.
//

#import "ADVGURLSessionManager.h"

//解析队列
static dispatch_queue_t url_session_manager_processing_queue() {
    static dispatch_queue_t url_session_manager_processing_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        url_session_manager_processing_queue = dispatch_queue_create("com.AdView.networking.session.manager.processing", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return url_session_manager_processing_queue;
}

//默认解析回调组
static dispatch_group_t url_session_manager_completion_group() {
    static dispatch_group_t advg_url_session_manager_completion_group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        advg_url_session_manager_completion_group = dispatch_group_create();
    });
    return advg_url_session_manager_completion_group;
}

#pragma mark - ADVGURLSessionManagerTaskHandler 用于处理某个Task
@interface ADVGURLSessionManagerTaskHandler : NSObject  <NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>
@property (nonatomic, strong) NSMutableData * taskData;                                             //数据累加容器
@property (nonatomic, copy) NSURL * downloadFileURL;                                                //下载文件保存路径
@property (nonatomic, weak) ADVGURLSessionManager * sessionManager;                                 //会话mananger
@property (nonatomic, copy) ADVGSessionTaskCompletionHandler completionHandler;                     //任务请求完毕Block
@property (nonatomic, copy) ADVGSessionDownloadTaskDestinationBlock downloadTaskDestinationBlock;   //获取下载文件转存位置Block

- (instancetype)initWithTask:(NSURLSessionTask *)task;
@end

@implementation ADVGURLSessionManagerTaskHandler

#pragma mark - Handler 初始化
//task暂时没有用到
- (instancetype)initWithTask:(NSURLSessionTask *)task {
    if (self = [super init]) {
        self.taskData = [NSMutableData data];
    }
    return self;
}

#pragma mark - Handler的URLSession回调
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [_taskData appendData:data];
}

- (void)URLSession:(__unused NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSData * tmpData = nil;
    __block id responseObject = nil;
    ADVGURLSessionManager * manager = self.sessionManager;
    
    if (_taskData) {
        tmpData = [_taskData copy];
        self.taskData = nil;
    }
    
    //如果Error不为空,直接报错
    if (error) {
        dispatch_group_async(self.sessionManager.completionGroup ?: url_session_manager_completion_group(), self.sessionManager.completionQueue ?: dispatch_get_main_queue(), ^{
            if (self.completionHandler) {
                self.completionHandler(task.response,responseObject,error);
            }
        });
    } else {
        //如果Error为空,并发队列解析数据
        dispatch_async(url_session_manager_processing_queue(), ^{
            NSError * serializationError = nil; //解析错误
            responseObject = [manager.responseSerializer responseObjectForResponse:task.response data:tmpData error:&serializationError];
            //如果下载的文件有转存位置,则返回这个位置作为结果
            if (self.downloadFileURL) {
                responseObject = self.downloadFileURL;
            }
            
            //如果用户需要监听请求完毕Group或者自定义返回线程
            dispatch_group_async(self.sessionManager.completionGroup ?: url_session_manager_completion_group(),
                                 self.sessionManager.completionQueue ?: dispatch_get_main_queue(), ^{
                                     if (self.completionHandler) {
                                         self.completionHandler(task.response,responseObject,serializationError);
                                     }
                                 });
        });
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    if (self.downloadTaskDestinationBlock) {
        NSError *error = nil;
        self.downloadFileURL = self.downloadTaskDestinationBlock(downloadTask, location);   //如果用户提供了转存路径
        if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:_downloadFileURL error:&error]) {
            //如果提供的转存路径无法转存文件,则设置文件路径为未转存位置并执行 -(void)URLSession:task:didCompleteWithError:
            self.downloadFileURL = location;
            AdViewLogInfo(@"%s - %@",__FUNCTION__,error); //如果转存失败downloadFileURL置空
        }
    }
}

- (void)dealloc {
    AdViewLogInfo(@"%s",__FUNCTION__);
}
@end

#pragma mark - ADVGURLSessionManager
@interface ADVGURLSessionManager() 
@property (nonatomic, strong, readwrite) NSURLSession * session;
@property (nonatomic, strong, readwrite) NSOperationQueue *operationQueue;
@property (nonatomic, strong, readwrite) NSURLSessionConfiguration *sessionConfiguration;

//一个Task对应一个Handler,处理数据,保存NSData等逻辑.
@property (nonatomic, strong, readwrite) NSMutableDictionary <NSNumber *, ADVGURLSessionManagerTaskHandler *>* taskHandlerAssociateDict;
@end

@implementation ADVGURLSessionManager

#pragma mark - 初始化和销毁方法
- (instancetype)init {
    return [self initWithSessionConfiguration:nil];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration {
    if (self = [super init]) {
        if (!configuration) {
            configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        }
        self.sessionConfiguration = configuration;
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        self.taskHandlerAssociateDict = [NSMutableDictionary new];
        self.responseSerializer = [ADVGJSONResponseSerializer serializer];
    }
    return self;
}

- (void)invalidateSessionCancelingTasks:(BOOL)cancelPendingTasks resetSession:(BOOL)resetSession {
    if (cancelPendingTasks) {
        [self.session invalidateAndCancel];
    } else {
        [self.session finishTasksAndInvalidate];
    }
    if (resetSession) {
        self.session = nil;
    }
}

#pragma mark - DataTask请求
//在这里初始化一个DataTask,并绑定Task与Handler.等待resume后delegate回调
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(ADVGSessionTaskCompletionHandler)completionHandler {
    //获取Request对应的DataTask
    NSURLSessionDataTask * dataTask = [self.session dataTaskWithRequest:request];
    
    //生成一个新的Handler
    ADVGURLSessionManagerTaskHandler * handler = [[ADVGURLSessionManagerTaskHandler alloc] initWithTask:dataTask];
    handler.sessionManager = self;
    handler.completionHandler = completionHandler;
    
    //设置DataTask与Handler关联
    [self associateTask:dataTask withHandler:handler];
    return dataTask;
}

#pragma mark - DownloadTask请求
//在这里初始化一个DownloadTask,并绑定Task与Handler.等待resume后delegate回调
- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                          destination:(ADVGSessionDownloadTaskDestinationBlock)destination completionHandler:(ADVGSessionTaskCompletionHandler)completionHandler {
    NSURLSessionDownloadTask * downloadTask = [self.session downloadTaskWithRequest:request];
    
    ADVGURLSessionManagerTaskHandler * handler = [[ADVGURLSessionManagerTaskHandler alloc] initWithTask:downloadTask];
    handler.sessionManager = self;
    handler.completionHandler = completionHandler;
    handler.downloadTaskDestinationBlock = destination;
    
    [self associateTask:downloadTask withHandler:handler];
    return downloadTask;
}

#pragma mark - session getter
- (NSURLSession *)session {
    @synchronized (self) {
        if (!_session) {
            _session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration delegate:self delegateQueue:self.operationQueue];
        }
    }
    return _session;
}

#pragma mark - Data & Handler
//设置DataTask与Handler关联
- (void)associateTask:(NSURLSessionTask *)task withHandler:(ADVGURLSessionManagerTaskHandler *)handler {
    @synchronized (_taskHandlerAssociateDict) {
        _taskHandlerAssociateDict[@(task.taskIdentifier)] = handler;
    }
}

//根据Task获取Handler
- (ADVGURLSessionManagerTaskHandler *)handlerForTask:(NSURLSessionTask *)task {
    @synchronized (_taskHandlerAssociateDict) {
        return _taskHandlerAssociateDict[@(task.taskIdentifier)];
    }
}

//删除已完成的Task的Handler
- (void)removeHandlerForTask:(NSURLSessionTask *)task {
    @synchronized (_taskHandlerAssociateDict) {
        [_taskHandlerAssociateDict removeObjectForKey:@(task.taskIdentifier)];
    }
}

#pragma mark - 各种 Task getter
- (NSArray *)tasks {
    return [self tasksForKeyPath:NSStringFromSelector(_cmd)];
}

- (NSArray *)dataTasks {
    return [self tasksForKeyPath:NSStringFromSelector(_cmd)];
}

- (NSArray *)uploadTasks {
    return [self tasksForKeyPath:NSStringFromSelector(_cmd)];
}

- (NSArray *)downloadTasks {
    return [self tasksForKeyPath:NSStringFromSelector(_cmd)];
}

- (NSArray *)tasksForKeyPath:(NSString *)keyPath {
    __block NSArray *tasks = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(dataTasks))]) {
            tasks = dataTasks;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(uploadTasks))]) {
            tasks = uploadTasks;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(downloadTasks))]) {
            tasks = downloadTasks;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(tasks))]) {
            tasks = [@[dataTasks, uploadTasks, downloadTasks] valueForKeyPath:@"@unionOfArrays.self"];
        }
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return tasks;
}

#pragma mark - URLSession data delegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    //收到的Data交给Handler进行拼接
    ADVGURLSessionManagerTaskHandler * taskHandler = [self handlerForTask:dataTask];
    [taskHandler URLSession:session dataTask:dataTask didReceiveData:data];
    
    if ([_delegate respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)]) {
        [_delegate URLSession:session dataTask:dataTask didReceiveData:data];
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    if ([_delegate respondsToSelector:@selector(URLSession:dataTask:didReceiveResponse:completionHandler:)]) {
        [_delegate URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
    } else {
        completionHandler(NSURLSessionResponseAllow);
    }
}

#pragma mark - URLSession Task delegate
//请求完毕
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    ADVGURLSessionManagerTaskHandler * taskHandler = [self handlerForTask:task];
    if (taskHandler) {
        //将Task传给taskHandler处理
        [taskHandler URLSession:session task:task didCompleteWithError:error];
        [self removeHandlerForTask:task];
    }
    
    //如果用户实现了回调方法 则返回
    if ([_delegate respondsToSelector:@selector(URLSession:task:didCompleteWithError:)]) {
        [_delegate URLSession:session task:task didCompleteWithError:error];
    }
}

#pragma mark - URLSession DownloadTask delegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    //让Handler处理 文件保存到指定目录等
    ADVGURLSessionManagerTaskHandler * taskHandler = [self handlerForTask:downloadTask];
    if (taskHandler) {
        [taskHandler URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
    }
    
    //如果使用者提供回调 则返回对应DownloadTask的Handler.downloadFileURL(文件转存路径)
    if ([_delegate respondsToSelector:@selector(URLSession:downloadTask:didFinishDownloadingToURL:)]) {
        [_delegate URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:taskHandler.downloadFileURL];
    }
}

#pragma mark - 系统的一些方法
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.session.configuration forKey:@"sessionConfiguration"];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithSessionConfiguration:self.session.configuration];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, session: %@, operationQueue: %@>", NSStringFromClass([self class]), self, self.session, self.operationQueue];
}

- (void)dealloc {
    AdViewLogInfo(@"%s",__FUNCTION__);
}

@end


