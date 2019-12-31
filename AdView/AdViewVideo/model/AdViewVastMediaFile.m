//
//  ADVASTMediaFile.m
//  AdViewVideoSample
//
//  Created by AdView on 16/9/30.
//  Copyright © 2016年 AdView. All rights reserved.
//

#import "AdViewVastMediaFile.h"

@implementation AdViewVastMediaFile

- (id)initWithId:(NSString *)id_ delivery:(NSString *)delivery type:(NSString *)type bitrate:(NSString *)bitrate width:(NSString *)width height:(NSString *)height scalable:(NSString *)scalable maintainAspectRatio:(NSString *)maintainAspectRatio apiFramework:(NSString *)apiFramework url:(NSString *)url {
    if (self = [super init]) {
        _id_ = id_;
        _delivery = delivery;
        _type = type;
        _fileType = [self changeStringToFileType:self.type];
        _bitrate = bitrate ? [bitrate intValue] : 0;
        _width = width ? [width intValue] : 0;
        _height = height ? [height intValue] : 0;
        _scalable = scalable == nil || [scalable boolValue];
        _maintainAspectRatio = maintainAspectRatio != nil && [maintainAspectRatio boolValue];
        _apiFramework = apiFramework;
        _url = [NSURL URLWithString:url];
    }
    return self;
}

- (ADVASTMediaFileType)changeStringToFileType:(NSString*)typeString {
    if ([typeString containsString:@"video"] || [typeString hasSuffix:@"mp4"]) {
        return ADVASTMediaFileType_Video;
    }else if ([typeString containsString:@"image"] || [typeString hasSuffix:@"png"]) {
        return ADVASTMediaFileType_Image;
    }else if ([typeString containsString:@"html"]) {
        return ADVASTMediaFileType_Html;
    }else if ([typeString containsString:@"javascript"] && [_apiFramework caseInsensitiveCompare:@"VPAID"] == NSOrderedSame){
        return ADVASTMediaFileType_JavaScript;
    }
    return ADVASTMediaFileType_Unknown;
}

@end
