//
//  ADVASTMediaFile.h
//  AdViewVideoSample
//
//  Created by AdView on 16/9/30.
//  Copyright © 2016年 AdView. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ADVASTMediaFileType_Video,          //普通视频
    ADVASTMediaFileType_Image,
    ADVASTMediaFileType_Html,
    ADVASTMediaFileType_JavaScript,     //VPAID
    ADVASTMediaFileType_Unknown,
}ADVASTMediaFileType;

@interface AdViewVastMediaFile : NSObject
@property (nonatomic, copy, readonly) NSString *id_;  // add trailing underscore to id_ to avoid conflict with reserved keyword "id".
@property (nonatomic, copy, readonly) NSString *delivery;
@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, assign, readonly) ADVASTMediaFileType fileType;
@property (nonatomic, assign, readonly) int bitrate;
@property (nonatomic, assign, readonly) int width;
@property (nonatomic, assign, readonly) int height;
@property (nonatomic, assign, readonly) BOOL scalable;
@property (nonatomic, assign, readonly) BOOL maintainAspectRatio;
@property (nonatomic, copy, readonly) NSString *apiFramework;
@property (nonatomic, strong, readonly) NSURL *url;

- (id)initWithId:(NSString *)id_ // add trailing underscore
        delivery:(NSString *)delivery
            type:(NSString *)type
         bitrate:(NSString *)bitrate
           width:(NSString *)width
          height:(NSString *)height
        scalable:(NSString *)scalable
maintainAspectRatio:(NSString *)maintainAspectRatio
    apiFramework:(NSString *)apiFramework
             url:(NSString *)url;
@end
