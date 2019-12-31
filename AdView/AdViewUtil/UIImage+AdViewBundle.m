//
//  UIImage+AdviewBundle.m
//  AdViewDevelop
//
//  Created by AdView on 2017/9/20.
//  Copyright © 2017年 AdView. All rights reserved.
//

#import "UIImage+AdViewBundle.h"
#import "AdViewOMAdHTMLManager.h"

@implementation UIImage (AdViewBundle)

+ (UIImage *)imagesNamedFromCustomBundle:(NSString *)imgName {
    NSBundle * frameworkBundle = [NSBundle bundleForClass:[AdViewOMAdHTMLManager class]];
    NSString * bundlePath = [frameworkBundle pathForResource:@"AdViewRes" ofType:@"bundle"];
    NSBundle * imageBundle = [NSBundle bundleWithPath:bundlePath];
    UIImage * image = [UIImage imageNamed:imgName inBundle:imageBundle compatibleWithTraitCollection:nil];
    return image;
}

//+ (UIImage *)imagesNamedFromCustomBundle:(NSString *)imgName {
//    NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"AdViewSDK.framework/AdViewRes" ofType:@"bundle"];
//    NSBundle * imageBundle = [NSBundle bundleWithPath:bundlePath];
//    NSString * imagePath = [imageBundle pathForResource:imgName ofType:nil];
//    UIImage * image = [UIImage imageWithContentsOfFile:imagePath];
//    if (!image) {
//        bundlePath = [[NSBundle mainBundle] pathForResource:@"AdViewRes" ofType:@"bundle"];
//        NSString *img_path = [bundlePath stringByAppendingPathComponent:imgName];
//        image = [UIImage imageWithContentsOfFile:img_path];
//    }
//    return image;
//}

@end
