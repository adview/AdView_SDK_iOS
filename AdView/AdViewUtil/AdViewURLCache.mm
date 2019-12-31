//
//  AdViewURLCache.m
//  AdViewSDK
//
//  Created by AdView on 12-9-21.
//  Copyright 2012 AdView. All rights reserved.
//

#import "AdViewURLCache.h"
#import "AdViewExtTool.h"
#import <vector>



static int c_ver = 2;       //cache version. mainly for store&load

#define STORE_KEY       0x2ef36279
#define SAVE_ENDIAN     0       //0 -- little endian, 1 -- large endian.

#define ALIGN4(__len)       (((__len-1)/4+1)*4)


//做数据Endian转换，将数据转成largeOrder的endian值。
// 0 -- little endian, 1 -- large endian.
static void swap_byteorder(void *data, int length, int largeOrder)
{
	short testShort = 0x0102;
	char  *testVal = (char*)&testShort;
	
	int cpuOrder = (testVal[0]==0x02)?0:1;
	
	if (largeOrder == cpuOrder)
		return;		//no need do things.
	
	int nLen = length/2;
	char tmp = 0;
	
	char *p = (char*)data;
	
	for (int i = 0; i < nLen; i++)
	{
		tmp = p[i];
		p[i] = p[length - i - 1];
		p[length-i-1] = tmp;
	}
}

//将数据加入到vector中
static void appendVecPointerVal(std::vector<unsigned char>&vecData, int &len,
                                const void *val, int vlen)
{
	vecData.resize(len+vlen);
	memcpy(&vecData[0] + len, val, vlen);
    switch (c_ver) {
        case 1:
            len += (vlen);
            break;
        default:
            len += ALIGN4(vlen);
    }
}

//按endian统一，将数据加入到vector中
static void appendVecPointerVal_ByteOrder(std::vector<unsigned char>&vecData, int &len,
                                void *val, int vlen)
{
    if (c_ver > 1)
        swap_byteorder(val, vlen, SAVE_ENDIAN);       //to large endian
    appendVecPointerVal(vecData, len, val, vlen);
}

//按endian统一，将Int数据加入到vector中
static void appendVecIntVal(std::vector<unsigned char>&vecData, int &len, int val)
{
	appendVecPointerVal_ByteOrder(vecData, len, &val, sizeof(int));
}

using std::vector;

@implementation AdViewURLCacheItem

@synthesize fullUrl;
@synthesize md5ID;
@synthesize fileName;
@synthesize fileSize;
@synthesize lastVisit;

- (void)dealloc {
    self.fullUrl = nil;
    self.md5ID = nil;
    self.fileName = nil;
    
    
}

- (id)initWithRequest:(NSURLRequest*)request
{
	self = [super init];
	if (nil != self) {
		self.fullUrl = [AdViewURLCache getFullUrlByRequest:request];
		self.md5ID = [AdViewExtTool getMd5HexString:self.fullUrl];
		self.fileName = self.md5ID;
		self.lastVisit = [[NSDate date] timeIntervalSince1970];
	}
	
	return self;
}

/*
 根据从文件中序列化好的数据解析。
 根据序列化原则反序列化。
 */
- (id)initWithData:(const unsigned char *)pData length:(int*)out_len version:(int)ver
{
	self = [super init];
	if (nil != self) {
		uint32					lenArr[4];
		const char*					strArr[4];
		int nLen = 0;
		for (int i = 0; i < 4; i++) 
		{
			lenArr[i] = *((uint32*)(pData+nLen));
			nLen += sizeof(uint32);
            if (ver > 1)
                swap_byteorder(&lenArr[i], sizeof(uint32), SAVE_ENDIAN);
			
			strArr[i] = nil;
			if (3 != i && lenArr[i] > 0) {
				strArr[i] = (const char *)(pData+nLen);
                switch (ver) {
                    case 1:
                        nLen += (lenArr[i] + 1);
                        break;
                    default:
                        nLen += ALIGN4(lenArr[i] + 1);
                        break;
                }
			}
		}
		
		self.fullUrl = [NSString stringWithCString:strArr[0] encoding:NSUTF8StringEncoding];
		self.md5ID = [NSString stringWithCString:strArr[1] encoding:NSUTF8StringEncoding];
		self.fileName = [NSString stringWithCString:strArr[2] encoding:NSUTF8StringEncoding];
		self.fileSize = lenArr[3];
		switch (ver) {
            case 1:     //don't parse it.
                break;
            default: {
                NSTimeInterval timeVal = *((NSTimeInterval*)(pData+nLen));
                swap_byteorder(&timeVal, sizeof(NSTimeInterval), SAVE_ENDIAN);
                self.lastVisit = timeVal;
            }
        }
		nLen += sizeof(NSTimeInterval);
		
		if (nil != out_len) *out_len = nLen;
	}
	
	return self;
}

/*
序列化数据到vector数据。
fullUrl字符串长度，fullUrl的UTF8String（如果为0，或nil则实际没有）
md5字符串长度，md5的UTF8String
文件名字符串长度，文件名的UTF8String
文件大小。
最后是lastVisit时间（NSTimeInterval）。--可能版本1的时候没有。
*/
- (void)ToVectorData:(std::vector<unsigned char>&)vecData
{
    uint32                  tmpUInt;
	uint32					lenArr[4];
	const char*					strArr[4];
	
	int	    nLen = (int)vecData.size();
	int		nOneSize;
	
	strArr[0] = [self.fullUrl UTF8String];
	strArr[1] = [self.md5ID UTF8String];
	strArr[2] = [self.fileName UTF8String];
	strArr[3] = nil;
	
	lenArr[0] = strArr[0]?(int)strlen(strArr[0]):0;
	lenArr[1] = strArr[1]?(int)strlen(strArr[1]):0;
	lenArr[2] = strArr[2]?(int)strlen(strArr[2]):0;
	lenArr[3] = self.fileSize;
	for (int j = 0; j < 4; j++)
	{
        tmpUInt = lenArr[j];
        appendVecPointerVal_ByteOrder(vecData, nLen, &tmpUInt, sizeof(uint32));
		
		if (nil == strArr[j] || lenArr[j] < 1) continue;
		
		nOneSize = lenArr[j]+1;
        appendVecPointerVal(vecData, nLen, strArr[j], nOneSize);
	}

	NSTimeInterval timeVal = self.lastVisit;
    appendVecPointerVal_ByteOrder(vecData, nLen, &timeVal, sizeof(NSTimeInterval));
}

@end

@interface AdViewURLCache(PRIVATE)

- (void)deleteItems;
- (void)deleteItemByKey:(NSString*)keyStr;

@end



@implementation AdViewURLCache

@synthesize dicItems;
@synthesize dicMemStore;

@synthesize diskUseSize;
@synthesize diskMyCapacity;

@synthesize diskPath;

@synthesize maxItem;

- (void)dealloc {
    [self removeAllCachedResponses];
    
    self.dicItems = nil;
    self.dicMemStore = nil;
    
    self.diskPath = nil;
    
    
}

+ (NSString *)getFullUrlByRequest:(NSURLRequest *)request {
    NSString*url = nil;
    if([request.HTTPMethod compare:@"GET"]== NSOrderedSame) {
		url =[[request URL] absoluteString];
    }
    else if([request.HTTPMethod compare:@"POST"]== NSOrderedSame){
		NSString*bodyStr = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
		url =[NSString stringWithFormat:@"%@?%@",[[request URL]absoluteString],bodyStr];
    }
    return url;
}

- (void)calculateSize
{
	self.diskUseSize = 0;
	
	NSArray *keyArr = [self.dicItems allKeys];
	for (int i = 0; i < [keyArr count]; i++)
	{
		NSString *keyStr = (NSString*)[keyArr objectAtIndex:i];
		if (nil == keyStr) continue;
		
		AdViewURLCacheItem *item = [self.dicItems objectForKey:keyStr];
		if (nil == item) continue;
		self.diskUseSize += item.fileSize;
	}
}

//judge by new add or update size to check if should to remove some data.
- (void)judgeChangeSize:(AdViewURLCacheItem*)item
{
	AdViewURLCacheItem *item1 = [self.dicItems objectForKey:item.fullUrl];	//if update?
	uint32 orgSize = item1.fileSize;
	
	if (item.fileSize <= orgSize) return;		//won't do.
	
	uint32 addSize = item.fileSize - orgSize;	//should add this.
	
	if (self.diskUseSize + addSize < self.diskMyCapacity) return;		//won't continue.
	
	NSArray *valArr1 = [self.dicItems allValues];
	NSMutableArray *valArr = [NSMutableArray arrayWithArray:valArr1];
	[valArr sortedArrayUsingComparator: ^(id obj1, id obj2) {
		
		if ([obj1 lastVisit] > [obj2 lastVisit]) {
			return (NSComparisonResult)NSOrderedDescending;
		}
		
		if ([obj1 lastVisit] < [obj2 lastVisit]) {
			return (NSComparisonResult)NSOrderedAscending;
		}
		return (NSComparisonResult)NSOrderedSame;
	}];
	
	int nCount = (int)[valArr count];
	AdViewLogInfo(@"val1:%f", [[valArr objectAtIndex:0] lastVisit]);
	AdViewLogInfo(@"val2:%f", [[valArr objectAtIndex:nCount-1] lastVisit]);
	
	uint32 delSize = 0;
	BOOL	   iFind = nCount;
	NSMutableArray *arrDel = [[NSMutableArray alloc] initWithCapacity:4];
	for (int i = 0; i < nCount; i++) 
	{
		AdViewURLCacheItem *itemTmp = (AdViewURLCacheItem*)[valArr objectAtIndex:i];
		
		delSize += [itemTmp fileSize];
		if (self.diskUseSize - delSize + addSize < self.diskMyCapacity)
		{
			iFind = i + 1;
			[arrDel addObject:itemTmp.fullUrl];
			break;
		}
	}
	
	if (iFind == nCount) [self deleteItems];
	else {
		for (int i = 0; i < [arrDel count]; i++)
			[self deleteItemByKey:[arrDel objectAtIndex:i]];
	}
}

/**
 将缓存数据文件信息序列化到文件。
 首先是KEY，然后是版本号，然后是数量（对版本1，这些都没有），然后就是各个描述文件信息。
 */
- (NSData*)ItemsToData
{
	std::vector<unsigned char>	vecData(8192);
	int							nLen = 0;
	
	int							nCount = (int)[self.dicItems count];
    
    if (c_ver > 1) {
        appendVecIntVal(vecData, nLen, STORE_KEY);
        appendVecIntVal(vecData, nLen, c_ver);
    }
    appendVecIntVal(vecData, nLen, nCount);
	
	NSArray *arrVal = [self.dicItems allValues];
	for (int i = 0; i < nCount; i++)
	{
		AdViewURLCacheItem *item = [arrVal objectAtIndex:i];
		if (nil == item) continue;
		
		[item ToVectorData:vecData];
	}
	
	NSData *data = [NSData dataWithBytes:&vecData[0] length:vecData.size()];
	return data;
}

/**
 对版本1，可能就是各个描述文件的序列化。只有2以后，才有KEY，版本号，数量。
 */
- (void)loadItems
{
	NSString *strDicPath = [NSString stringWithFormat:@"%@/openapiCache.plist", self.diskPath];
	NSData *data1 = [[NSData alloc] initWithContentsOfFile:strDicPath];
	if (nil != data1 && [data1 length] > 0) {
		[self.dicItems removeAllObjects];
		
        int   nLen = 0;
        int   nVer = 1;         //version of cache data.
		const unsigned char *bytes = (const unsigned char*)[data1 bytes];
        uint32    nCount_swap = 0;
		uint32	  nCount = *((uint32*)bytes);
        nLen += sizeof(uint32);
        
        nCount_swap = nCount;
        swap_byteorder(&nCount_swap, sizeof(uint32), SAVE_ENDIAN);        //large-endian
        
        if (nCount != STORE_KEY && nCount_swap != STORE_KEY) {
            nVer = 1;
        } else {
            nCount = nCount_swap;
            
            nVer = *((uint32*)(bytes+nLen));        //version.
            nLen += sizeof(uint32);
            
            nCount = *((uint32*)(bytes+nLen));
            nLen += sizeof(uint32);
            
            swap_byteorder(&nVer, sizeof(int), SAVE_ENDIAN);
            swap_byteorder(&nCount, sizeof(int), SAVE_ENDIAN);
        }
        
        
		int   nItemLen, nCount1 = 0;
		while (YES) {
			if (nLen >= [data1 length]) break;
			
			nItemLen = 0;
			AdViewURLCacheItem *item = [[AdViewURLCacheItem alloc] initWithData:bytes + nLen
																			 length:&nItemLen
                                                                            version:nVer];
			if (nil != item) {
				[self.dicItems setObject:item forKey:item.fullUrl]; 
				++nCount1;
			}
			nLen += nItemLen;
		}
		AdViewLogDebug(@"loadItems count:%d, actual count:%d", nCount, nCount1);
	}
}

- (void)saveItems 
{	
	NSString *strDicPath = [NSString stringWithFormat:@"%@/openapiCache.plist", self.diskPath];
	
	AdViewLogInfo(@"dic file:%@", strDicPath);
	
	[[self ItemsToData] writeToFile:strDicPath atomically:YES];
}

- (void)deleteFileInItem:(AdViewURLCacheItem*)item FileManager:(NSFileManager*)fileManager
{
	if (nil == item) return;
	
	NSString *strDataPath = [NSString stringWithFormat:@"%@/%@.dat", self.diskPath, item.fileName];
	NSString *strRespPath = [NSString stringWithFormat:@"%@/%@.rsp", self.diskPath, item.fileName];	
	NSString *strReqPath = [NSString stringWithFormat:@"%@/%@.req", self.diskPath, item.fileName];
	
	[fileManager removeItemAtPath:strDataPath error:nil];
	[fileManager removeItemAtPath:strRespPath error:nil];
	[fileManager removeItemAtPath:strReqPath error:nil];
}

- (void)deleteItems 
{
	if (0 >= [self.dicItems count]) return;
	
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	
	NSArray *keyArr = [self.dicItems allKeys];
	for (int i = 0; i < [keyArr count]; i++)
	{
		NSString *keyStr = (NSString*)[keyArr objectAtIndex:i];
		if (nil == keyStr) continue;
		
		AdViewURLCacheItem *item = [self.dicItems objectForKey:keyStr];
		if (nil == item) continue;
		
		[self deleteFileInItem:item FileManager:fileManager];
	}
	self.diskUseSize = 0;
	[self.dicItems removeAllObjects];
	
	modified = YES;
}

- (void)deleteItemByKey:(NSString*)keyStr
{
	AdViewURLCacheItem *item = [self.dicItems objectForKey:keyStr];
	
	if (nil == item) return;
	
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	[self deleteFileInItem:item FileManager:fileManager];
	
	if (self.diskUseSize > item.fileSize)
		self.diskUseSize -= item.fileSize;
	else [self calculateSize];
	[self.dicItems removeObjectForKey:keyStr];
	
	modified = YES;
}

- (void)removeAllCachedResponses
{
	[self deleteItems];
	[self.dicMemStore removeAllObjects];
	
	[super removeAllCachedResponses];
}

- (void)removeCachedResponseForRequest:(NSURLRequest *)request
{
	AdViewLogInfo(@"AdViewURLCache removeCachedResponseForRequest");
	NSString *keyStr = [AdViewURLCache getFullUrlByRequest:request];
	[self deleteItemByKey:keyStr];
	[self.dicMemStore removeObjectForKey:request];
	
	[super removeCachedResponseForRequest:request];
}

- (id)initWithMemoryCapacity:(NSUInteger)memoryCapacity
				diskCapacity:(NSUInteger)diskCapacity
					diskPath:(NSString *)path
{
	self = [super initWithMemoryCapacity:memoryCapacity
							diskCapacity:10
								diskPath:nil];
	
	if (nil != self) {//load my file cache.
		self.diskMyCapacity = diskCapacity;
		self.diskPath = path;
		
		if (diskCapacity > 0) 
		{
			NSMutableDictionary *dic1 = [[NSMutableDictionary alloc] initWithCapacity:4];
			self.dicItems = dic1;
			
			NSMutableDictionary *dic2 = [[NSMutableDictionary alloc] initWithCapacity:4];
			self.dicMemStore = dic2;
			
			self.maxItem = (int)(diskCapacity / 20*1024);
			
			//to load disk data.
			NSFileManager *fileManager = [[NSFileManager alloc] init];
			if ([fileManager fileExistsAtPath:path]) {
				[self loadItems];
				
			} else {
				[fileManager createDirectoryAtPath:path withIntermediateDirectories:YES
										attributes:nil
											 error:nil];
			}
		}
 	}
	
	return self;
}

- (void)logMemUsage {
	uint32 memCap = (uint32)[self memoryCapacity];
	uint32 memUse1 = (uint32)[self currentMemoryUsage];
	uint32 memUse = (uint32)[self currentMemoryUsage];
	
	AdViewLogDebug(@"mem cap:%d, use1:%d, use2:%d", memCap, memUse1, memUse);
}

- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request
{
	NSCachedURLResponse *ret = nil;
	ret = [super cachedResponseForRequest:request];
	
	NSString *fullUrl = [AdViewURLCache getFullUrlByRequest:request];
    
    [self logMemUsage];
	
	if (nil == ret) {//memory not in, to find in storage.
		ret = [self.dicMemStore objectForKey:request];
		
		if (nil == ret) {//ok, use file.
			if (nil != [self.dicItems objectForKey:fullUrl]) 
			{//load data.
				AdViewURLCacheItem *item = [self.dicItems objectForKey:fullUrl];
				
				NSString *strDataPath = [NSString stringWithFormat:@"%@/%@.dat", self.diskPath, item.fileName];
				NSData *data = [NSData dataWithContentsOfFile:strDataPath];
				
				if (nil == data || [data length] != item.fileSize)
				{//error
					//delete the key.
					return ret;
				}
				
				NSString *strRespPath = [NSString stringWithFormat:@"%@/%@.rsp", self.diskPath, item.fileName];
				NSData *respData = [NSData dataWithContentsOfFile:strRespPath];
				NSURLResponse *response = [NSKeyedUnarchiver unarchiveObjectWithData:respData];
                
                if (nil == response) {//如果是64位，可能为空，则需要直接返回为nil
                    return ret;
                }
				
                NSCachedURLResponse *ret1 = [[NSCachedURLResponse alloc] initWithResponse:response data:data userInfo:nil storagePolicy:NSURLCacheStorageAllowedInMemoryOnly];
				[super storeCachedResponse:ret1 forRequest:request];		//load to mem.
				ret = [super cachedResponseForRequest:request];
                if (nil == ret) {
                    ret = ret1;
                }
			}
		}
	}
	
	AdViewURLCacheItem *item = [self.dicItems objectForKey:fullUrl];
	if (nil != item) {
		item.lastVisit = [[NSDate date] timeIntervalSince1970];
		modified = YES;
	}
	
	return ret;
}

- (BOOL)myStoreToData:(BOOL)bFlush 
{
	@synchronized(self) 
	{
		if ([self.dicMemStore count] >= STORE_MEM_LIMIT
			|| (bFlush && [self.dicMemStore count] > 0))
		{
			NSArray *keyArr = [self.dicMemStore allKeys];
			for (int i = 0; i < [keyArr count]; i++)
			{
				NSURLRequest *keyReq = (NSURLRequest*)[keyArr objectAtIndex:i];
				NSCachedURLResponse *cachedResp = [self.dicMemStore objectForKey:keyReq];
				
				AdViewURLCacheItem *item = [[AdViewURLCacheItem alloc] initWithRequest:keyReq];
				NSData *data = [cachedResp data];
				item.fileSize = (int)[data length];
				
				[self judgeChangeSize:item];
				[self.dicItems setObject:item forKey:item.fullUrl];
				self.diskUseSize += item.fileSize;
				
				NSString *strDataPath = [NSString stringWithFormat:@"%@/%@.dat", self.diskPath, item.fileName];
				[data writeToFile:strDataPath atomically:YES];
				
				//AdViewLogInfo(@"data path:%@", strDataPath);
				
				NSString *strRespPath = [NSString stringWithFormat:@"%@/%@.rsp", self.diskPath, item.fileName];
				NSData *respData = [NSKeyedArchiver archivedDataWithRootObject:[cachedResp response]];
				[respData writeToFile:strRespPath atomically:YES];
				
				NSString *strReqPath = [NSString stringWithFormat:@"%@/%@.req", self.diskPath, item.fileName];
				NSData *reqData = [NSKeyedArchiver archivedDataWithRootObject:keyReq];
				[reqData writeToFile:strReqPath atomically:YES];				
			}
			
			[self.dicMemStore removeAllObjects];
			return YES;
		}
		
		return NO;
	}
}

- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request
{
	uint32 memCap = (uint32)[self memoryCapacity];
	uint32 memUse1 = (uint32)[self currentMemoryUsage];
	[super storeCachedResponse:cachedResponse forRequest:request];
	uint32 memUse = (uint32)[self currentMemoryUsage];
	
	AdViewLogDebug(@"mem cap:%d, use1:%d, use2:%d", memCap, memUse1, memUse);
	
	if (self.diskMyCapacity < 1) return;		//don't use disk
	
	modified = YES;
	
	//BOOL bNotAdd = (memUse1 == memUse);
	
	//added to items.
	[self.dicMemStore setObject:cachedResponse forKey:request];
	if ([self myStoreToData:NO]) {
		[self saveModified];
	}
}

- (void)saveModified {
	if (!modified) return;
	modified = NO;
	
	[self myStoreToData:YES];
	[self saveItems];
}

@end
