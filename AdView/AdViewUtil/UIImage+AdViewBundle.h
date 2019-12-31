//
//  UIImage+AdviewBundle.h
//  AdViewDevelop
//
//  Created by AdView on 2017/9/20.
//  Copyright © 2017年 AdView. All rights reserved.
//  获取Framework中的bundle中的资源

#import <UIKit/UIKit.h>

@interface UIImage (AdViewBundle)

//从动态库中寻找image
+ (UIImage *)imagesNamedFromCustomBundle:(NSString *)imgName;
@end
