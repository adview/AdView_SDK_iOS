//
//  AdViewURLCache.h
//  AdViewSDK
//
//  Created by AdView on 12-9-21.
//  Copyright 2012 AdView. All rights reserved.
//

#import<Foundation/Foundation.h>

typedef unsigned int uint32;

@interface AdViewURLCacheItem : NSObject

@property (nonatomic, retain) NSString *fullUrl;
@property (nonatomic, retain) NSString *md5ID;
@property (nonatomic, retain) NSString *fileName;
@property (nonatomic, assign) uint32		fileSize;
@property (nonatomic, assign) NSTimeInterval	lastVisit;

- (id)initWithRequest:(NSURLRequest*)request;

@end

#define STORE_MEM_LIMIT		10

@interface AdViewURLCache : NSURLCache {
	NSMutableDictionary* dicItems;		//AdViewURLCacheItem->fullUrl.
	NSMutableDictionary* dicMemStore;	//NSCachedURLResponse->NSURLRequest
	
	NSUInteger			 diskUseSize;
	NSUInteger			 diskMyCapacity;
	
	NSString*			 diskPath;
	
	int					 maxItem;
	
	BOOL				 modified;
}

@property (nonatomic, retain) NSMutableDictionary* dicItems;
@property (nonatomic, retain) NSMutableDictionary* dicMemStore;

@property (nonatomic, assign) NSUInteger diskUseSize;
@property (nonatomic, assign) NSUInteger diskMyCapacity;
@property (nonatomic, retain) NSString*  diskPath;

@property (nonatomic, assign) int		 maxItem;

+ (NSString *)getFullUrlByRequest:(NSURLRequest *)request;

- (void)saveModified;

@end
