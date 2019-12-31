//
//  ADVASTMediaFilePicker.m
//  AdViewVideoSample
//
//  Created by AdView on 16/10/9.
//  Copyright © 2016年 AdView. All rights reserved.
//

#import "AdViewVastMediaFilePicker.h"
#import "AdViewReachability.h"
#import "AdViewExtTool.h"
#import <UIKit/UIKit.h>

// This enum will be of more use if we ever decide to include the media files'
// delivery type and/or bitrate into the picking algorithm.
typedef enum {
    NetworkTypeCellular,
    NetworkTypeNone,
    NetworkTypeWiFi
} NetworkType;

@interface AdViewVastMediaFilePicker()

+ (BOOL)isMIMETypeCompatible:(AdViewVastMediaFile *)vastMediaFile;

@end

@implementation AdViewVastMediaFilePicker

//选择一个适合的视频播放
+ (AdViewVastMediaFile *)pick:(NSArray *)mediaFiles
{
    AdViewViewNetworkStatus status = [[AdViewReachability reachabilityForInternetConnection] currentReachabilityStatus];
    AdViewLogDebug(@"VAST - Mediafile Picker : NetworkType %d",status);
    if (status == AdViewViewNotReachable) {
        return nil;
    }
    
    // Go through the provided media files and only those that have a compatible MIME type.
    NSMutableArray *compatibleMediaFiles = [[NSMutableArray alloc] init];
    for (AdViewVastMediaFile *vastMediaFile in mediaFiles) {
        // Make sure that you have type specified for mediafile and ignore accordingly
        if (vastMediaFile.type != nil && [self isMIMETypeCompatible:vastMediaFile]) {
            [compatibleMediaFiles addObject:vastMediaFile];
        }
    }
    if ([compatibleMediaFiles count] == 0) {
        return nil;
    }
    
    // Sort the media files based on their video size (in square pixels).
    NSArray *sortedMediaFiles = [compatibleMediaFiles sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        AdViewVastMediaFile *mf1 = (AdViewVastMediaFile *)a;
        AdViewVastMediaFile *mf2 = (AdViewVastMediaFile *)b;
        int area1 = mf1.width * mf1.height;
        int area2 = mf2.width * mf2.height;
        if (area1 < area2) {
            return NSOrderedAscending;
        } else if (area1 > area2) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    // Pick the media file with the video size closes to the device's screen size.
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    int screenArea = screenSize.width * screenSize.height;
    int bestMatch = 0;
    int bestMatchDiff = INT_MAX;
    int len = (int)[sortedMediaFiles count];
    
    for (int i = 0; i < len; i++) {
        int videoArea = ((AdViewVastMediaFile *)sortedMediaFiles[i]).width * ((AdViewVastMediaFile *)sortedMediaFiles[i]).height;
        int diff = abs(screenArea - videoArea);
        if (diff >= bestMatchDiff) {
            break;
        }
        bestMatch = i;
        bestMatchDiff = diff;
    }
    
    AdViewVastMediaFile *toReturn = (AdViewVastMediaFile *)sortedMediaFiles[bestMatch];
    AdViewLogDebug(@"VAST - Mediafile Picker : Selected Media File %@",toReturn.url);
    return toReturn;
}

+ (BOOL)isMIMETypeCompatible:(AdViewVastMediaFile *)vastMediaFile
{
    NSString *pattern = @"(mp4|m4v|quicktime|3gpp|png|jpg|jpeg|html|gif|image|javascript)";
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSArray *matches = [regex matchesInString:vastMediaFile.type
                                      options:0
                                        range:NSMakeRange(0, [vastMediaFile.type length])];
    
    return ([matches count] > 0);
}

@end
