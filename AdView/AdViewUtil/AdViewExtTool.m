//
//  AdViewExtTool.m
//  AdViewHello
//
//  Created by AdView on 12-8-23.
//  Copyright 2012 AdView. All rights reserved.
//

#import "AdViewExtTool.h"
#import "AdViewNetManager.h"
#import "AdViewURLProtocol.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreLocation/CoreLocation.h>

#import <UIKit/UIKit.h>
#include <sys/socket.h> // Per msqr 
#include <sys/sysctl.h> 
#include <net/if.h> 
#include <net/if_dl.h>

#include <stdio.h>  
#include <stdlib.h>  
#include <string.h>  
#include <unistd.h>  
#include <sys/ioctl.h>  
#include <sys/types.h>  
#include <sys/socket.h>  
#include <netinet/in.h>  
#include <netdb.h>  
#include <arpa/inet.h>  
#include <sys/sockio.h>  
#include <net/if.h>  
#include <errno.h>  
#include <net/if_dl.h>

#import <EventKit/EventKit.h>
#import <Security/Security.h>
#import <CommonCrypto/CommonHMAC.h>

#import "AdViewReachability.h"

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <AdSupport/AdSupport.h>

#import "zlib.h"
#import <sys/utsname.h>

#pragma mark Log Function

static int gOpenAPIAdLogLevel = OPENAPI_AD_DEBUGLOG ? AdViewLogLevel_Debug : AdViewLogLevel_None;

void setAdViewLogLevel(int level) 
{
	if (gOpenAPIAdLogLevel == AdViewLogLevel_Debug) return;	//won't change
	
	gOpenAPIAdLogLevel = level;
	if (level > AdViewLogLevel_Debug)
		gOpenAPIAdLogLevel = AdViewLogLevel_Debug;
}

void _AdViewLogDebug(NSString *format, ...)
{
	va_list ap;
	
	if (gOpenAPIAdLogLevel < AdViewLogLevel_Debug) return;
	
	NSString *fmt_real = [@"AdViewView:" stringByAppendingString:format];
	va_start(ap, format);
	NSLogv(fmt_real, ap);
	va_end(ap);
}

void _AdViewLogInfo(NSString *format, ...)
{
	va_list ap;
	if (gOpenAPIAdLogLevel < AdViewLogLevel_Info) return;
	
    NSString *fmt_real = [@"AdViewView:" stringByAppendingString:format];
	va_start(ap, format);
	NSLogv(fmt_real, ap);
	va_end(ap);
}

static CGContextRef createContext()
{
    // create the bitmap context
    int density = [AdViewExtTool getDensity];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_1
    int bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
#else
    int bitmapInfo = kCGImageAlphaPremultipliedLast;
#endif
    
    CGContextRef context = CGBitmapContextCreate(nil, 27*density, 27*density, 8, 0,
                                                 colorSpace,bitmapInfo);
    CFRelease(colorSpace);
    return context;
}

CGImageRef createForwardOrBackArrowImageRef_AdView(BOOL bForward)
{
    int density = [AdViewExtTool getDensity];
    
    CGContextRef context = createContext();
    // set the fill color
    CGColorRef fillColor = [[UIColor blackColor] CGColor];
    CGContextSetFillColor(context, CGColorGetComponents(fillColor));
    CGContextBeginPath(context);
    if (bForward) {
        CGContextMoveToPoint(context, 18.0f*density, 13.0f*density);
        CGContextAddLineToPoint(context, 2.0f*density, 4.0f*density);
        CGContextAddLineToPoint(context, 2.0f*density, 22.0f*density);
    } else {
        CGContextMoveToPoint(context, 8.0f*density, 13.0f*density);
        CGContextAddLineToPoint(context, 24.0f*density, 4.0f*density);
        CGContextAddLineToPoint(context, 24.0f*density, 22.0f*density);
    }
    CGContextClosePath(context);
    CGContextFillPath(context);
    // convert the context into a CGImageRef
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    return image;
}

#define MAC_ADDR_FMT0 @"%02x%02x%02x%02x%02x%02x"
#define MAC_ADDR_FMT1 @"%02x:%02x:%02x:%02x:%02x:%02x"
#define MAC_ADDR_FMT2 @"%02X%02X%02X%02X%02X%02X"
#define MAC_ADDR_FMT3 @"%02X:%02X:%02X:%02X:%02X:%02X"
#define UI_USER_INTERFACE_IDIOM() ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : UIUserInterfaceIdiomPhone)

static AdViewExtTool *gAdViewExtTool = nil;

@interface AdViewExtTool() <CLLocationManagerDelegate>

@end

@implementation AdViewExtTool
@synthesize ipAddr = _ipAddr;
@synthesize closeImageN = _closeImageN;
@synthesize closeImageH = _closeImageH;
@synthesize urlCache = _urlCache;
@synthesize ios6Checked = _ios6Checked;
@synthesize idaString = _idaString;
@synthesize idvString = _idvString;
@synthesize advTrackingEnabled = _advTrackingEnabled;
@synthesize inmobiIdMapStr = _inmobiIdMapStr;
@synthesize userAgent;
@synthesize protocolCount;

//文件测试
//#define  LOG_FILE_AdViewBID  @"AdView_BID_log.txt"
//#define  Log_FILE_AdFill     @"AdFill_log.txt"
//#define  LOG_FILE_NAME  @"AdView_log.txt"
//
//+ (void)writeTheLogWithWho:(NSString*)who Source:(NSString*)src AdId:(NSString*)name Type:(NSString*)type {
//    NSString* date;
//    NSDateFormatter * formatter = [[NSDateFormatter alloc ] init];
//    [formatter setDateFormat:@"YYYY-MM-dd hh:mm:ss:SSS"];
//    date = [formatter stringFromDate:[NSDate date]];
//    NSString * timeNow = [[NSString alloc] initWithFormat:@"%@", date];
//    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:LOG_FILE_NAME];
//    
//    NSString *logInfo = [NSString stringWithFormat:@"%@ %@ %@ %@ %@\n",
//                         timeNow,who,src,name,type];
//    FILE *fp = fopen([logPath UTF8String], "a+");
//    if (NULL != fp) {
//        NSData *data = [logInfo dataUsingEncoding:NSUTF8StringEncoding];
//        fwrite([data bytes], [data length], 1, fp);
//        fclose(fp);
//    }
//}

#pragma mark MAC addy

/*******************************************************************************
 See header for documentation.
 */
+ (NSData *)gzipData:(NSData *)pUncompressedData
{
    /*
     Special thanks to Robbie Hanson of Deusty Designs for sharing sample code
     showing how deflateInit2() can be used to make zlib generate a compressed
     file with gzip headers:
     
     http://deusty.blogspot.com/2007/07/gzip-compressiondecompression.html
     
     */
    
    if (!pUncompressedData || [pUncompressedData length] == 0)
    {
        AdViewLogInfo(@"%s: Error: Can't compress an empty or null NSData object.", __func__);
        return nil;
    }
    
    z_stream zlibStreamStruct;
    zlibStreamStruct.zalloc    = Z_NULL; // Set zalloc, zfree, and opaque to Z_NULL so
    zlibStreamStruct.zfree     = Z_NULL; // that when we call deflateInit2 they will be
    zlibStreamStruct.opaque    = Z_NULL; // updated to use default allocation functions.
    zlibStreamStruct.total_out = 0; // Total number of output bytes produced so far
    zlibStreamStruct.next_in   = (Bytef*)[pUncompressedData bytes]; // Pointer to input bytes
    zlibStreamStruct.avail_in  = (uInt)[pUncompressedData length]; // Number of input bytes left to process
    
    int initError = deflateInit2(&zlibStreamStruct, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY);
    if (initError != Z_OK)
    {
        NSString *errorMsg = nil;
        switch (initError)
        {
            case Z_STREAM_ERROR:
                errorMsg = @"Invalid parameter passed in to function.";
                break;
            case Z_MEM_ERROR:
                errorMsg = @"Insufficient memory.";
                break;
            case Z_VERSION_ERROR:
                errorMsg = @"The version of zlib.h and the version of the library linked do not match.";
                break;
            default:
                errorMsg = @"Unknown error code.";
                break;
        }
        AdViewLogInfo(@"%s: deflateInit2() Error: \"%@\" Message: \"%s\"", __func__, errorMsg, zlibStreamStruct.msg);
        return nil;
    }
    
    NSMutableData *compressedData = [NSMutableData dataWithLength:[pUncompressedData length] * 1.01 + 12];
    
    int deflateStatus;
    do
    {
        zlibStreamStruct.next_out = [compressedData mutableBytes] + zlibStreamStruct.total_out;
        
        zlibStreamStruct.avail_out = (uInt)([compressedData length] - zlibStreamStruct.total_out);
        
        deflateStatus = deflate(&zlibStreamStruct, Z_FINISH);
        
    } while ( deflateStatus == Z_OK );
    
    // Check for zlib error and convert code to usable error message if appropriate
    if (deflateStatus != Z_STREAM_END)
    {
        NSString *errorMsg = nil;
        switch (deflateStatus)
        {
            case Z_ERRNO:
                errorMsg = @"Error occured while reading file.";
                break;
            case Z_STREAM_ERROR:
                errorMsg = @"The stream state was inconsistent (e.g., next_in or next_out was NULL).";
                break;
            case Z_DATA_ERROR:
                errorMsg = @"The deflate data was invalid or incomplete.";
                break;
            case Z_MEM_ERROR:
                errorMsg = @"Memory could not be allocated for processing.";
                break;
            case Z_BUF_ERROR:
                errorMsg = @"Ran out of output buffer for writing compressed bytes.";
                break;
            case Z_VERSION_ERROR:
                errorMsg = @"The version of zlib.h and the version of the library linked do not match.";
                break;
            default:
                errorMsg = @"Unknown error code.";
                break;
        }
        AdViewLogInfo(@"%s: zlib error while attempting compression: \"%@\" Message: \"%s\"", __func__, errorMsg, zlibStreamStruct.msg);
        
        // Free data structures that were dynamically created for the stream.
        deflateEnd(&zlibStreamStruct);
        
        return nil;
    }
    // Free data structures that were dynamically created for the stream.
    deflateEnd(&zlibStreamStruct);
    [compressedData setLength: zlibStreamStruct.total_out];
    AdViewLogDebug(@"%s: Compressed file from %d KB to %d KB", __func__, [pUncompressedData length]/1024, [compressedData length]/1024);
    
    return compressedData;
}

+ (AdViewLocale)locale {
    NSString *languageCode = [NSLocale preferredLanguages][0];
    return [languageCode containsString:@"zh"] ? AdViewLocale_Chinese : AdViewLocale_English;
}

// Return the local MAC addy 
// Courtesy of FreeBSD hackers email list 
// Accidentally munged during previous update. Fixed thanks to mlamb. 
+ (BOOL) getMacAddressBytes:(void *)out_mac
{ 
	int                    mib[6]; 
	size_t                len; 
	char                *buf; 
	unsigned char        *ptr; 
	struct if_msghdr    *ifm; 
	struct sockaddr_dl    *sdl; 
	
	mib[0] = CTL_NET; 
	mib[1] = AF_ROUTE; 
	mib[2] = 0; 
	mib[3] = AF_LINK; 
	mib[4] = NET_RT_IFLIST;
    
    int     idx1, idx2;
    idx1 = if_nametoindex("en0");
    idx2 = if_nametoindex("en1");
	mib[5] = (0!=idx1)?idx1:idx2;
    
	if (mib[5] == 0) {
		AdViewLogInfo(@"Error: if_nametoindex error\n");
		return NO; 
	} 
	
	if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) { 
		AdViewLogInfo(@"Error: sysctl, take 1\n"); 
		return NO; 
	} 
	
	if ((buf = malloc(len)) == NULL) { 
		AdViewLogInfo(@"Could not allocate memory. error!\n"); 
		return NO; 
	} 
	
	if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) { 
		AdViewLogInfo(@"Error: sysctl, take 2");
        free(buf);
		return NO; 
	} 
	
	ifm = (struct if_msghdr *)buf; 
	sdl = (struct sockaddr_dl *)(ifm + 1);
	ptr = (unsigned char *)LLADDR(sdl);
	
	if (out_mac) memcpy(out_mac, ptr, 6);
	free(buf);
	return YES;
}

+ (NSString*)actGetMacAddress:(MacAddrFmtType)fmt
{
	unsigned char      ptr[32];
	NSString *fmtStr = nil;
    
    NSString *sysVersion = [[UIDevice currentDevice] systemVersion];	//@"4.2"
    float sysVer = [sysVersion floatValue];
    
    if (sysVer >= 7.0f) {
        return @"";
    }
	
	switch (fmt) {
		case MacAddrFmtType_UpperCaseColon:fmtStr = MAC_ADDR_FMT3; break;
		case MacAddrFmtType_UpperCase:fmtStr = MAC_ADDR_FMT2; break;
		case MacAddrFmtType_Colon:fmtStr = MAC_ADDR_FMT1; break;
		default:
			fmtStr = MAC_ADDR_FMT0;
	}
	
	memset(ptr, 0, sizeof(ptr));
	if (![AdViewExtTool getMacAddressBytes:ptr])
    {
        memset(ptr, 0, sizeof(ptr));    //set to 0.
        //return nil;
    }
	
	NSString *outstring = [NSString stringWithFormat:fmtStr,
						   ptr[0], ptr[1], ptr[2], ptr[3], ptr[4], ptr[5]];
	return [outstring uppercaseString];
}

+ (AdViewExtTool*)sharedTool {
	if (nil == gAdViewExtTool) {
		gAdViewExtTool = [[AdViewExtTool alloc] init];
        //上一次请求广告是否成功 默认为yes
        [gAdViewExtTool storeObject:[NSNumber numberWithBool:YES] forKey:@"lastRequestAdStatus"];
    }
	return gAdViewExtTool;
}

- (id) init {
    srandom(CFAbsoluteTimeGetCurrent());
	self = [super init];
	if (self) {
		//think this will set some global info, like URLCache.
		NSString *strPath = [[NSString alloc] initWithFormat:@"%@/%@", NSHomeDirectory(),URLCACHE_PATH];
		AdViewURLCache *cache = [[AdViewURLCache alloc] initWithMemoryCapacity:URLCACHE_MEM_SIZE
														  diskCapacity:URLCACHE_DISK_SIZE
															  diskPath:strPath];
		AdViewLogInfo(@"UrlCachePath:%@", strPath);
		self.urlCache = cache;
		
		[[NSNotificationCenter defaultCenter]
		 addObserver:self
		 selector:@selector(enterBackground:)
		 name:UIApplicationDidEnterBackgroundNotification		//UIApplicationWillTerminateNotification
		 object:nil];
		
		[[NSNotificationCenter defaultCenter]
		 addObserver:self
		 selector:@selector(enterBackground:)
		 name:UIApplicationWillTerminateNotification			//UIApplicationWillTerminateNotification
		 object:nil];
        
        [self createHttpRequest];		//init some global parameters
        protocolCount = 0;
        [NSURLProtocol registerClass:[AdViewURLProtocol class]];
	}
	return self;
}

- (void)setMyURLCache {
#if 0
	if (nil != self.urlCache) 
		[NSURLCache setSharedURLCache:self.urlCache];
#endif
}

- (void)removeAllCaches {
    [self.urlCache removeAllCachedResponses];
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if (nil != netManager) {
		AdViewNetManager_delete(netManager);
		netManager = nil;
	}
	objDict = nil;
    [NSURLProtocol unregisterClass:[AdViewURLProtocol class]];
}

- (NSString*)getMacAddress:(MacAddrFmtType)fmt {
	if (nil == macAddr[fmt] || [macAddr[fmt] length] < 1) {
		macAddr[fmt] = [[NSString alloc] initWithString:[AdViewExtTool actGetMacAddress:fmt]];
	}
	
	return macAddr[fmt];
}

- (void)storeObject:(NSObject*)obj forKey:(NSString*)keyStr
{
	if (nil == objDict) objDict = [[NSMutableDictionary alloc] initWithCapacity:4];
	[objDict setObject:obj forKey:keyStr];
}

- (NSObject*)objectStoredForKey:(NSString*)keyStr {
	return [objDict objectForKey:keyStr];
}

- (void)removeStoredObjectForKey:(NSString*)keyStr {
    [objDict removeObjectForKey:keyStr];
}

- (NSString *)actDeviceIPAdress {
	if (nil == netManager) {
		netManager = AdViewNetManager_new();
	}
	
	AdViewNetManager_GetIPAddresses(netManager);
    const char *localIp = "127.0.0.1";
    const char *ipName = AdViewNetManager_GetIPName(netManager, 1);
    if (NULL == ipName) ipName = localIp;
    return [NSString stringWithFormat:@"%s", ipName];
}

- (NSString *)deviceIPAdress {
	if (nil == self.ipAddr || [self.ipAddr length] < 1)
		self.ipAddr = [self actDeviceIPAdress];
	
	if (nil == self.ipAddr) self.ipAddr = @""; 
	return self.ipAddr;
}

#pragma mark device info
+ (BOOL)isJailbroken {
    BOOL jailbroken = NO;
    NSString *cydiaPath = @"/Applications/Cydia.app";
    NSString *aptPath = @"/private/var/lib/apt/";
    if ([[NSFileManager defaultManager] fileExistsAtPath:cydiaPath]) {
        jailbroken = YES;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:aptPath]) {
        jailbroken = YES;
    }
    return jailbroken;
}

+ (id)getSSIDInfo {
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) {
            break;
        }
    }
    return info;
}

+ (BOOL)getDeviceIsIpad {
#if 1
	return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#else
	NSString *modelName = [[UIDevice currentDevice] model];
	if ([modelName rangeOfString:@"iPad" options:NSCaseInsensitiveSearch].location != NSNotFound) {
		return YES;
	}
	return NO;
#endif
}

//是否横屏
+ (BOOL)getDeviceDirection
{
    UIDeviceOrientation orientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;
    BOOL bIsLand = UIDeviceOrientationIsLandscape(orientation);
    return bIsLand;
}

+ (int)getDensity
{
	UIUserInterfaceIdiom deviceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
	
	//density
	int densityVal = 1;
    if (deviceIdiom == UIUserInterfaceIdiomPhone ){
        densityVal = (int)[UIScreen mainScreen].scale;
    }
    
	if (deviceIdiom == UIUserInterfaceIdiomPad )
		densityVal = (int)[UIScreen mainScreen].scale;
	
	return densityVal;
}

+ (NSString*)getUM5 {
    //From 2013.05, can not use udid
    return @"";
/*
    UIDevice *device = [UIDevice currentDevice];
    if (![device respondsToSelector:@selector(uniqueIdentifier)])
        return nil;
    
	NSString *udid = [device performSelector:@selector(uniqueIdentifier)];
	NSString *um5 = [AdViewExtTool getMd5HexString:udid];
	return um5;
*/
}

+ (NSString*) serviceProviderCode
{
    NSString* serviceProviderCode;
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    //NSString *carrierName = [carrier carrierName];
    NSString *carrierCountryCode = [carrier mobileCountryCode];
    NSString *carrierNetworkCode = [carrier mobileNetworkCode];
    NSString* deviceModel = [[UIDevice currentDevice] model];
    NSRange simulatorRange = [deviceModel rangeOfString:@"Simulator"];
    if (simulatorRange.location != NSNotFound) {
        serviceProviderCode = @"Unknown";
    } else {
        serviceProviderCode = @"";
        if (carrierCountryCode && carrierNetworkCode) {
            serviceProviderCode = [NSString stringWithFormat:@"%@%@", carrierCountryCode, carrierNetworkCode];
        }
    }
    return serviceProviderCode;
}

+ (int) aduuNetworkType
{
    int nRet = 0;
    AdViewViewNetworkStatus netStatus = [[AdViewReachability reachabilityForInternetConnection] currentReachabilityStatus];
    
    {
        NSString *name = [AdViewExtTool serviceProviderCode];
        int     nVal = [name intValue];
        switch (nVal%10) {
            case 0:
            case 2:nRet = 1; break;
            case 1:nRet = 2; break;
            case 3:nRet = 3; break;
            default:
                break;
        }
    }
    switch (netStatus) {
        case AdViewViewNotReachable:
            nRet = 4;
            break;
        case AdViewReachableViaWiFi:
            nRet = 4;
            break;
        case AdViewReachableViaWWAN:
            break;
        default:
            break;
    }
    return nRet;
}

#pragma mark Util method

#define kChosenDigestLength CC_SHA1_DIGEST_LENGTH

+ (NSData *)getSha1HashBytes:(NSData *)plainText {
    CC_SHA1_CTX ctx;
    uint8_t * hashBytes = NULL;
    NSData * hash = nil;
    
    // Malloc a buffer to hold hash.
    hashBytes = malloc( kChosenDigestLength * sizeof(uint8_t) );
    memset((void *)hashBytes, 0x0, kChosenDigestLength);
    
    // Initialize the context.
    CC_SHA1_Init(&ctx);
    // Perform the hash.
    CC_SHA1_Update(&ctx, (void *)[plainText bytes], (int)[plainText length]);
    // Finalize the output.
    CC_SHA1_Final(hashBytes, &ctx);
    
    // Build up the SHA1 blob.
    hash = [NSData dataWithBytes:(const void *)hashBytes length:(NSUInteger)kChosenDigestLength];
    
    if (hashBytes) free(hashBytes);
    
    return hash;
}

+ (NSString *)getSha1HexStringByData:(NSData *)_data {
	NSData *data = [AdViewExtTool getSha1HashBytes:_data];
	
	unsigned char *digest = (unsigned char *)[data bytes];
	
	NSMutableString* ret = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
	
	for(int i = 0; i < kChosenDigestLength; i++)
		[ret appendFormat:@"%02x", digest[i]];
	
	return ret;
}

+ (NSString *)getSha1HexString:(NSString *)plainText {
	return [AdViewExtTool getSha1HexStringByData:
			[plainText dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSString *)getMd5HexString:(NSString *)plainText {
	NSData *data = [plainText dataUsingEncoding:NSUTF8StringEncoding 
						   allowLossyConversion:YES];
	
	uint8_t digest[CC_MD5_DIGEST_LENGTH];
	CC_MD5(data.bytes, (int)data.length, digest);
	
	NSMutableString* ret = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
	
	for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
		[ret appendFormat:@"%02x", digest[i]];
	
	return ret;
}

+ (NSString*)encryptAduuMd5:(NSString*)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, (int)strlen(cStr), result);
    
    char ac[] = {
        '9', '0', '6', 'e', 'd', 'c', '1', 'b', '3', '8', '7',
        '2', 'a', '5', 'f', '4'
    };
    
    char ac1[32];
    
    int l = 0;
    for(int i1 = 0; i1 < 16; i1++) {
        char byte0 = result[i1];
        ac1[l++] = ac[(byte0 >> 4) & 0xf];
        ac1[l++] = ac[byte0 & 0xf];
    }
    NSString* tem = [NSString stringWithFormat:@"%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c",ac1[0],ac1[1],ac1[2],ac1[3],ac1[4],ac1[5],ac1[6],ac1[7],ac1[8],
                     ac1[9],ac1[10],ac1[11],ac1[12],ac1[13],ac1[14],ac1[15],ac1[16],
                     ac1[17],ac1[18],ac1[19],ac1[20],ac1[21],ac1[22],ac1[23],ac1[24],
                     ac1[25],ac1[26],ac1[27],ac1[28],ac1[29],ac1[30],ac1[31]];
    return tem;
}

+ (NSString *)URLEncodedString:(NSString *)str {
    NSString *encodedString = (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)str,(CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]",(CFStringRef)@"!*'();:@&=+$,%#[]/?",kCFStringEncodingUTF8));
    return encodedString;
}

+ (NSString *)stringFromHexString:(NSString *)hexString {
    char *myBuffer = (char *)malloc((int)[hexString length] / 2 + 1);
    bzero(myBuffer, [hexString length] / 2 + 1);
    for (int i = 0; i < [hexString length] - 1; i += 2) {
        unsigned int anInt;
        NSString * hexCharStr = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
        [scanner scanHexInt:&anInt];
        myBuffer[i / 2] = (char)anInt;
    }
    NSString *unicodeString = [NSString stringWithCString:myBuffer encoding:4];
    AdViewLogDebug(@"------字符串=======%@",unicodeString);
    return unicodeString;
}

+ (NSString *)hexStringFromString:(NSString *)string {
    NSData *myD = [string dataUsingEncoding:NSUTF8StringEncoding];
    Byte *bytes = (Byte *)[myD bytes];
    //下面是Byte 转换为16进制。
    NSString *hexStr=@"";
    for(long i=0;i<[myD length];i++){
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    return hexStr;
}

+(NSString*) getNetStatus {
	NSString *retVal = @"Unknown";
	
	return retVal;	
}

+ (NSString *)encodeToPercentEscapeString:(NSString *)input    
{    
    // Encode all the reserved characters, per RFC 3986    
    // (<http://www.ietf.org/rfc/rfc3986.txt>)    
    NSString *outputStr = (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,    
                                            (CFStringRef)input,    
                                            NULL,    
                                            (CFStringRef)@"!*'();:@&=+$,%#[]/?",    
                                            kCFStringEncodingUTF8));
    return outputStr;
}    

+ (NSString *)decodeFromPercentEscapeString:(NSString*)input
{    
    NSMutableString *outputStr = [NSMutableString stringWithString:input];    
    [outputStr replaceOccurrencesOfString:@"+"    
                               withString:@" "    
                                  options:NSLiteralSearch    
                                    range:NSMakeRange(0, [outputStr length])];    
	
    return [outputStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];    
}

+(UIImage*) renderCloseImageWithSize:(CGSize)size withBgColor:(UIColor*)bgColor withForColor:(UIColor*)forColor
{
    int dx = (int) size.width;
    int dy = (int) size.height;
    void* imagePixel = malloc (dx * 4 * dy);
    if (!imagePixel) {
        return nil;
    }
    memset(imagePixel, 0, dx*4*dy);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_1
    int bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
#else
    int bitmapInfo = kCGImageAlphaPremultipliedLast;
#endif
    
    CGContextRef context = CGBitmapContextCreate(imagePixel, dx, dy, 8, 4*dx, colorSpace,
                                                 bitmapInfo);
    /*
     * Fill use background color
     */
    UIGraphicsPushContext(context);
	
	CGContextSetLineWidth(context, 5.0f);
	
	[[UIColor clearColor] setFill];
	CGContextFillRect(context, CGRectMake(0.0f, 0.0f, size.width, size.height));
	
	[bgColor setFill];
	CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, size.width, size.height));
	
	CGPoint linePt[2], linePt1[2];
	
	CGFloat decLen = size.width * 0.2;
	
	linePt[0] = CGPointMake(0 + decLen, 0 + decLen);
	linePt[1] = CGPointMake(size.width - decLen, size.height - decLen);
	linePt1[0] = CGPointMake(size.width - decLen, 0 + decLen);
	linePt1[1] = CGPointMake(0 + decLen, size.height - decLen);	
	
	[forColor setFill];
	[forColor setStroke];
	CGContextBeginPath(context);
	CGContextAddLines(context, linePt, 2);
	CGContextAddLines(context, linePt1, 2);
	CGContextDrawPath(context, kCGPathStroke);
	
    UIGraphicsPopContext();
	
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage* img = [UIImage imageWithCGImage: imgRef];
    CGImageRelease(imgRef);
    CGContextRelease(context);
    free(imagePixel);
    CGColorSpaceRelease(colorSpace);
	
    return img;
}

- (UIImage *)getCloseImageNormal {
	if (nil == self.closeImageN) {
		int den = [AdViewExtTool getDensity];
		self.closeImageN = [AdViewExtTool renderCloseImageWithSize:CGSizeMake(32*den, 32*den)
															   withBgColor:[UIColor colorWithWhite:0.8 alpha:0.5]
															  withForColor:[UIColor redColor]];
	}
	return self.closeImageN;
}

- (UIImage *)getCloseImageHighlight {
	if (nil == self.closeImageH) {
		int den = [AdViewExtTool getDensity];
		self.closeImageH = [AdViewExtTool renderCloseImageWithSize:CGSizeMake(32*den, 32*den)
															   withBgColor:[UIColor colorWithWhite:0.5 alpha:0.5]
															  withForColor:[UIColor yellowColor]];
	}
	return self.closeImageH;	
}

#pragma mark Got UserAgent

- (void)createHttpRequest {
	_webView = [[UIWebView alloc] init];
    self.userAgent = [_webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if (webView == _webView) {
		self.userAgent = [request valueForHTTPHeaderField:@"User-Agent"];
		// Return no, we don't care about executing an actual request.
		return NO;
	}
	return YES;
}

#pragma mark UIApplication notification
- (void)enterBackground:(NSNotification *)notification {
	[self.urlCache saveModified];
}

#pragma mark string to color
+ (UIColor *) hexStringToColor: (NSString *) stringToConvert {
    NSString *cString = [[stringToConvert stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // String should be 6 or 8 characters
    
    if ([cString length] < 6) return [UIColor blackColor];
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"]) cString = [cString substringFromIndex:1];
    if ([cString length] != 6 && [cString length] != 8) return [UIColor blackColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *aString = @"255";
    if ([cString length] == 8) {
        aString = [cString substringWithRange:range];
        range.location += 2;
    }
    NSString *rString = [cString substringWithRange:range];
    range.location += 2;
    NSString *gString = [cString substringWithRange:range];
    range.location += 2;
    NSString *bString = [cString substringWithRange:range];
    // Scan values
    unsigned int r, g, b, a;
    
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    [[NSScanner scannerWithString:aString] scanHexInt:&a];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:((float) a / 255.0f)];
}

#pragma mark iOS6

+ (NSString *)getIDA {
    ASIdentifierManager *manager = [ASIdentifierManager performSelector:@selector(sharedManager)];
    if (nil == manager) return @"";
    
    id adi = [manager performSelector:@selector(advertisingIdentifier)];
    
    NSString *ret = [adi performSelector:@selector(UUIDString)];
    if (nil == ret) ret = @"";
    return ret;
}

+ (NSString *)getIDFV {
    NSString *idv = @"";
    if([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
        idv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    return idv;
}

+ (BOOL)isadvertisingTrackingEnabled {
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    
    if (nil == ASIdentifierManagerClass) return NO;
    
    id manager = [ASIdentifierManagerClass performSelector:@selector(sharedManager)];
    if (nil == manager) return NO;
    
    BOOL ret = NO;
    
    if ([manager respondsToSelector:@selector(isAdvertisingTrackingEnabled)])
	{
		id retId = [manager performSelector:@selector(isAdvertisingTrackingEnabled)];
		ret = (BOOL)(unsigned long)retId;
	}
    
    return ret;
}

+ (NSString *)getIDV {
    /*
    UIDevice *device = [UIDevice currentDevice];
    
    if ([device respondsToSelector:@selector(identifierForVendor)])
    {
        id uuidObj = [device  performSelector:@selector(identifierForVendor)];
        return [uuidObj performSelector:@selector(UUIDString)];
    }
    */
    
    return @"";
}

+ (int)dateStringChangeToSeconds:(NSString*)timeStr {
    if ([timeStr isEqualToString:@"-1"]) {
        return -1;
    }
    
    NSArray *arr = [timeStr componentsSeparatedByString:@"."];
    timeStr = [arr firstObject];
    timeStr = [timeStr stringByReplacingOccurrencesOfString:@"：" withString:@":"];//防止写成中文冒号
    arr = [timeStr componentsSeparatedByString:@":"];
    int seconds = 0;
    for (int i = 0; i < arr.count; i++ ) {
        if (i == 0) {
            seconds += [[arr objectAtIndex:i] intValue] * 3600;
        }else if (i == 1) {
            seconds += [[arr objectAtIndex:i] intValue] * 60;
        }else if (i == 2) {
            seconds += [[arr objectAtIndex:i] intValue] * 1;
        }else {
            break;
        }
    }
    
    return seconds;
}

- (void)checkIOS6Params {
    if (self.ios6Checked) return;
    
    self.idaString = [AdViewExtTool getIDA];
    self.idvString = [AdViewExtTool getIDV];
    self.advTrackingEnabled = [AdViewExtTool isadvertisingTrackingEnabled];
    
    self.ios6Checked = YES;
}

- (NSString*)getInMobiODIN1:(NSString*)macAddr1 {
	NSString *odin1 = [AdViewExtTool getSha1HexString:macAddr1];
	NSString *odin1_md5 = [AdViewExtTool getMd5HexString:odin1];
	
	return odin1_md5;
}

- (NSString*)getStdODIN1 {
	unsigned char macBytes[32];
	
	memset(macBytes, 0, sizeof(macBytes));
	if (![AdViewExtTool getMacAddressBytes:macBytes])
		return nil;
	
	NSData *data = [NSData dataWithBytes:macBytes length:6];
	NSString *std_odin1 = [AdViewExtTool getSha1HexStringByData:data];
	return std_odin1;
}

- (void)testODIN {
	NSString *odin1_md5 = [self getInMobiODIN1:@"5C:59:48:33:04:4C"];
	AdViewLogDebug(@"test inmobi odin1:%@", odin1_md5);
	
	const unsigned char macAddrVal[] = {0x1a, 0x2b, 0x3c, 0x4d, 0x5e, 0x6f};
	NSData *data = [NSData dataWithBytes:macAddrVal length:6];
	NSString *std_odin1 = [AdViewExtTool getSha1HexStringByData:data];
	AdViewLogDebug(@"test std odin1:%@", std_odin1);
}

- (NSString*)getInMobiIdMap
{
    if (self.inmobiIdMapStr)
        return self.inmobiIdMapStr;
    
    [self checkIOS6Params];
    
#if OPENAPI_AD_DEBUGLOG
	[self testODIN];
#endif
    
	NSString *macAddrStr = [[AdViewExtTool sharedTool] getMacAddress:
							MacAddrFmtType_UpperCaseColon];
	NSString *inMobiODIN1 = [self getInMobiODIN1:macAddrStr];
	NSString *stdODIN1 = [self getStdODIN1];
	NSString *um5 = [AdViewExtTool getUM5];
    
    const char *idMapNames[] = {"O1", "SO1", "UM5", "IDA", "IDV"};
    NSString *idMapVals[] = {
        inMobiODIN1, stdODIN1, um5,
        self.idaString, self.idvString
    };
    
    NSMutableString *idMapStr = [[NSMutableString alloc] initWithCapacity:500];
    [idMapStr appendString:@"{"];
    BOOL bMapEmpty = YES;
    for (int i = 0; i < 5; i++) {
        
        if (nil == idMapVals[i]) continue;
        
        if (!bMapEmpty) [idMapStr appendString:@","];
        bMapEmpty = NO;
        [idMapStr appendFormat:@"\"%s\":\"%@\"", idMapNames[i], idMapVals[i]];
    }
    [idMapStr appendString:@"}"];
    
    self.inmobiIdMapStr = [NSString stringWithString:idMapStr];

    return self.inmobiIdMapStr;
}

#pragma mark ios version

+ (void)showViewModal:(UIViewController*)toShow FromRoot:(UIViewController*)root
{
    if (root.presentedViewController) {
        [root.presentedViewController presentViewController:toShow animated:YES completion:nil];
        return;
    }
    [root presentViewController:toShow animated:YES completion:nil];
}

+ (void)dismissViewModal:(UIViewController*)inShow
{
    [inShow dismissViewControllerAnimated:YES completion:nil];
}

//将size2的尺寸按照size的大小等比放大
+ (void)scaleEnlargesTheSize:(CGSize)size toSize:(CGSize *)size2 {
    if (size2->width < 1 || size2->height < 1) return;
    
    CGFloat scaleX = size.width / size2->width;
    CGFloat scaleY = size.height / size2->height;
    
    CGFloat scale = scaleX<scaleY?scaleX:scaleY;
    
    size2->width *= scale;
    size2->height *= scale;
    
    size2->width = floor(size2->width + 0.5f);
    size2->height = floor(size2->height + 0.5f);
}

+ (NSString*) jsonStringFromDic:(NSDictionary*)dic{
    NSError *parseError = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (void)newCalendarFromJsonDict:(NSDictionary *)jsonDict completion:(void(^)(BOOL granted, NSError * error))completion {
#if CALENDAR_PRIVACY
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                AdViewLogDebug(@"发生了错误:%@",error);
                completion(granted,error);
            } else if (!granted) {
                AdViewLogDebug(@"用户拒绝访问日历");
                completion(granted,error);
            } else {
                NSString * title = [jsonDict objectForKey:@"title"] ? [jsonDict objectForKey:@"title"] : @"Notice";
                NSString * location = [jsonDict objectForKey:@"location"] ? [jsonDict objectForKey:@"location"] : @"";
                NSString * startDateString = [jsonDict objectForKey:@"start"];
                NSString * endDateString = [jsonDict objectForKey:@"end"];
                
                NSString * eventId = [[NSUserDefaults standardUserDefaults] objectForKey:title];
                EKEvent * userDefaultEvent = [eventStore eventWithIdentifier:eventId];
                if (userDefaultEvent) {
                    //如果日历存在 则返回错误。如果不存在 则添加一条事件提醒 (这里有个问题。eventId会越来越多 无法清理 以后再说吧。加个定时清理)
                    AdViewLogDebug(@"日历已经存在 不再重新添加");
                    NSError * err = [NSError errorWithDomain:@"Event Already Exit" code:-886 userInfo:nil];
                    completion(granted,err);
                } else {
                    EKEvent * event  = [EKEvent eventWithEventStore:eventStore];
                    event.title  = title;
                    event.location = location;
                    NSDateFormatter *format = [[NSDateFormatter alloc] init];
                    format.dateFormat = @"yyyy-MM-dd'T'HH:mm-HH:mm";
                    NSDate * startDate = [format dateFromString:startDateString];
                    NSDate * endDate = [format dateFromString:endDateString];
                    event.startDate = startDate;
                    event.endDate = endDate;
                    event.allDay = YES;
                    //第一次提醒 设置事件开始之前1分钟提醒
                    [event addAlarm:[EKAlarm alarmWithRelativeOffset:60.0f * 60 * 14]];
                    //事件类容备注
                    NSString * str = [jsonDict objectForKey:@"description"] ? [jsonDict objectForKey:@"description"] : @"";
                    event.notes = [NSString stringWithFormat:@"%@",str];
                    //添加事件到日历中
                    [event setCalendar:[eventStore defaultCalendarForNewEvents]];
                    NSError * err;
                    [eventStore saveEvent:event span:EKSpanThisEvent error:&err];
                    [[NSUserDefaults standardUserDefaults] setObject:event.eventIdentifier forKey:title];  //保存事件id，方便查询和删除
                    completion(granted,err);
                }
            }
        });
    }];
#else
    completion(NO,nil);
#endif
}

#pragma mark - TEST
// the interface for test
// 获取测试所需数据
- (NSDictionary*)getDataForTest {
    return _testDict;
}

// 存储测试所需数据
- (void)storDataForTest {

}

- (NSString *)URLEncodedString:(NSString*)str
{
    NSString *encodedString = (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)str,
                                                              (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]",
                                                              NULL,
                                                              kCFStringEncodingUTF8));
    return encodedString;
}

- (NSArray *)replaceStrArr {
    if (!_replaceStrArr) {
        _replaceStrArr = @[@"{RELATIVE_COORD}",@"{ABSOLUTE_COORD}",@"{UUID}",@"{LATITUDE}",@"{LONGITUDE}",@"{CLICKAREA}",@"__DOWN_X__",@"__DOWN_Y__",@"__UP_X__",@"__UP_Y__",@"__DURATION__",@"__BEGINTIME__",@"__ENDTIME__",@"__FIRST_FRAME__",@"__LAST_FRAME__",@"__SCENE__",@"__TYPE__",@"__BEHAVIOR__",@"__STATUS__"];
    }
    return _replaceStrArr;
}

// 点击&展示汇报中宏替换；
- (NSString*)replaceDefineString:(NSString *)urlString
{
    for (NSString *string in self.replaceStrArr)
    {
        if ([urlString rangeOfString:string].length > 0)
        {
            NSString *value = [NSString stringWithFormat:@"%@", [objDict objectForKey:string]];
            if (!value || value.length == 0)
            {
                value = @"";
            }
            value = [self URLEncodedString:value];
            urlString = [urlString stringByReplacingOccurrencesOfString:string withString:value];
        }
    }
    
    NSArray *arr = @[@"{", @"}", @"\""];
    for (NSString *str in arr)
    {
        if ([urlString containsString:str])
        {
            urlString = [urlString stringByReplacingOccurrencesOfString:str withString:[self URLEncodedString:str]];
        }
    }
    return urlString;
}

- (void)getLocation {
    CLLocationManager *manager = [[CLLocationManager alloc] init];
    manager.delegate = self;
    manager.desiredAccuracy = kCLLocationAccuracyBest;
    manager.distanceFilter = kCLDistanceFilterNone;
    [manager stopUpdatingLocation];
}

#pragma mark - 获取手机型号
- (NSString *)iphoneType {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString*platform = [NSString stringWithCString: systemInfo.machine encoding:NSASCIIStringEncoding];
    return platform;
}
    
+ (BOOL)isViewable:(UIView *)view
{
    CGRect windowRect = [[[UIApplication sharedApplication] keyWindow] bounds];
    CGRect currentRect = [view convertRect:view.bounds toView:nil];
    BOOL currentRectOnScreen = CGRectIntersectsRect(windowRect, currentRect);   //是否在屏幕可视范围内
    BOOL hasSuperView = [view superview] != nil;                                //是否已经添加到界面上
    BOOL isHidden = view.hidden;
    BOOL finialResult = currentRectOnScreen && hasSuperView && !isHidden;
    return finialResult;
}

void UIImageFromURL( NSURL * URL, void (^imageBlock)(UIImage * image), void (^errorBlock)(void) )
{
    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^(void)
                   {
                       NSData * data = [[NSData alloc] initWithContentsOfURL:URL] ;
                       UIImage * image = [[UIImage alloc] initWithData:data];
                       dispatch_async( dispatch_get_main_queue(), ^(void){
                           if( image != nil )
                           {
                               imageBlock( image );
                           } else {
                               errorBlock();
                           }
                       });
                   });
}

UIEdgeInsets AdViewSafeAreaInset(UIView *view)
{
    if (@available(iOS 11.0, *))
    {
        return view.safeAreaInsets;
    }
    return UIEdgeInsetsZero;
}
@end
