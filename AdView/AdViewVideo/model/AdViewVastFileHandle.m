//
//  ADVASTFileHandle.m
//  AdViewVideoSample
//
//  Created by AdView on 17/2/17.
//  Copyright © 2017年 AdView. All rights reserved.
//

#import "AdViewVastFileHandle.h"
#import "AdViewExtTool.h"

@implementation AdViewCacheTimeValue

+ (AdViewCacheTimeValue *)sharedCacheTimeValue {
    static AdViewCacheTimeValue*value;
    @synchronized (self) {
        if (!value) {
            value = [[AdViewCacheTimeValue alloc] init];
        }
        return value;
    }
}

- (instancetype)init {
    if (self = [super init]) {
        _cacheTimeOutValue = 1800;// 缓存存在时间默认为1800
    }
    return self;
}

@end

@interface AdViewVastFileHandle ()

@property (nonatomic, strong) NSFileHandle *writeFileHandle;
@property (nonatomic, strong) NSFileHandle *readFileHandle;

@end

@implementation AdViewVastFileHandle

+ (NSString*)tempFilePath {
    return [[NSHomeDirectory() stringByAppendingPathComponent:@"tmp"] stringByAppendingPathComponent:@"VastVideoTemp.mp4"];
}

+ (NSString *)cacheFolderPath {
    return [[NSHomeDirectory( ) stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"VastVideoCaches"];
}

+ (NSString *)fileNameWithURL:(NSURL *)url fileType:(NSString*)type{
    NSString *fName = [AdViewExtTool getMd5HexString:url.absoluteString];
    fName = [NSString stringWithFormat:@"%@.%@",fName,type];
    return fName;
//    NSString *fileName = [[url.path componentsSeparatedByString:@"/"] lastObject];
//    if (!fileName || !fileName.length) return nil;
//    NSArray *array = [fileName componentsSeparatedByString:@"."];
//    if (array.count <= 1) {
//        fileName = [NSString stringWithFormat:@"%@%@",fileName,type];
//    }
//    return fileName;
}

+ (BOOL)createTempFile {
    NSFileManager * manager = [NSFileManager defaultManager];
    NSString * path = [AdViewVastFileHandle tempFilePath];
    if ([manager fileExistsAtPath:path]) {
        [manager removeItemAtPath:path error:nil];
    }
    return [manager createFileAtPath:path contents:nil attributes:nil];
}

+ (void)writeTempFileData:(NSData *)data {
    NSFileHandle * handle = [NSFileHandle fileHandleForWritingAtPath:[AdViewVastFileHandle tempFilePath]];
    [handle seekToEndOfFile];
    [handle writeData:data];
}

+ (NSData *)readTempFileDataWithOffset:(NSUInteger)offset length:(NSUInteger)length {
    NSFileHandle * handle = [NSFileHandle fileHandleForReadingAtPath:[AdViewVastFileHandle tempFilePath]];
    [handle seekToFileOffset:offset];
    return [handle readDataOfLength:length];
}

+ (void)cacheTempFileWithFileName:(NSString *)name {
    NSFileManager * manager = [NSFileManager defaultManager];
    NSString * cacheFolderPath = [AdViewVastFileHandle cacheFolderPath];
    if (![manager fileExistsAtPath:cacheFolderPath]) {
        [manager createDirectoryAtPath:cacheFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString * cacheFilePath = [NSString stringWithFormat:@"%@/%@", cacheFolderPath, name];
    BOOL success = [[NSFileManager defaultManager] copyItemAtPath:[AdViewVastFileHandle tempFilePath] toPath:cacheFilePath error:nil];
    
    if (success) {
        NSString *fileName = [cacheFolderPath stringByAppendingPathComponent:@"/check.plist"];
        if (![manager fileExistsAtPath:fileName]) {
            [manager createFileAtPath:fileName contents:nil attributes:nil];
        }
        
        // 文件大小
        float fileSize = ([[manager attributesOfItemAtPath:cacheFilePath error:nil] fileSize])/(1024.0*1024.0);
        NSNumber *size = [NSNumber numberWithFloat:fileSize];
        
        // 当前时间
        NSDate *date = [NSDate date];
        NSNumber *time = [NSNumber numberWithDouble:[date timeIntervalSince1970]];
        
        NSMutableDictionary *fileDict = [NSMutableDictionary dictionaryWithContentsOfFile:fileName];
        if (nil == fileDict) {
            fileDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@[size,time],name,nil];
        }else {
            [fileDict setObject:@[size,time] forKey:name];
        }
        
        // 缓存超过200M时，删除最早的文件，知道小于200M
        NSString *fName = nil;
        do {
            fName = [AdViewVastFileHandle findTheOldFile:fileName newFileSize:fileSize];
            if (nil != fName) {
                NSString * needRemoveFilePath = [NSString stringWithFormat:@"%@/%@", cacheFolderPath, fName];
                [fileDict removeObjectForKey:fName];
                [manager removeItemAtPath:needRemoveFilePath error:nil];
            }
        } while (fName != nil);
        
        // 存储处理好的文件信息到plist中
        [fileDict writeToFile:fileName atomically:YES];
    }
    
    AdViewLogDebug(@"cache file : %@", success ? @"success" : @"fail");
}

// 判断缓存总大小是否超过200M,如超过返回时间最早存入的缓存 参数fileSize新下载的文件的大小，判断是否超过200M，需要用200M减去新文件大小，以保证缓存不超过200M
+ (NSString*)findTheOldFile:(NSString*)fileName newFileSize:(int)fileSize{
    NSDictionary *fileInfoDict = [NSDictionary dictionaryWithContentsOfFile:fileName];
    float size = 0;
    
    for (NSString *key in [fileInfoDict allKeys]) {
        NSArray *array = [fileInfoDict objectForKey:key];
        size += [(NSNumber*)array.firstObject floatValue];
    }
    
    if (size <= (URLCACHE_VIDEO_SIZE - fileSize)) return nil;
    
    // 当前时间
    NSDate *date = [NSDate date];
    NSTimeInterval nowTime = [date timeIntervalSince1970];
    
    // 要找的文件名字
    NSString *fName = nil;
    
    for (NSString *key in fileInfoDict) {
        NSArray *array = [fileInfoDict objectForKey:key];
        NSTimeInterval time = [(NSNumber*)array.lastObject doubleValue];
        if (time < nowTime) {
            nowTime = time;
        }
        fName = key;
    }
    
    return fName;
}

+ (NSString *)cacheFileExistsWithURL:(NSURL *)url {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *cacheFolderPath = [AdViewVastFileHandle cacheFolderPath];
    NSString *fileName = [AdViewExtTool getMd5HexString:url.absoluteString];
    if (!fileName || !fileName.length) {
        return nil;
    }
    
    NSString *checkFilePath = [cacheFolderPath stringByAppendingString:@"/check.plist"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:checkFilePath];
    if (nil == dict) {
        [manager createFileAtPath:checkFilePath contents:nil attributes:nil];
        return nil;
    }
    
    BOOL isExists = NO;
    for (NSString *key in [dict allKeys]) {
        if ([key hasPrefix:fileName]) {
            fileName = key;
            isExists = YES;
        }
    }
    
    if (!isExists) {
        return nil;
    }
    
    NSString *cacheFilePath = [NSString stringWithFormat:@"%@/%@",cacheFolderPath,fileName];
    if ([manager fileExistsAtPath:cacheFilePath]) {
        NSArray *array = [dict objectForKey:fileName];
        NSTimeInterval time = [(NSNumber*)array.lastObject doubleValue];
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        float size = [array.firstObject floatValue];
        float reacFileSize = [manager attributesOfItemAtPath:cacheFilePath error:nil].fileSize/(1024.0*1024.0);
        // 文件不可用，对比文件中文件大小为零，或者实际文件大小为零，或者两者不相等
        BOOL fileUnavailable = (size == 0) || (reacFileSize == 0) || (size != reacFileSize);
        // 缓存数据超过30分钟后清掉
        if ((now - time) >= [AdViewCacheTimeValue sharedCacheTimeValue].cacheTimeOutValue || fileUnavailable) {
            [manager removeItemAtPath:cacheFilePath error:nil];
            [dict removeObjectForKey:fileName];
            [dict writeToFile:checkFilePath atomically:YES];
            return nil;
        }
        return cacheFilePath;
    }
    return nil;
}

+ (void)clearCacheWithURL:(NSURL*)url {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *cacheFolderPath = [AdViewVastFileHandle cacheFolderPath];
    NSString *fileName = [AdViewVastFileHandle fileNameWithURL:url fileType:@".mp4"];
    NSString *cacheFilePath = [NSString stringWithFormat:@"%@/%@",cacheFolderPath,fileName];
    if ([manager fileExistsAtPath:cacheFilePath]) {
        NSString *checkFilePath = [cacheFolderPath stringByAppendingString:@"/check.plist"];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:checkFilePath];
        
        if (nil != dict) {
            [dict removeObjectForKey:fileName];
        }
        [manager removeItemAtPath:cacheFilePath error:nil];
        [dict writeToFile:checkFilePath atomically:YES];
    }
}

+ (BOOL)clearCache {
    NSFileManager * manager = [NSFileManager defaultManager];
    return [manager removeItemAtPath:[AdViewVastFileHandle cacheFolderPath] error:nil];
}

+ (void)printCacheFile {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *path = [AdViewVastFileHandle cacheFolderPath];
    NSArray *fileList = [manager contentsOfDirectoryAtPath:path error:nil];
    for (NSString *name in fileList) {
        AdViewLogDebug(@"%@\n",name);
        if ([name isEqualToString:@"check.plist"]) {
            NSString *checkFilePath = [path stringByAppendingString:@"/check.plist"];
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:checkFilePath];
            AdViewLogDebug(@"%@",dict);
        }
    }
}

+ (NSString *)logVideoCacheInfoForTest
{
    // 总大小
    float size = 0;

    NSFileManager *mgr = [NSFileManager defaultManager];
    NSString *pathStr = [NSMutableString stringWithString:[AdViewVastFileHandle cacheFolderPath]];
    NSMutableString *logStr = [NSMutableString stringWithString:pathStr];
    NSArray *fileList = [mgr contentsOfDirectoryAtPath:pathStr error:nil];
    for (NSString *name in fileList) {
//        if ([name hasSuffix:@"mp4"]) {
        
            NSDictionary *attrs = [mgr attributesOfItemAtPath:[NSString stringWithFormat:@"%@/%@",pathStr,name] error:nil];
            
            NSString* sizeStr;
            size = attrs.fileSize;
            if (size >= pow(10, 9)) { // size >= 1GB
                sizeStr = [NSString stringWithFormat:@"%.2fGB", size / pow(10, 9)];
            } else if (size >= pow(10, 6)) { // 1GB > size >= 1MB
                sizeStr = [NSString stringWithFormat:@"%.2fMB", size / pow(10, 6)];
            } else if (size >= pow(10, 3)) { // 1MB > size >= 1KB
                sizeStr = [NSString stringWithFormat:@"%.2fKB", size / pow(10, 3)];
            } else { // 1KB > size
                sizeStr = [NSString stringWithFormat:@"%.2fB", size];
            }
            NSString *append = [NSString stringWithFormat:@"\n名称：%@ 大小：%@",name,sizeStr];
            [logStr appendString:append];
        
            if ([name isEqualToString:@"check.plist"]) {
                NSString *checkFilePath = [[AdViewVastFileHandle cacheFolderPath] stringByAppendingString:@"/check.plist"];
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:checkFilePath];
                
                NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
                for (NSString *key in [dict allKeys]) {
                    NSMutableArray *arr = [NSMutableArray arrayWithArray:[dict objectForKey:key]];
                    NSDate *date = [NSDate date];
                    NSTimeInterval nowTime = [date timeIntervalSince1970];
                    [arr addObject:[NSNumber numberWithInteger:(nowTime - [[arr objectAtIndex:1] integerValue])]];
                    [arr removeObjectAtIndex:1];
                    [newDict setObject:arr forKey:key];
                }
             
                NSString *append = [NSString stringWithFormat:@"{%@}",newDict];
                [logStr appendString:append];
            }
    }
    return logStr;
}


@end

