//
//  AdViewCheckTool.m
//  AdViewHello
//
//  Created by AdView on 17/3/1.
//
//

#import "AdViewCheckTool.h"
#import <WebKit/WebKit.h>

static AdViewCheckTool *gAdViewCheckTool = nil;

@implementation AdViewCheckTool
@synthesize matchLanding;

+ (AdViewCheckTool*)sharedTool {
    if (nil == gAdViewCheckTool) {
        gAdViewCheckTool = [[AdViewCheckTool alloc] init];
    }
    return gAdViewCheckTool;
}

- (id)init{
    if (self = [super init]) {

    }
    return self;
}

- (void)dealloc{
    self.matchLanding = nil;
}
/**
 * default url:
 *  https://itunes.apple.com/
 *  itms-appss://itunes.apple.com/
 *  itms
 */
- (BOOL)isLandingUrl:(NSString*)reqUrl {
    if (nil == reqUrl) return NO;
    NSArray *DEF_ARRAY = [NSArray arrayWithObjects:@"https://itunes.apple.com/", @"itms", nil];
    
    NSString *lowerUrl = [reqUrl lowercaseString];
    for (NSString *caseString in DEF_ARRAY) {
        NSRange caseRange = [lowerUrl rangeOfString:caseString];
        if (caseRange.location == 0)
            return YES;
    }
    //根据返回内容的判断
    //like: @"https://itunes\\.apple\\.com/.*" - "\\."是代码写需要\\表示单个\字符
    if (nil != self.matchLanding && [self.matchLanding isKindOfClass:[NSArray class]]) {
        for (NSString *aMatch in self.matchLanding) {
            if (![aMatch isKindOfClass:[NSString class]]) continue;
            if (aMatch.length < 1) continue;
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", aMatch];
            if([predicate evaluateWithObject:lowerUrl])
                return YES;
        }
    }
    
    return NO;
}

- (BOOL)isEmptyAd:(UIView*)rAdView
{    
    NSDictionary *dict;
    if ([rAdView isKindOfClass:[WKWebView class]])
    {
        UIImage *image = [self captureView:(WKWebView*)rAdView];
        dict = [self getAllIndexColorWithImage:image withViewSize:rAdView.frame.size];
    }
    else
    {
        // 获取所有点颜色的字符串
        dict = [self getAllIndexColorWithView:rAdView];
    }
    
    // 如果字典为空，则认为是白条
    if (nil == dict) {
        return YES;
    }
    
    // 判断颜色是否一样
    BOOL isEqual = NO;
    // 获取颜色的种类数
    NSUInteger kindOfColor = [dict allKeys].count;
    if (kindOfColor <= 3) {// 当颜色种类数少于等于3种时并且单一颜色超过90%时判定为白条
        int pointCount = 0;
        for (NSString *key in [dict allKeys]) {
            NSNumber *number = [dict objectForKey:key];
            pointCount += [number intValue];
        }
        
        for (NSString *key in [dict allKeys]) {
            NSNumber *number = [dict objectForKey:key];
            if ([number intValue] > pointCount * 0.9) {
                isEqual = YES;
                break;
            }
        }
    }
//    NSLog(@"有%ld种类颜色，数色值字典：%@",(unsigned long)kindOfColor,dict);
    return isEqual;
}

- (BOOL)CGColorEqualWithArray:(NSArray*)colorArr {
    BOOL isEqual = YES;
    NSEnumerator *enumerator = [colorArr objectEnumerator];
    UIColor *color1 = [enumerator nextObject];
    UIColor *color2;
    while ((color2 = [enumerator nextObject]) != nil) {
        isEqual = CGColorEqualToColor(color1.CGColor, color2.CGColor);
        if (!isEqual) {
            break;
        }
    }
    return isEqual;
}

static int const maxIndex = 8; //view分成多少个取点区域

- (NSMutableDictionary*)getAllIndexColorWithView:(UIView*)view {
    size_t pixelsWide = view.bounds.size.width;
    size_t pixelsHigh = view.bounds.size.height;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    void *bitmapData = malloc( pixelsWide*pixelsHigh*4 );
    
    CGContextRef cgctx = CGBitmapContextCreate (bitmapData,
                                                pixelsWide,
                                                pixelsHigh,
                                                8,
                                                pixelsWide*4,
                                                colorSpace,
                                                kCGImageAlphaPremultipliedFirst);
    
//    if ([view isKindOfClass:[WKWebView class]])
    [view.layer renderInContext:cgctx];
    view.layer.contents = nil;
 
    unsigned char* data = CGBitmapContextGetData (cgctx);
    
    //取出要取点的范围（防止取到广告字样或者广告logo上的店，导致判断白条出现错误）剥离视图外侧一圈，取中间部分为取点范围
    CGSize size = view.frame.size;
    NSMutableDictionary *colorDict = [self getColorDictWithSize:size withImageData:data];
    
    //释放
    CGColorSpaceRelease( colorSpace );
    CGContextRelease(cgctx);
    data = nil;
    free (bitmapData);
    
    return colorDict;
}

- (UIImage*)captureView:(WKWebView *)webView
{
    UIImage* image = nil;
    //优化图片截取不清晰
    UIGraphicsBeginImageContextWithOptions(webView.scrollView.contentSize, true, [UIScreen mainScreen].scale);
    {
        CGPoint savedContentOffset = webView.scrollView.contentOffset;
        CGRect savedFrame = webView.scrollView.frame;
        webView.scrollView.contentOffset = CGPointZero;
        webView.scrollView.frame = CGRectMake(0, 0, webView.scrollView.contentSize.width, webView.scrollView.contentSize.height);
        for (UIView * subView in webView.subviews) {
            [subView drawViewHierarchyInRect:subView.bounds afterScreenUpdates:YES];
        }
        image = UIGraphicsGetImageFromCurrentImageContext();
        webView.scrollView.contentOffset = savedContentOffset;
        webView.scrollView.frame = savedFrame;
    }
    UIGraphicsEndImageContext();
    return image;
}

- (NSMutableDictionary*)getAllIndexColorWithImage:(UIImage*)image withViewSize:(CGSize)viewSize{
    size_t pixelsWide = image.size.width;
    size_t pixelsHigh = image.size.height;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    void *bitmapData = malloc( pixelsWide*pixelsHigh*4 );
    
    CGContextRef cgctx = CGBitmapContextCreate (bitmapData,
                                                pixelsWide,
                                                pixelsHigh,
                                                8,
                                                pixelsWide*4,
                                                colorSpace,
                                                kCGImageAlphaPremultipliedFirst);
    CGImageRef cgImage = image.CGImage;
    CGContextSetBlendMode(cgctx, kCGBlendModeCopy);
//    CGContextTranslateCTM(cgctx,, <#CGFloat ty#>)
    CGContextDrawImage(cgctx, CGRectMake(0, 0, pixelsWide, pixelsHigh), cgImage);
    unsigned char* data = CGBitmapContextGetData (cgctx);
    
    CGSize size = image.size.width * image.size.height < viewSize.width *viewSize.height ? image.size : viewSize;
    
    NSMutableDictionary *colorDict = [self getColorDictWithSize:size withImageData:data];
    
    //释放
    CGColorSpaceRelease( colorSpace );
    CGContextRelease(cgctx);
    data = nil;
    free (bitmapData);
    
    return colorDict;
}

- (NSMutableDictionary*)getColorDictWithSize:(CGSize)size withImageData:(unsigned char*)data{
    NSMutableDictionary *colorDict = [NSMutableDictionary dictionary];
    
    CGFloat width = 4;
    CGRect horizontalR = CGRectMake(0, (size.height - width) / 2, size.width, width);
    CGRect verticalR = CGRectMake((size.width - width) / 2, 0, width, size.height);
    
    CGPoint point = CGPointMake(0, (size.height - width) / 2);
    do {
        NSString *key = [self getPixelColorStringAtLocation:point withImage:data andImageWidth:size.width];
        id value = [colorDict objectForKey:key];
        if (nil == value) {
            [colorDict setObject:[NSNumber numberWithInt:1] forKey:key];
        }else {
            int count = [(NSNumber*)value intValue];
            [colorDict setObject:[NSNumber numberWithInt:++count] forKey:key];
        }
        
//        NSLog(@"point:%@ color:%@",NSStringFromCGPoint(point),key);
        
        point.x += 1;
        if (point.x > horizontalR.origin.x + horizontalR.size.width) {
            point.x = 0;
            point.y += 1;
        }
    } while (point.y < horizontalR.origin.y + width);
    
    point = CGPointMake((size.width - width) / 2, 0);
    do {
        NSString *key = [self getPixelColorStringAtLocation:point withImage:data andImageWidth:size.width];
        id value = [colorDict objectForKey:key];
        if (nil == value) {
            [colorDict setObject:[NSNumber numberWithInt:1] forKey:key];
        }else {
            int count = [(NSNumber*)value intValue];
            [colorDict setObject:[NSNumber numberWithInt:++count] forKey:key];
        }
        
//        NSLog(@"point:%@ color:%@",NSStringFromCGPoint(point),key);
        
        point.x += 1;
        if (point.x >= verticalR.origin.x + verticalR.size.width) {
            point.x = (size.width - width) / 2;
            point.y += 1;
        }
    } while (point.y < size.height);
    
    return colorDict;
}

- (CGPoint)randomGetPointAtIndex:(int)index withSize:(CGSize)size {
    CGFloat x = index%(maxIndex/2)*size.width;
    CGFloat y = index/(maxIndex/2)*size.height;
    
    CGFloat logoWidth = 60;//去除4角的宽度
    CGFloat logoHeight = 25;//去除4角的高度
    
    CGFloat rX = [self randomFloatFrom:0 To:size.width];
    CGFloat rY = [self randomFloatFrom:0 To:size.height];
    CGFloat offX = rX;
    CGFloat offY = rY;
    
    if (rX < logoWidth) {
        rX = (size.width-logoWidth)/2;
        rX = rX==0?4:rX;
        rX = logoWidth + fabs(rX);
    }
    
    if (rY < logoHeight) {
        rY = (size.height-logoHeight)/2;
        rY = rY==0?4:rY;
        rY = logoHeight + fabs(rY);
    }
    
    if (index == 0) {
        x += rX;
        y += rY;
    }else if(index == (maxIndex/2 - 1)) {
        x = x + size.width - rX;
        y += rY;
    }else if(index == maxIndex/2) {
        x += rX;
        y = y + size.height - rY;
    }else if(index == maxIndex - 1) {
        x = x + size.width - rX;
        y = y + size.height - rY;
    }else {
        x += offX;
        y += offY;
    }
    return CGPointMake(x, y);
}

- (CGFloat)randomFloatFrom:(CGFloat)start To:(CGFloat)end {
    int key = (int)end - (int)start;
    int result = arc4random() % key;
    return start + result;
}

// 根据该点颜色创建相应的颜色字符串
- (NSString*)getPixelColorStringAtLocation:(CGPoint)point withImage:(unsigned char*)data andImageWidth:(size_t)width {
    NSString *string = @"null";
    if (data != NULL) {
        @try {
            int offset = 4*((width*round(point.y))+round(point.x));
            int alpha =  data[offset];
            int red = data[offset+1];
            int green = data[offset+2];
            int blue = data[offset+3];
//            NSLog(@"point : %@ offset: %i length:%lu string: RGB A %i %i %i  %i",NSStringFromCGPoint(point),offset,strlen(data),red,green,blue,alpha);
            string = [NSString stringWithFormat:@"%f,%f,%f,%f",(red/255.0f),(green/255.0f),(blue/255.0f),(alpha/255.0f)];
        }
        @catch (NSException * e) {}
        @finally {}
    }
    return string;
}
    
- (UIColor*) getPixelColorAtLocation:(CGPoint)point withImage:(unsigned char*)data andImageWidth:(size_t)width{
    
    UIColor* color = nil;
    if (data != NULL) {
        @try {
            int offset = 4*((width*round(point.y))+round(point.x));
            int alpha =  data[offset];
            int red = data[offset+1];
            int green = data[offset+2];
            int blue = data[offset+3];
            
            color = [UIColor colorWithRed:(red/255.0f) green:(green/255.0f) blue:(blue/255.0f) alpha:(alpha/255.0f)];
        }
        @catch (NSException * e) {}
        @finally {}
    }
    
    return color;
}

@end
