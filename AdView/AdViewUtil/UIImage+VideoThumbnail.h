//
//  UIImage+VideoThumbnail.h
//  AdViewSDK
//
//  Created by unakayou on 11/28/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (VideoThumbnail)
+ (UIImage*)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time;
@end

NS_ASSUME_NONNULL_END
