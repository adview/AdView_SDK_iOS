//
//  UIDevice+AdViewIDFA.m
//  AdViewHello
//
//  Created by unakayou on 6/24/19.
//

#import "UIDevice+AdViewIDFA.h"
#import <sys/sysctl.h>
#import <CommonCrypto/CommonDigest.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

@implementation UIDevice (AdViewIDFA)
- (NSString *)getAdViewIDFA
{
    NSString * countryString = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    NSString * languageString = [NSLocale preferredLanguages] ? [[NSLocale preferredLanguages] firstObject] : [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
    NSString * deviceNameString = [[[self class] currentDevice] name];
    
    NSString * systemVersion = [[[self class] currentDevice] systemVersion];
    NSString * hardwareString = [self hardwareInfo];
    NSString * totalDiskSpaceString = [[[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemSize] stringValue];
    
    NSString * firstString = [NSString stringWithFormat:@"%@%@%@",countryString,languageString,deviceNameString];
    NSString * lastString = [NSString stringWithFormat:@"%@%@%@",systemVersion,hardwareString,totalDiskSpaceString];
    
    const unsigned char * firstPartMD5 = [self ascMd5FromString:firstString];
    const unsigned char * lastPartMD5 = [self ascMd5FromString:lastString];
    NSString * retString = [self mergeMd5String:firstPartMD5 otherMd5String:lastPartMD5];
    return retString;
}

- (NSString *)hardwareInfo
{
    NSString * modelString = [self getSysInfoByName:@"hw.model"];
    NSString * machineString = [self getSysInfoByName:@"hw.machine"];
    NSString * carrierNameString = [self carrierName];
    return [NSString stringWithFormat:@"%@%@%@",modelString,machineString,carrierNameString];
}

- (NSString *)carrierName
{
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [info subscriberCellularProvider];
    return carrier ? [carrier carrierName] : @"";
}

- (NSString *)getSysInfoByName:(NSString *)typeString
{
    const char * typeSpecifier = typeString.UTF8String;
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);
    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    free(answer);
    return results;
}

- (unsigned char *)ascMd5FromString:(NSString *)source
{
    const char * str = [source UTF8String];
    unsigned char * result = malloc(sizeof(char) * CC_MD5_DIGEST_LENGTH);
    CC_MD5(str, (CC_LONG)strlen(str), result);
    return result;
}

- (NSString *)mergeMd5String:(const unsigned char *)md5Str1 otherMd5String:(const unsigned char *)md5Str2
{
    NSMutableString * retString = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2 + 4];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    {
        if (i == 4 || i == 6 || i == 8 || i == 10)
            [retString appendString:@"-"];
        
        if (i < CC_MD5_DIGEST_LENGTH / 2)
        {
            [retString appendFormat:@"%02X",md5Str1[i]];
        }
        else
        {
            [retString appendFormat:@"%02X",md5Str2[CC_MD5_DIGEST_LENGTH - i - 1 + CC_MD5_DIGEST_LENGTH / 2]];
        }
    }
    return [retString copy];
}
@end
