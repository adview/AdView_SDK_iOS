//
//  AdViewContent.m
//  AdViewHello
//
//  Created by AdView on 13-1-23.
//
//

#import "AdViewContent.h"
#import "AdViewExtTool.h"
#import "AdViewMraidWebView.h"
#import "AdViewVideoViewController.h"

#define ATTRIBUTEDSTRINGTEST 1

#if ATTRIBUTEDSTRINGTEST
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>
#import "AdViewAdManager.h"
#import "UIImage+AdViewBundle.h"
#import "AdViewOMAdHTMLManager.h"

#pragma mark - 配色方案

static NSArray *colorBgs;

@interface AttributedUILabel : UILabel {
    NSMutableAttributedString *attributeStr;
    CGFloat fontSize;
}
@property (retain, nonatomic) NSMutableAttributedString *attributeStr;

- (void)setString:(NSString*)text withFont:(UIFont*)font;

// 设置某段字的颜色
- (void)setColor:(UIColor *)color fromIndex:(NSInteger)location length:(NSInteger)length;

// 设置某段字的字体
- (void)setFont:(UIFont *)font fromIndex:(NSInteger)location length:(NSInteger)length;

// 设置某段字的风格
- (void)setStyle:(CTUnderlineStyle)style fromIndex:(NSInteger)location length:(NSInteger)length;

@end

@implementation AttributedUILabel
@synthesize attributeStr;
- (void)dealloc{
    self.attributeStr = nil;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return  self;
}

- (void)drawRect:(CGRect)rect {
    CATextLayer *textLayer = [CATextLayer layer];
    textLayer.contentsScale = self.layer.contentsScale;
    textLayer.string = self.attributeStr;
    textLayer.backgroundColor = [UIColor clearColor].CGColor;
    CGSize size = CGSizeMake([self.attributeStr length]*fontSize, fontSize);
    CGSize size1 = CGSizeMake(self.frame.size.width, ((int)(size.width / self.frame.size.width) + 1)*(fontSize * 7 / 6 ));
    
    [textLayer setFrame:CGRectMake(0, (self.frame.size.height - size1.height)/2, size1.width, size1.height)];
    textLayer.wrapped = YES;
    [textLayer setNeedsLayout];
    NSArray *array = [self.layer sublayers];
    if (array && [array count]) {
        for (int i = 0; i < [array count]; i++) {
//            if (i != [array count] - 1)
            [[array objectAtIndex:i] removeFromSuperlayer];
        }
    }
    [self.layer addSublayer:textLayer];
}

- (void)setString:(NSString*)text withFont:(UIFont*)font {
    [self setText:text];
    fontSize = font.pointSize;
    if (nil == text)
        attributeStr = nil;
    else
        attributeStr = [[NSMutableAttributedString alloc] initWithString:text];
    
    CTFontRef aFont = CTFontCreateWithName((CFStringRef)font.fontName, font.pointSize, NULL);
    CTFontRef newFont = CTFontCreateCopyWithSymbolicTraits(aFont, 0.0, NULL, kCTFontItalicTrait, kCTFontBoldTrait);
    //    kCTLineBreakByCharWrapping;
    [self.attributeStr addAttribute:(NSString *)kCTFontAttributeName
                              value:(__bridge id)newFont//[(id)CTFontCreateWithName((CFStringRef)font.fontName,font.pointSize,NULL) autorelease]
                              range:NSMakeRange(0, [text length])];
    CFRelease(aFont);
    CFRelease(newFont);
}

- (void)setText:(NSString *)text {
    [super setText:text];
    if (nil == text)
        attributeStr = nil;
    else
        attributeStr = [[NSMutableAttributedString alloc] initWithString:text];
}

- (void)setColor:(UIColor *)color fromIndex:(NSInteger)location length:(NSInteger)length {
    if (location < 0||location>self.text.length-1||length+location>self.text.length) {
        return;
    }
    [self.attributeStr addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)color.CGColor range:NSMakeRange(location, length)];
}

- (void)setFont:(UIFont *)font fromIndex:(NSInteger)location length:(NSInteger)length {
    if (location < 0||location>self.text.length-1||length+location>self.text.length) {
        return;
    }
    CTFontRef aFont = CTFontCreateWithName((CFStringRef)font.fontName, font.pointSize, NULL);
    CTFontRef newFont = CTFontCreateCopyWithSymbolicTraits(aFont, 0.0, NULL, kCTFontItalicTrait, kCTFontBoldTrait);
    //    kCTLineBreakByCharWrapping;
    [self.attributeStr addAttribute:(NSString *)kCTFontAttributeName
                              value:(__bridge id)newFont//[(id)CTFontCreateWithName((CFStringRef)font.fontName,font.pointSize,NULL) autorelease]
                              range:NSMakeRange(location, length)];
    CFRelease(aFont);
    CFRelease(newFont);
}

- (void)setStyle:(CTUnderlineStyle)style fromIndex:(NSInteger)location length:(NSInteger)length {
    if (location < 0||location>self.text.length-1||length+location>self.text.length) {
        return;
    }
    [self.attributeStr addAttribute:(NSString *)kCTUnderlineStyleAttributeName
                              value:(id)[NSNumber numberWithInt:style]
                              range:NSMakeRange(location, length)];
}
@end

#endif

#define RANGE_USELESS_STRING        @"\\{([^\\}])*\\}"
#define REPLACE_USELESS_STRING      @"\\{|\\}"

static int getRandomInt(int range) {
	return 1+(int)(200.0*rand()/(RAND_MAX+1.0));
}

@implementation AdImageItem

@synthesize imgUrl, imgData, img;

- (void)dealloc {
    AdViewLogDebug(@"Dealloc AdImageItem");
    
    self.imgUrl = nil;
    self.imgData = nil;
    self.img = nil;
}

@end

@implementation AdViewAdCondition

@synthesize appId=_appId;
@synthesize appPwd=_appPwd;
@synthesize positionId=_positionId;
@synthesize adSize = _adSize;
@synthesize adTest = _adTest;
@synthesize longitude = _longitude;
@synthesize latitude = _latitude;
@synthesize accuracy = _accuracy;
@synthesize adCount;
@synthesize hasLocationVal = _hasLocationVal;
@synthesize bUseHtml5;

- (void)dealloc {
    self.appId = nil;
    self.appPwd = nil;
}

@end

@interface AdViewContent()
{
//    AttributedUILabel *textLabel;
    NSMutableArray *exchangeArr;
    int exchangeNum;
    int colorTheme;
}

@end

@implementation AdViewContent
//@synthesize colorScheme;
@synthesize colorBG;
@synthesize adPlatType;
@synthesize adWebLoaded;
@synthesize adId;
@synthesize adInfo;
@synthesize adText;
@synthesize adSubText;
@synthesize adTitle;

@synthesize adBody;
@synthesize adBaseUrlStr;

@synthesize adShowType;
@synthesize adLinkType;
@synthesize adLinkURL;
@synthesize fallBack;
@synthesize deepLink;
@synthesize adAppId;

@synthesize errorReportQuery;

@synthesize adCopyrightStr;
@synthesize spreadTextViewSize;
@synthesize adImageItems;

@synthesize adBgImgURL;
@synthesize adBgImg;

@synthesize adActImgURL;
@synthesize adActImg;

@synthesize adWebURL;
@synthesize hostURL;
@synthesize adWebRequest;

@synthesize adInstlImageSize;        /*记录图片大小*/

@synthesize adActionType;
@synthesize adParseError;

@synthesize adRenderBgColorType;

@synthesize adBgColor;
@synthesize adTextColor;

@synthesize spreadImgViewRect;
@synthesize otherShowURL;
@synthesize src;
@synthesize nCurFrame;
@synthesize severAgent;
@synthesize severAgentAdvertiser;
@synthesize monCstring;
@synthesize monSstring;

@synthesize clickSize;

@synthesize forceTime;
@synthesize relayTime;
@synthesize cacheTime;
@synthesize spreadVat = _spreadVat;
@synthesize deformationMode;

@synthesize extendShowUrl;
@synthesize extendClickUrl;
@synthesize maxClickNum;

@synthesize miniProgramDict;

@synthesize nativeDict;

+ (void)load {
	AdViewLogDebug(@"AdViewContent load");
	srand((unsigned)time(0));
}

- (instancetype)initWithAppId:(NSString *)appId {
    if (self = [super init]) {
        self.adAppId = appId;
    }
    return self;
}

#pragma mark - 添加logo标签（右下角）
//将logo标签16进制数字转换成NSData
- (NSData *)changeToDataFromString:(NSString*)logoStr {
    NSInteger a = [logoStr length]/2;
    //将16进制数转成byte数组
    int j = 0;
    Byte bytes[a];//3ds key 的byte数组，128位
    for (int i = 0; i < [logoStr length]; i++) {
        int int_ch;//两位16进制数转化后的10进制数
        
        UniChar hex_char1 = [logoStr characterAtIndex:i];//两位16进制数种的第一位（高位*16）
        int int_ch1;
        if (hex_char1 >= '0' && hex_char1 <= '9') {
            int_ch1 = (hex_char1 - 48)*16;
        }else if(hex_char1 >= 'A' && hex_char1 <= 'F'){
            int_ch1 = (hex_char1 - 55)*16;
        }else {
            int_ch1 = (hex_char1 - 87)*16;
        }
        i++;
        
        unichar hex_char2 = [logoStr characterAtIndex:i];//两位16进制数种的第二位（低位）
        int int_ch2;
        if (hex_char2 >= '0' && hex_char2 <= '9') {
            int_ch2 = (hex_char2 - 48);
        }else if(hex_char1 >= 'A' && hex_char1 <= 'F'){
            int_ch2 = (hex_char2 - 55);
        }else {
            int_ch2 = (hex_char2 - 87);
        }
        
        int_ch = int_ch1 + int_ch2;
        //        NSLog(@"int_ch = %d",int_ch);
        bytes[j] = int_ch;
        j++;
    }
    
    return [[NSData alloc] initWithBytes:bytes length:a];
}

//添加logo标签（右下角adview标示）
- (void)addLogoLabelWithView:(UIView*)ret adType:(AdvertType)adType
{
    //如果是互推则不添加logo标识
    if(self.adPlatType == AdViewAdPlatTypeAdDirect || self.adPlatType == AdViewAdPlatTypeAdExchange) return;
    
    CGFloat scale = 1;
    if (adType == AdViewBanner)
    {
        scale = scale*2/3;
    }
    if ([AdViewExtTool getDeviceIsIpad])
    {
        scale *= 1.5;
    }
    
    if (nil != self.adLogoImg && self.adLogoImg.size.width > 0 && self.adLogoImg.size.height > 0)
    {
        UIImageView *imgView = (UIImageView *)[ret viewWithTag:ADVIEW_LABEL_TAG];
        if (!imgView)
        {
            imgView = [[UIImageView alloc] initWithImage:self.adLogoImg];
            imgView.tag = ADVIEW_LABEL_TAG;
        }
        
        CGFloat labelWidth = scale*self.adLogoImg.size.width;
        CGFloat labelHeight = scale*self.adLogoImg.size.height;
        
        CGFloat ggScale = 1;
        //修正图标过大
        if (self.adLogoImg.size.width > 65 || self.adLogoImg.size.height > 22) {
            ggScale = 0.75;
        }
        imgView.frame = CGRectMake(ret.frame.size.width - labelWidth*ggScale, ret.frame.size.height - labelHeight*ggScale, labelWidth*ggScale, labelHeight*ggScale);
        if (adType == AdViewSpread)
        {
            imgView.frame = CGRectMake(ret.frame.size.width - labelWidth * ggScale,
                                       ret.frame.size.height - labelHeight * ggScale,
                                       labelWidth * ggScale,
                                       labelHeight * ggScale);
        }
        [ret addSubview:imgView];
    }
    
    if (nil != self.adIconImg && self.adIconImg.size.width > 0 && self.adIconImg.size.height > 0) {
        UIImageView *ggImgView = (UIImageView*)[ret viewWithTag:ADVIEW_GG_LABEL_TAG];
        if (!ggImgView) {
            ggImgView = [[UIImageView alloc] initWithImage:self.adIconImg];
            ggImgView.tag = ADVIEW_GG_LABEL_TAG;
        }
        
        CGFloat labelWidth = scale*self.adIconImg.size.width;
        CGFloat labelHeight = scale*self.adIconImg.size.height;

        CGFloat ggScale = 0.9;
        ggImgView.frame = CGRectMake(0, ret.frame.size.height-labelHeight*ggScale, labelWidth*ggScale, labelHeight*ggScale);
        if (adType == AdViewSpread) {
            ggImgView.frame = CGRectMake(0, ret.frame.size.height - labelHeight*ggScale, labelWidth*ggScale, labelHeight*ggScale);
        }

        [ret addSubview:ggImgView];
    }
}

- (id)init {
    self = [super init];
    if (self) {
        [self colorScheme];
        self.maxClickNum = 5;
        AdViewExtTool *tool = [AdViewExtTool sharedTool];
        [tool storeObject:@"-999" forKey:@"__DOWN_X__"];
        [tool storeObject:@"-999" forKey:@"__UP_X__"];
        [tool storeObject:@"-999" forKey:@"__DOWN_Y__"];
        [tool storeObject:@"-999" forKey:@"__UP_Y__"];
    }
    return self;
}

- (void)colorScheme
{
    if (!colorBgs) {
        //默认颜色值
        colorBgs = @[@{@"aibc":@"#252525",@"abc":@"#000000",@"aabc":@"#0876C1",@"amtc":@"#FFFFFF",@"astc":@"#FFFFFF",@"afc":@"#FFFFFF"},@{@"aibc":@"#D7C48C",@"abc":@"#76BBDC",@"aabc":@"#19649B",@"amtc":@"#FFFFFF",@"astc":@"#FFFFFF",@"afc":@"#FFFFFF"},@{@"aibc":@"#BEBABB",@"abc":@"#9E8F88",@"aabc":@"#3C373B",@"amtc":@"#FFFFFF",@"astc":@"#FFFFFF",@"afc":@"#FFFFFF"},@{@"aibc":@"#8BA1C8",@"abc":@"#5E6F8D",@"aabc":@"#33383E",@"amtc":@"#FFFFFF",@"astc":@"#FFFFFF",@"afc":@"#FFFFFF"},@{@"aibc":@"#7B9091",@"abc":@"#111F20",@"aabc":@"#0876C1",@"amtc":@"#FFFFFF",@"astc":@"#FFFFFF",@"afc":@"#FFFFFF"},@{@"aibc":@"#A1969A",@"abc":@"#7D4E62",@"aabc":@"#474143",@"amtc":@"#FFFFFF",@"astc":@"#FFFFFF",@"afc":@"#FFFFFF"}];
    }
    colorBG = [[NSMutableDictionary alloc]initWithDictionary:[colorBgs objectAtIndex:arc4random()%[colorBgs count]]];
}

static CGFloat trimColorVal(CGFloat v)
{
	v = (v>1.0f)?1.0f:v;
	v = (v<0.0f)?0.0f:v;
	return v;
}

- (void)renderBackground:(CGContextRef)context WithSize:(CGSize)size withBgColor:(UIColor*)bgColor {
	[[UIColor whiteColor] setFill];
	CGContextFillRect(context, CGRectMake(0.0f, 0.0f, size.width, size.height));
	
#if  1
    CGFloat rgba[4] = {0, 0, 0, 0};
    if (![bgColor getRed:rgba+0 green:rgba+1 blue:rgba+2 alpha:rgba+3]) {
        if ([bgColor getWhite:rgba+0 alpha:rgba+3]) {
            rgba[1] = rgba[2] = rgba[0];
        } else {
            AdViewLogDebug(@"color fail");
        }
    }
#else
	const CGFloat *rgba;
	rgba = CGColorGetComponents([bgColor CGColor]);
	//glColor4f(rgba[0], rgba[1], rgba[2], rgba[3]);
#endif
	
	CGFloat gray = (CGFloat)(rgba[0]*0.299+rgba[1]*0.587+rgba[2]*0.114);
	
	CGFloat r1, g1, b1;
	
	if (gray > 0.5f) {
		gray -= 0.25f;
		
		r1 = trimColorVal(rgba[0] - 0.25f);
		g1 = trimColorVal(rgba[1] - 0.25f);
		b1 = trimColorVal(rgba[2] - 0.25f);
	} else {
		gray += 0.25f;
		
		r1 = trimColorVal(rgba[0] + 0.25f);
		g1 = trimColorVal(rgba[1] + 0.25f);
		b1 = trimColorVal(rgba[2] + 0.25f);
	}
	
	CGFloat rgb2[] = {r1, g1, b1};
	
	if (GradientColorType_Random == self.adRenderBgColorType) {
		int iMin, iMax, iOther;
		iMin = iMax = iOther = 0;
		for (int i = 1; i < 3; i++) {
			if (rgba[i] > rgba[iMax]) iMax = i;
			else if (rgba[i] < rgba[iMin]) iMin = i;
		}
		
		int rand1 = getRandomInt(300) % 3;
		int rand2 = 0;
		if (0 == rand1) {
			if (iMax != iMin && rgba[iMax] > 0.005 && rgba[iMin]/rgba[iMax] < 0.9) {//not r==g==b
				rgb2[0] = rgba[0];
				rgb2[1] = rgba[1];
				rgb2[2] = rgba[2];
				
				rand2 = getRandomInt(300) % 2;
				iOther = 3 - iMax - iMin;
				
				switch (rand2) {
					case 0:
						rgb2[iMin] = rgba[iMax];
						rgb2[iMax] = rgba[iMin];
						break;
					case 1:
						rgb2[iMin] = rgba[iMax];
						rgb2[iMax] = rgba[iOther];
						rgb2[iOther] = rgba[iMin];
						break;
				}
			} else
				rand1 = 1;	//to as next random color.
		}
		if (1 == rand1) {
			rand2 = getRandomInt(300) % 6;
			CGFloat lowVal = gray - 0.4f;
			if (lowVal < 0.0f) lowVal = 0.0f;
			switch (rand2) {
				case 0:rgb2[1] = rgb2[2] = lowVal; break;
				case 1:rgb2[0] = rgb2[2] = lowVal; break;
				case 2:rgb2[0] = rgb2[1] = lowVal; break;
				case 3:rgb2[0] = lowVal; break;
				case 4:rgb2[1] = lowVal; break;
				case 5:rgb2[2] = lowVal; break;
			}
		}
	}
	
	CGFloat barColors[] = {
		rgba[0], rgba[1], rgba[2], 0.75f,
		rgb2[0], rgb2[1], rgb2[2], 0.75f,
		rgba[0], rgba[1], rgba[2], 0.75f
	};
	
	CGColorSpaceRef colorSpace1 = CGColorSpaceCreateDeviceRGB();
	CGGradientRef _barGradient = nil;
	if (colorSpace1 != NULL)
	{
		_barGradient = CGGradientCreateWithColorComponents(colorSpace1, barColors, NULL, 3);
		if (_barGradient == NULL)
			AdViewLogInfo(@"Failed to create CGGradient");
		CGColorSpaceRelease(colorSpace1);
	}
	CGPoint _barStartPoint = CGPointMake(0.0f, 0.0f);
	CGPoint _barEndPoint = CGPointMake(0.0f, size.height);
	
	if (nil != _barGradient) {
		CGContextDrawLinearGradient(context, _barGradient, _barStartPoint, _barEndPoint,
									0);//kCGGradientDrawsAfterEndLocation);
		CGGradientRelease(_barGradient);
	} else {
		[bgColor setFill];
		CGContextFillRect(context, CGRectMake(0.0f, 0.0f, size.width, size.height));
	}
}

static void kOpenAPIScaleCGSize(CGSize *size, CGSize *size2)
{
	if (size2->width < 1 || size2->height < 1) return;
	
	CGFloat scaleX = size->width / size2->width;
	CGFloat scaleY = size->height / size2->height;
	
	CGFloat scale = scaleX<scaleY?scaleX:scaleY;
	
	size->width = size2->width * scale;
	size->height = size2->height *scale;
	size->width = floor(size->width + 0.5f);
	size->height = floor(size->height + 0.5f);
}

static float scaleEnlargesTheSize(CGSize *size, CGSize *size2)
{
    if (size2->width < 1 || size2->height < 1) return 0;
    
    CGFloat scaleX = size->width / size2->width;
    CGFloat scaleY = size->height / size2->height;
    
    CGFloat scale = scaleX<scaleY?scaleX:scaleY;
    
    size2->width *= scale;
    size2->height *= scale;
    
    return scale;
}

#ifdef __IPHONE_6_0
#define LineBreadMode   NSLineBreakByWordWrapping
#else
#define LineBreadMode   UILineBreakModeWordWrap
#endif
- (void)renderTextInContext:(CGContextRef)context Rect:(CGRect)rect TextColor:(UIColor*)textColor {
    self.adCopyrightStr = self.adText;
	if (nil == self.adText) return;
	
	CGSize size = rect.size;
	CGFloat margin = floor(4*(rect.size.height/48)+0.5f);
	CGRect rect0 = rect;
    //self.adSubText = self.adText;
	
	CGFloat fontHt1 = floor(size.height/3.0f+0.5f);
	CGFloat fontHt2 = floor(size.height/5.0f+0.5f);
    
    if (self.adSubText && [self.adSubText length] > 0) {
        fontHt1 = floor(size.height/3.5f+0.5f);
        fontHt2 = floor(size.height/6.0f+0.5f);
    }
	CGContextSaveGState(context);
	CGContextTranslateCTM(context, 0.0f, size.height);
	CGContextScaleCTM(context, 1.0f, -1.0f);
	
	UIFont * font = [UIFont fontWithName:@"Helvetica" size:fontHt1];
    CGSize textSize = [self.adText sizeWithAttributes:@{NSFontAttributeName: font}];
    
    if (textSize.width > rect0.size.width
        && textSize.width > rect0.size.width * 1.8) {
        fontHt2 *= 0.75f;
    }
	
	NSString* copyString = self.adCopyrightStr;
	UIFont* smallFont = [UIFont fontWithName:@"Helvetica" size:fontHt2];
    
//    CGSize copySize = [copyString sizeWithFont:smallFont forWidth:size.width lineBreakMode:LineBreadMode];
    CGRect copyRect = [copyString boundingRectWithSize:size
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{NSFontAttributeName:smallFont}
                                               context:nil];
    CGSize copySize = copyRect.size;
    
    [textColor set];
	rect0.size.height -= copySize.height;
	CGRect rect1 = CGRectInset(rect0, margin, margin);
    if (textSize.width > rect1.size.width) {        //one line is not enough.
        rect1.size.height += copySize.height;
        
        float fLineNum = textSize.width/rect1.size.width;
        if (textSize.width < rect1.size.width * 2 - copySize.width) {
            textSize = [self.adText drawInRect:rect1 withFont:font];
        } else {
            // >=3 lines
            CGFloat fontHt1_1 = fontHt1*1.8f/fLineNum;
            UIFont* font_1 = [UIFont fontWithName:@"Helvetica" size:fontHt1_1];
            textSize = [self.adText drawInRect:rect1 withFont:font_1];
        }
    }
    else
    {
        textSize = [self.adText drawInRect:rect1 withFont:font];
    }
    
    if (self.adSubText && [self.adSubText length] > 0) {
        UIColor *color2 = [textColor colorWithAlphaComponent:0.7];
        UIFont  *font2 = [UIFont italicSystemFontOfSize:fontHt1];
        [color2 set];
        
        CGRect rect2 = CGRectOffset(rect0, textSize.height*2, textSize.height+margin);
        [self.adSubText drawInRect:rect2 withAttributes:@{NSFontAttributeName:font2}];
        [textColor set];
    }
	
    [copyString drawAtPoint:CGPointMake(rect.origin.x + size.width - copySize.width - margin,
                                        rect.origin.y + size.height - copySize.height - margin)
             withAttributes:@{NSFontAttributeName:smallFont}];
    
	CGContextRestoreGState(context);
}

- (UIImage *)makeBGColorImageViewWithSize:(CGSize)size withBgColor:(UIColor *)bgColor
{
    int dx = (int) size.width;
    int dy = (int) size.height;
    void* imagePixel = malloc (dx * 4 * dy);
    if (!imagePixel) {
        return nil;
    }
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
    [self renderBackground:context WithSize:size withBgColor:bgColor];
    UIGraphicsPopContext();
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage* img = [UIImage imageWithCGImage: imgRef];
    CGImageRelease(imgRef);
    CGContextRelease(context);
    free(imagePixel);
    CGColorSpaceRelease(colorSpace);
    
    return img;
}

- (NSMutableDictionary*)uselessStringRange:(NSString*)string{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    while (1) {
        NSRange range = [string rangeOfString:RANGE_USELESS_STRING options:NSRegularExpressionSearch];
        if (range.location == NSNotFound || range.length == 0) break;
        [dict setObject:[NSNumber numberWithInteger:range.length - 2] forKey:[NSNumber numberWithInteger:range.location]];
        string = [string stringByReplacingCharactersInRange:NSMakeRange(range.location, 1) withString:@""];
        string = [string stringByReplacingCharactersInRange:NSMakeRange(range.location + range.length - 2
                                                                        , 1) withString:@""];
    }
    return dict;
}

- (void)animExchangeAd:(UIView*)view {
    if (!self.adSubText) {
        return;
    }
    if (![view subviews]) {
        return;
    }

    UIView *textView = [view viewWithTag:100];
    if (nil == textView) {
        return;
    }
    AttributedUILabel *textLabel = (AttributedUILabel*)[textView viewWithTag:1000];
    
    exchangeNum += 1;
    exchangeNum %= [exchangeArr count];
    
    NSMutableDictionary *dict = [exchangeArr objectAtIndex:exchangeNum];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationTransition:6 forView:textLabel cache:YES];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:1.0f];
    
    [textLabel setString:[dict objectForKey:@"text"] withFont:[dict objectForKey:@"font"]];
    if (!exchangeNum) {
//        [NSString stringWithUTF8String:colorScheme.titleColor]
        [textLabel setColor:[self hexStringToColor:[colorBG objectForKey:@"amtc"]] fromIndex:0 length:[[dict objectForKey:@"text"] length]];
    }else
        [textLabel setColor:[self hexStringToColor:[colorBG objectForKey:@"astc"]] fromIndex:0 length:[[dict objectForKey:@"text"] length]];
    
    for (id num in [dict allKeys]) {
        if ([num isKindOfClass:[NSNumber class]]) {
            [textLabel setColor:[self hexStringToColor:[colorBG objectForKey:@"afc"]] fromIndex:[num intValue] length:[[dict objectForKey:num] intValue]];
        }
    }
    
    [UIView commitAnimations];
}

-(UIView *) MakeAdFillViewWithSize:(CGSize)size withBgColor:(UIColor *)bgColor withTextColor:(UIColor *)textColor {
    UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    view.backgroundColor = [self hexStringToColor:[colorBG objectForKey:@"abc"]];
    view.tag = 100;
    
    CGFloat imgWidth = 0;
    CGFloat imgHeight = 0;
    CGFloat edge1r = floor(5.0f * (size.height/48) + 0.5f);
    CGFloat edge2r = edge1r * 2;
    UIImage *adImage = [self getAdImage:0];
    
    if (adImage) {
        AdViewLogInfo(@"adImage Size:%@", NSStringFromCGSize(adImage.size));
        CGSize imageSize = adImage.size;
        CGSize imageBound;
        BOOL bLeftStruct = YES;
        if (size.width > size.height * 3) {
            imageBound = CGSizeMake(size.width - edge2r, size.height - edge2r);
        } else {
            bLeftStruct = NO;
            imgHeight = size.height * 2 / 3;
            imageBound = CGSizeMake(size.width - edge2r, imgHeight - edge2r);
        }
        
        CGSize image = imageBound;
        kOpenAPIScaleCGSize(&image, &imageSize);
        CGPoint thumbnailPoint = CGPointMake((imageBound.width - image.width)/2, (imageBound.height - image.height)/2);
        
        if (bLeftStruct) {
            thumbnailPoint.x = 0.0;
            imgWidth = image.width;
        } else {
            thumbnailPoint.y = size.height - image.height - edge2r;
        }
        
        CGRect rectImg = CGRectMake(thumbnailPoint.x + edge1r, thumbnailPoint.y + edge1r, image.width, image.height);
        
        UIImageView *img = [[UIImageView alloc] initWithImage:adImage];
        img.layer.cornerRadius = 9.0;
        img.layer.masksToBounds = YES;
        img.frame = rectImg;
        //icon添加背景视图
        UIView *iconBgView = [[UIView alloc] init];
        iconBgView.backgroundColor = [self hexStringToColor:[colorBG objectForKey:@"aibc"]];
        iconBgView.frame = CGRectMake(thumbnailPoint.x, thumbnailPoint.y, image.width+2*edge1r, image.height+2*edge1r);
        [view addSubview:iconBgView];
        [iconBgView addSubview:img];
    }
    
    CGFloat actImgWidth = 0;
    
    if ([self.adActImg size].width <= 0) {
        switch (self.adActionType) {
            case AdViewAdActionType_Web:
                self.adActImg = [UIImage imagesNamedFromCustomBundle:@"icon_web.png"];
                break;
            case AdViewAdActionType_AppStore:
                self.adActImg = [UIImage imagesNamedFromCustomBundle:@"icon_down.png"];
                break;
            case AdViewAdActionType_Map:
                self.adActImg = [UIImage imagesNamedFromCustomBundle:@"icon_map.png"];
                break;
            case AdViewAdActionType_Sms:
                self.adActImg = [UIImage imagesNamedFromCustomBundle:@"icon_ems.png"];
                break;
            case AdViewAdActionType_Mail:
                self.adActImg = [UIImage imagesNamedFromCustomBundle:@"icon_email.png"];
                break;
            case AdViewAdActionType_Call:
                self.adActImg = [UIImage imagesNamedFromCustomBundle:@"icon_call.png"];
                break;
            case AdViewAdActionType_Unknown:
                self.adActImg = [UIImage imagesNamedFromCustomBundle:@"icon_video.png"];
                break;
            default:
                break;
        }
    }
    AdViewLogInfo(@"ActionImg Size:%@", NSStringFromCGSize(self.adActImg.size));
    CGFloat actionImgWidth = size.width - size.height;
    CGRect actionImg = CGRectMake(actionImgWidth, 0, size.height, size.height);
    UIView *bgView = [[UIView alloc] initWithFrame:actionImg];
    bgView.backgroundColor = [self hexStringToColor:[colorBG objectForKey:@"aabc"]];
    CGFloat imageHgt = size.height * 12 / 25;
    UIImageView *actImage = [[UIImageView alloc] initWithImage:self.adActImg];
    actImage.backgroundColor = [UIColor clearColor];
    actImage.frame = CGRectMake(size.height/4, size.height/4, imageHgt, imageHgt);
    [view addSubview:bgView];
    [bgView addSubview:actImage];
    actImgWidth = size.height;

    
    CGRect textRect = CGRectMake(imgWidth + edge2r + edge1r, 0, size.width - imgWidth - actImgWidth - edge2r, size.height - imgHeight);
    
    if (self.adText) {
        CGSize textSize = textRect.size;
        CGFloat margin = floor(4*(textRect.size.height/48) + 0.5f);
        
        CGFloat textHeight = textSize.height - 2*margin;
        
        CGFloat textHgt = textHeight * 3 / 5;
        
        UIFont *font = [UIFont fontWithName:@"Helvetica" size:textHgt*2/3];
        if (font.pointSize * [self.adText length] > textSize.width) {
            font = [UIFont fontWithName:@"Helvetica" size:textHgt / 2];
            if (font.pointSize * [self.adText length] > textSize.width * 2) {
                font = [UIFont fontWithName:@"Helvetica" size:textHgt / 3];
            }
        }

        exchangeArr = [[NSMutableArray alloc] initWithCapacity:0];
        
        AttributedUILabel *textLabel = [[AttributedUILabel alloc] initWithFrame:textRect];
        textLabel.backgroundColor = [self hexStringToColor:[colorBG objectForKey:@"abc"]];
        NSDictionary *titleDict = [self uselessStringRange:self.adText];
        NSString *adText1 = [self.adText stringByReplacingOccurrencesOfString:REPLACE_USELESS_STRING withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [self.adText length])];
        [textLabel setString:adText1 withFont:font];
        [textLabel setColor:[self hexStringToColor:[colorBG objectForKey:@"amtc"]] fromIndex:0 length:[adText1 length]];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:titleDict];
        [dict setObject:adText1 forKey:@"text"];
        [dict setObject:font forKey:@"font"];
        for (NSNumber * num in [titleDict allKeys]) {
            [textLabel setColor:[self hexStringToColor:[colorBG objectForKey:@"afc"]] fromIndex:[num intValue] length:[[titleDict objectForKey:num] intValue]];
        }
        textLabel.tag = 1000;
        [view addSubview:textLabel];
        [exchangeArr addObject:dict];
        exchangeNum = 0;
        if (self.adSubText) {
            NSArray * arr = [self.adSubText componentsSeparatedByString:@"\n"]; // 可能存在两条和在一起由"\n"分隔
            UIFont *subFont = [UIFont fontWithName:@"Helvetica" size:textHgt*2/3];

            if (arr && [arr count] > 1) {
                NSString *str1 = [arr objectAtIndex:0];
                NSString *str2 = [arr objectAtIndex:1];
                if (subFont.pointSize * [str1 length] > textSize.width) {
                    subFont = [UIFont fontWithName:@"Helvetica" size:textHgt / 2];
                    if (subFont.pointSize * [str1 length] > textSize.width * 2) {
                        subFont = [UIFont fontWithName:@"Helvetica" size:textHgt / 3];
                    }
                }
                NSDictionary *str1Dict = [self uselessStringRange:str1];
                NSString *string1 = [str1 stringByReplacingOccurrencesOfString:REPLACE_USELESS_STRING withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [str1 length])];
                NSMutableDictionary *dict1 = [NSMutableDictionary dictionaryWithDictionary:str1Dict];
                [dict1 setObject:string1 forKey:@"text"];
                [dict1 setObject:subFont forKey:@"font"];
                
                if (subFont.pointSize * [str2 length] > textSize.width) {
                    subFont = [UIFont fontWithName:@"Helvetica" size:textHgt / 2];
                    if (subFont.pointSize * [str2 length] > textSize.width * 2) {
                        subFont = [UIFont fontWithName:@"Helvetica" size:textHgt / 3];
                    }
                }
                NSDictionary *str2Dict = [self uselessStringRange:str2];
                NSString *string2 = [str2 stringByReplacingOccurrencesOfString:REPLACE_USELESS_STRING withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [str2 length])];
                NSMutableDictionary *dict2 = [NSMutableDictionary dictionaryWithDictionary:str2Dict];
                [dict2 setObject:string2 forKey:@"text"];
                [dict2 setObject:subFont forKey:@"font"];
                [exchangeArr addObject:dict1];
                [exchangeArr addObject:dict2];
            }else {
                if (subFont.pointSize * [self.adSubText length] > textSize.width) {
                    subFont = [UIFont fontWithName:@"Helvetica" size:textHgt / 2];
                    if (subFont.pointSize * [self.adSubText length] > textSize.width * 2) {
                        subFont = [UIFont fontWithName:@"Helvetica" size:textHgt / 3];
                    }
                }
                NSDictionary *subDict = [self uselessStringRange:self.adSubText];
                NSString *replaceStr = [self.adSubText stringByReplacingOccurrencesOfString:REPLACE_USELESS_STRING withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [self.adSubText length])];
                NSMutableDictionary *subConDict = [NSMutableDictionary dictionaryWithDictionary:subDict];
                [subConDict setObject:replaceStr forKey:@"text"];
                [subConDict setObject:subFont forKey:@"font"];
                [exchangeArr addObject:subConDict];
            }
        }
    }
    return view;
}

-(UIView *) makeAdFillViewWithSize:(CGSize)size withBgColor:(UIColor *)bgColor withTextColor:(UIColor *)textColor {
    UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage *useBgImg = self.adBgImg;
    if (nil == useBgImg) {
        useBgImg = [self makeBGColorImageViewWithSize:size withBgColor:bgColor];
    }
    
    UIImageView *bgImg = [[UIImageView alloc] initWithFrame:
                          CGRectMake(0, 0, size.width, size.height)
                          ];
    bgImg.layer.cornerRadius = 5.0;
    bgImg.layer.masksToBounds = YES;
    bgImg.image = useBgImg;
    [view addSubview:bgImg];
    
    CGFloat imgWidth = 0;
    CGFloat imgHeight = 0;
    CGFloat edge1r = floor(3.0f * (size.height/48) + 0.5f);
    CGFloat edge2r = edge1r * 2;
    UIImage *adImage = [self getAdImage:0];
    
    if (adImage) {
        AdViewLogInfo(@"adImage Size:%@", NSStringFromCGSize(adImage.size));
        CGSize imageSize = adImage.size;
        CGSize imageBound;
        BOOL bLeftStruct = YES;
        if (size.width > size.height * 3) {
            imageBound = CGSizeMake(size.width - edge2r, size.height - edge2r);
        } else {
            bLeftStruct = NO;
            imgHeight = size.height * 2 / 3;
            imageBound = CGSizeMake(size.width - edge2r, imgHeight - edge2r);
        }
        
        CGSize image = imageBound;
        kOpenAPIScaleCGSize(&image, &imageSize);
        CGPoint thumbnailPoint = CGPointMake((imageBound.width - image.width)/2, (imageBound.height - image.height)/2);
        
        if (bLeftStruct) {
            thumbnailPoint.x = 0.0;
            imgWidth = image.width;
        } else {
            thumbnailPoint.y = size.height - image.height - edge2r;
        }
        
        CGRect rectImg = CGRectMake(thumbnailPoint.x + edge1r, thumbnailPoint.y + edge1r, image.width, image.height);
        
        UIImageView *img = [[UIImageView alloc] initWithImage:adImage];
        img.layer.cornerRadius = 5.0;
        img.layer.masksToBounds = YES;
        img.frame = rectImg;
        [view addSubview:img];
    }
    
    CGFloat actImgWidth = 0;
    
    if ([self.adActImg size].width > 0) {
        AdViewLogInfo(@"ActionImg Size:%@", NSStringFromCGSize(self.adActImg.size));
        CGFloat actionImgWidth = size.width - size.height * 14 / 12;
        CGRect actionImg = CGRectMake(actionImgWidth, size.height / 6, size.height, size.height * 2 / 3);
        UIImageView *actImage = [[UIImageView alloc] initWithImage:self.adActImg];
        actImage.frame = actionImg;
        [view addSubview:actImage];
        actImgWidth = size.height * 14 / 12;
    }
    
    CGRect textRect = CGRectMake(imgWidth + edge2r, 0, size.width - imgWidth - actImgWidth - edge2r, size.height - imgHeight);
    
    if (self.adText) {
        CGSize textSize = textRect.size;
        CGRect rect0 = textRect;
        CGFloat margin = floor(4*(textRect.size.height/48) + 0.5f);
        
        CGFloat textHeight = textSize.height - 2*margin;
        //        CGFloat fontHt1 = floor(textHeight*3/5);
        //        CGFloat fontHt2 = floor(textHeight*2/5);
        
        CGFloat textHgt = textHeight * 3 / 5;
        //CGFloat subTextHgt = textHeight * 2 /5;
        
        CGFloat unitTextHgt = textHeight / 5;
        
        UIFont *font;
        CGSize adTextSize;
        
        if (self.adSubText && [self.adSubText length] > 0) {
#if ATTRIBUTEDSTRINGTEST
            CGFloat subLabelHgt = unitTextHgt *2;
            CGFloat textLabelHgt = unitTextHgt *3;
            UIFont *font1 = [UIFont fontWithName:@"Helvetica" size:subLabelHgt * 2 / 3];
            font = [UIFont fontWithName:@"Helvetica" size:textLabelHgt * 2 / 3];
            CGSize adSubSize = [self.adSubText sizeWithAttributes:@{NSFontAttributeName:font}];
            if (adSubSize.width > rect0.size.width) {
                subLabelHgt = unitTextHgt *3;
                textLabelHgt = unitTextHgt *2;
                font1 = [UIFont fontWithName:@"Helvetica" size:subLabelHgt / 3];
                font = [UIFont fontWithName:@"Helvetica" size:textLabelHgt * 2 / 3];
                if ([self.adSubText sizeWithAttributes:@{NSFontAttributeName:font1}].width < rect0.size.width) {
                    font1 = [UIFont fontWithName:@"Helvetica" size:subLabelHgt * 4 / 9];
                    font = [UIFont fontWithName:@"Helvetica" size:1];
                }
            }
            
            CGRect rect2 = CGRectMake(rect0.origin.x, textHgt + margin, rect0.size.width, subLabelHgt);
            CGRect rect1 = CGRectMake(rect0.origin.x, textHgt + margin, rect0.size.width, textLabelHgt);
            AttributedUILabel *subLabel = [[AttributedUILabel alloc] initWithFrame:rect2];
            NSDictionary *subTextDict = [self uselessStringRange:self.adSubText];
            NSString *subString = [self.adSubText stringByReplacingOccurrencesOfString:REPLACE_USELESS_STRING withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [self.adSubText length])];
            subLabel.text = subString;
            [subLabel setColor:textColor fromIndex:0 length:[subString length]];
            for (NSNumber * num in [subTextDict allKeys]) {
                [subLabel setColor:[UIColor redColor] fromIndex:[num intValue] length:[[subTextDict objectForKey:num] intValue]];
            }
            if (adSubSize.width > rect0.size.width) {
                subLabel.numberOfLines = 2;
                subLabel.lineBreakMode = NSLineBreakByCharWrapping;
            }else {
                subLabel.numberOfLines = 1;
                subLabel.lineBreakMode = NSLineBreakByCharWrapping;
            }
            [subLabel setFont:font1 fromIndex:0 length:[subString length]];
            adSubSize = [subString sizeWithAttributes:@{NSFontAttributeName:font1}];
            CGFloat subY = adSubSize.width > rect2.size.width?adSubSize.height *2 :adSubSize.height;
            subLabel.frame = CGRectMake(rect2.origin.x, textHeight - subY + margin - 2, rect2.size.width, subY + 2);
#else
            CGRect rect1 = CGRectMake(rect0.origin.x, rect0.origin.y + margin, rect0.size.width , textHgt);
            UIFont *font1 = [UIFont fontWithName:@"Helvetica" size:subTextHgt*2/3];
            CGSize adSubSize = [self.adSubText sizeWithFont:font1];
            CGRect rect2 = CGRectMake(rect0.origin.x, textHgt + margin, rect0.size.width, subTextHgt);
            UILabel *subLabel = [[UILabel alloc] initWithFrame:rect2];
            subLabel.text = adSubText;
            subLabel.textColor = textColor;
            subLabel.font = font1;
            if (adSubSize.width > rect0.size.width) {
                textHgt = textHeight / 2;
                subTextHgt = textHeight / 2;
                font = [UIFont fontWithName:@"Helvetica" size:textHgt*2/3];
                font1 = [UIFont fontWithName:@"Helvetica" size:subTextHgt*2/3];
                float fLineNum = adSubSize.width/rect2.size.width;
                if (adSubSize.width < rect2.size.width * 2) {
                    subLabel.numberOfLines = 2;
                    subLabel.lineBreakMode = NSLineBreakByCharWrapping;
                    subLabel.font = font1;
                } else {//line
                    subLabel.numberOfLines = fLineNum;
                    subLabel.lineBreakMode = NSLineBreakByCharWrapping;
                    CGFloat fontHt1_1 = subTextHgt*1.8f/fLineNum;
                    UIFont *font_1 = [UIFont fontWithName:@"Helvetica" size:fontHt1_1];
                    subLabel.font = font_1;
                }
            }
#endif
            subLabel.backgroundColor = [UIColor clearColor];
            [view addSubview:subLabel];
#if ATTRIBUTEDSTRINGTEST
            AttributedUILabel *adTextLabel = [[AttributedUILabel alloc] initWithFrame:rect1];
            NSDictionary *adTextDict = [self uselessStringRange:self.adText];
            NSString *adText1 = [self.adText stringByReplacingOccurrencesOfString:REPLACE_USELESS_STRING withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [self.adText length])];
            adTextLabel.text = adText1;
            [adTextLabel setColor:textColor fromIndex:0 length:[adText1 length]];
            for (NSNumber * num in [adTextDict allKeys]) {
                [adTextLabel setColor:[UIColor redColor] fromIndex:[num intValue] length:[[adTextDict objectForKey:num] intValue]];
            }
            [adTextLabel setFont:font fromIndex:0 length:[adText1 length]];
            adTextSize = [adText1 sizeWithAttributes:@{NSFontAttributeName:font}];
            CGFloat y = adTextSize.width > rect1.size.width?adTextSize.height * 2 : adTextSize.height;
            adTextLabel.frame = CGRectMake(rect1.origin.x, (textHgt - y+3) / 2, rect1.size.width, y+2);
            adTextLabel.backgroundColor = [UIColor clearColor];
            [view addSubview:adTextLabel];
        } else {
            CGRect rect1 = CGRectMake(rect0.origin.x, rect0.origin.y + margin, rect0.size.width, textHeight);
            AttributedUILabel *adTextLabel = [[AttributedUILabel alloc] initWithFrame:rect1];
            NSDictionary *adTextDict = [self uselessStringRange:self.adText];
            NSString *adText1 = [self.adText stringByReplacingOccurrencesOfString:REPLACE_USELESS_STRING withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [self.adText length])];
            adTextLabel.text = adText1;
            [adTextLabel setColor:textColor fromIndex:0 length:[adText1 length]];
            for (NSNumber * num in [adTextDict allKeys]) {
                [adTextLabel setColor:[UIColor redColor] fromIndex:[num intValue] length:[[adTextDict objectForKey:num] intValue]];
            }
            adTextLabel.backgroundColor = [UIColor clearColor];
            font = [UIFont fontWithName:@"Helvetica" size:textHeight*12/25];
            [adTextLabel setFont:font fromIndex:0 length:[adText1 length]];
            adTextSize = [adText1 sizeWithAttributes:@{NSFontAttributeName:font}];
            if (adTextSize.width > rect1.size.width) {// one line is not enough.
                //                float fLineNum = adTextSize.width/rect1.size.width;
                if (adTextSize.width < rect1.size.width*1.2) {
                    font = [UIFont fontWithName:@"Helvetica" size:textHeight*2/5];
                } else {
                    //                    CGFloat fontHt1_1 = subTextHgt*1.8f/fLineNum;
                    //                    UIFont *font_1 = [UIFont fontWithName:@"Helvetica" size:fontHt1_1];
                    //                    [adTextLabel setFont:font_1 fromIndex:0 length:[adText1 length]];
                    font = [UIFont fontWithName:@"Helvetica" size:textHeight*8/25];
                }
                [adTextLabel setFont:font fromIndex:0 length:[adText1 length]];
                adTextSize = [adText1 sizeWithAttributes:@{NSFontAttributeName:font}];
            }
            CGFloat y = adTextSize.width > rect1.size.width?adTextSize.height * 2 : adTextSize.height;
            adTextLabel.frame = CGRectMake(rect0.origin.x, (textHeight - y+3) / 2, rect0.size.width, y+2);
#else
            UILabel *adTextLabel = [[UILabel alloc] initWithFrame:rect1];
            adTextLabel.text = self.adText;
            adTextLabel.textColor = textColor;
            adTextLabel.font = font;
            adTextLabel.backgroundColor = [UIColor clearColor];
            [view addSubview:adTextLabel];
            [adTextLabel release];
        } else {
            CGRect rect1 = CGRectMake(rect0.origin.x, rect0.origin.y + margin, rect0.size.width, textHeight);
            UILabel *adTextLabel = [[UILabel alloc] initWithFrame:rect1];
            adTextLabel.text = self.adText;
            adTextLabel.textColor = textColor;
            adTextLabel.backgroundColor = [UIColor clearColor];
            if (adTextSize.width > rect1.size.width) {// one line is not enough.
                float fLineNum = adTextSize.width/rect1.size.width;
                if (adTextSize.width < rect1.size.width*2) {
                    adTextLabel.numberOfLines = 2;
                    adTextLabel.lineBreakMode = NSLineBreakByCharWrapping;
                    adTextLabel.font = font;
                } else {
                    CGFloat fontHt1_1 = subTextHgt*1.8f/fLineNum;
                    UIFont *font_1 = [UIFont fontWithName:@"Helvetica" size:fontHt1_1];
                    adTextLabel.font = font_1;
                    adTextLabel.numberOfLines = fLineNum;
                    adTextLabel.lineBreakMode = NSLineBreakByCharWrapping;
                }
            }
#endif
            [view addSubview:adTextLabel];
        }
    }
    return view;
}

#define DRAW_IMAGE  1

- (UIImage*)renderWithSize:(CGSize)size withBgColor:(UIColor*)bgColor withTextColor:(UIColor*) textColor
{
	AdViewAdSHowType showTypeVal = self.adShowType;
	int density = [AdViewExtTool getDensity];
	size.width *= density;
	size.height *= density;
	
    int nImgFrame = self.nCurFrame - 1;
    if ([self.adImageItems count] > 0)
        nImgFrame %= [self.adImageItems count];
    else
        nImgFrame = 0;
    
    UIImage *adImage = [self getAdImage:nImgFrame];
	if (nil != adImage) {
		AdViewLogInfo(@"adImage Size:%@", NSStringFromCGSize(adImage.size));
		CGSize orgSize = adImage.size;
		BOOL bOrgOK = (orgSize.width > 0 && orgSize.height > 0);
		if (bOrgOK && (AdViewAdSHowType_FullImage == showTypeVal
					   || AdViewAdSHowType_FullGif == showTypeVal))
		{//same scale.
			kOpenAPIScaleCGSize(&size, &orgSize);
		}
	}
    
    if (nil != self.adBgImg) {
        CGSize orgSize = self.adBgImg.size;
		BOOL bOrgOK = (orgSize.width > 30 && orgSize.height > 30);
		if (bOrgOK)
		{//same scale.
			kOpenAPIScaleCGSize(&size, &orgSize);
		}
    }
	
    int dx = (int) size.width;
    int dy = (int) size.height;
    void* imagePixel = malloc (dx * 4 * dy);
    if (!imagePixel) {
        return nil;
    }
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_1
    int bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
#else
    int bitmapInfo = kCGImageAlphaPremultipliedLast;
#endif
    
    CGContextRef context = CGBitmapContextCreate(imagePixel, dx, dy, 8, 4*dx, colorSpace, bitmapInfo);
    UIGraphicsPushContext(context);
	
	if (GradientColorType_None == self.adRenderBgColorType) {
		[bgColor setFill];
		CGContextFillRect(context, CGRectMake(0.0f, 0.0f, size.width, size.height));
	} else {
		[self renderBackground:context WithSize:size withBgColor:bgColor];
	}
    
    if (nil != self.adBgImg) {
        [self.adBgImg drawInRect:CGRectMake(0, 0, size.width - 0 , size.height - 0)];
    }
    
    if (AdViewAdSHowType_Text == showTypeVal && self.adText ) {
		[self renderTextInContext:context
                             Rect:CGRectMake(0, 0, size.width, size.height)
						TextColor:textColor];
    } else if (AdViewAdSHowType_ImageText == showTypeVal) {
		CGFloat imgDrawWidth = 0;
        CGFloat imgDrawHeight = 0;
        CGFloat edge1r = floor( 1.0f * (size.height/48) + 0.5f);
        CGFloat edge2r = edge1r*2;
#if 1
		if (adImage) {
			CGSize imageSize = adImage.size;
			CGSize imageBound;
            
            BOOL    bLeftStruct = YES;
			
            if (size.width > size.height * 3) { //left image, right text
                if (size.width < size.height) {
                    imageBound = CGSizeMake(size.width - edge2r, size.width - edge2r);
                } else {
                    imageBound = CGSizeMake(size.height - edge2r, size.height - edge2r);
                }
            } else {//top image, bottom text
                bLeftStruct = NO;
                imgDrawHeight = size.height*2/3;
                imageBound = CGSizeMake(size.width - edge2r, imgDrawHeight - edge2r);
            }
			
			CGSize imageDraw = imageBound;
			
			kOpenAPIScaleCGSize(&imageDraw, &imageSize);
			CGPoint thumbnailPoint = CGPointMake((imageBound.width-imageDraw.width)/2,
                                                 (imageBound.height-imageDraw.height)/2);
            
            if (bLeftStruct) {
                thumbnailPoint.x = 0.0;
                imgDrawWidth = imageDraw.width;
            } else {
                thumbnailPoint.y = size.height - imageDraw.height - edge2r;
            }
			
            CGRect rectImg = CGRectMake(thumbnailPoint.x + edge1r,
                                        thumbnailPoint.y + edge1r,
                                        imageDraw.width, imageDraw.height);
            
			CGContextDrawImage(context, rectImg, [adImage CGImage]);
		}
#endif
        if (self.adText) {
			[self renderTextInContext:context Rect:CGRectMake(imgDrawWidth, 0, size.width - imgDrawWidth, size.height - imgDrawHeight)
							TextColor:textColor];
        }
    } else if (AdViewAdSHowType_FullImage == showTypeVal) {
#if DRAW_IMAGE
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, 0.0f, size.height);
        CGContextScaleCTM(context, 1.0f, -1.0f);
        [adImage drawInRect:CGRectMake(0, 0, size.width - 0 , size.height - 0)];
        CGContextRestoreGState(context);
        //CGContextDrawImage(context, CGRectMake(0, 0, size.width - 0 , size.height - 0), [self.adImage CGImage]);
#endif
    } else if (AdViewAdSHowType_FullGif == showTypeVal) {//gif animation image. should use imageview.
#if DRAW_IMAGE
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, 0.0f, size.height);
        CGContextScaleCTM(context, 1.0f, -1.0f);
        [adImage drawInRect:CGRectMake(0, 0, size.width - 0 , size.height - 0)];
        CGContextRestoreGState(context);
#endif
	}
    UIGraphicsPopContext();
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage* img = [UIImage imageWithCGImage: imgRef];
    CGImageRelease(imgRef);
    CGContextRelease(context);
    free(imagePixel);
    CGColorSpaceRelease(colorSpace);
    return img;
}

/*根据图片的大小算当前比例*/
- (CGSize)withTheProportion:(CGSize)imagesize withSize:(CGSize)showSize
{
    if (imagesize.width <= showSize.width && imagesize.height <= showSize.height) {
        return imagesize;
    }else
        scaleEnlargesTheSize(&showSize, &imagesize);
    return imagesize;
}

- (void)conversionClickSizeWith:(CGSize)relativeSize {//开屏返回点击区域转换成正常点击尺寸
    //clickSize是在图片上的相对位置（千分之），比如(0,0,1000,1000)表示整个图片位置，(0,500,1000,500)表示图片下半区域。
    const CGFloat CLICKABLE_BASE = 1000.0f;
    CGRect rectOrg = self.clickSize;
    self.clickSize = CGRectMake(rectOrg.origin.x*relativeSize.width/CLICKABLE_BASE,
                                rectOrg.origin.y*relativeSize.height/CLICKABLE_BASE,
                                rectOrg.size.width*relativeSize.width/CLICKABLE_BASE,
                                rectOrg.size.height*relativeSize.height/CLICKABLE_BASE);
}

- (UIImage*)makeAdSpreadViewImageWithSize:(CGSize)size
{
    AdViewAdSHowType showTypeVal = self.adShowType ;
    self.adverType = AdViewSpread;
    
    int nImgFrame = self.nCurFrame - 1;
    if ([self.adImageItems count] > 0)
        nImgFrame %= [self.adImageItems count];
    else
        nImgFrame = 0;
    
    CGSize adImgSize = CGSizeMake(0, 0);
    UIImage *adImage = [self getAdImage:nImgFrame];
    if (nil != adImage) {
        AdViewLogInfo(@"adImage Size:%@", NSStringFromCGSize(adImage.size));
        adImgSize = adImage.size;
        BOOL bOrgOK = (adImgSize.width > 0 && adImgSize.height > 0);
        if (bOrgOK && (AdViewAdSHowType_FullImage == showTypeVal
                       || AdViewAdSHowType_FullGif == showTypeVal))
        {//same scale.
            scaleEnlargesTheSize(&size, &adImgSize);
        }
    }
    
    CGSize rectSize = CGSizeMake(adImgSize.width, adImgSize.height);

    int dx = (int) rectSize.width;
    int dy = (int) rectSize.height;
    void* imagePixel = malloc (dx * 4 * dy);
    if (!imagePixel) {
        return nil;
    }
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
    
    if (AdViewAdSHowType_FullImage == showTypeVal) {
#if DRAW_IMAGE
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, 0.0f, rectSize.height);
        CGContextScaleCTM(context, 1.0f, -1.0f);
        [adImage drawInRect:CGRectMake(0, 0, adImgSize.width - 0 , adImgSize.height - 0)];
        CGContextRestoreGState(context);
        //CGContextDrawImage(context, CGRectMake(0, 0, size.width - 0 , size.height - 0), [self.adImage CGImage]);
#endif
    } else if (AdViewAdSHowType_FullGif == showTypeVal) {//gif animation image. should use imageview.
#if DRAW_IMAGE
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, 0.0f, rectSize.height);
        CGContextScaleCTM(context, 1.0f, -1.0f);
        [adImage drawInRect:CGRectMake(0, 0, rectSize.width - 0 , rectSize.height - 0)];
        CGContextRestoreGState(context);
#endif
    }
    UIGraphicsPopContext();
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage* img = [UIImage imageWithCGImage: imgRef];
    CGImageRelease(imgRef);
    CGContextRelease(context);
    free(imagePixel);
    CGColorSpaceRelease(colorSpace);
    
    return img;
}

- (UIView*)makeAdSpreadTextViewWithFrame:(CGRect)rect
{
    if (self.adShowType != AdViewAdSHowType_Text) {
        return nil;
    }
    UIColor *bgColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1];
    UIColor *textColor = [UIColor blackColor];
    if (self.adBgColor && [adBgColor length] > 0)
    {
        bgColor = [self hexStringToColor:self.adBgColor];
    }
    if (self.adTextColor && [adTextColor length] > 0)
    {
        textColor = [self hexStringToColor:self.adTextColor];
    }
    
    if ([self.adText length] < 1 && [self.adSubText length] < 1) return nil;
    
    NSString *mainText = [self.adText length] > 0? self.adText:self.adSubText;
    NSString *secondText = [self.adText length] > 0? self.adSubText:nil;
    CGRect rectMain, rectSecond, rectIcon;
    
    self.adActImg = [UIImage imagesNamedFromCustomBundle:@"icon_web.png"];
    rectIcon = CGRectMake(0, 0, rect.size.height*2/3, rect.size.height*2/3);
    rectIcon.origin.x = rect.size.width - rect.size.height*5/6;
    rectIcon.origin.y = rect.size.height/6;
    UIImageView *actionImageView = [[UIImageView alloc] initWithImage:self.adActImg];
    actionImageView.backgroundColor = [UIColor clearColor];
    actionImageView.frame = rectIcon;
    
    CGFloat margin = 10;
    
    //init Text Label.
    CGRect rectText = CGRectMake(margin, margin, rect.size.width - rectIcon.size.width - 2*margin, rect.size.height - 2*margin);
    if ([secondText length] > 0)
    {
        rectMain = rectText;
        rectMain.size.height = (rectText.size.height-margin)*3/5;
        
        rectSecond = rectText;
        rectSecond.origin.y = rectText.origin.y + rectMain.size.height + margin;
        rectSecond.size.height = (rectText.size.height-margin)*2/5;
    }
    else
    {
        rectSecond = CGRectMake(0, 0, 0, 0);
        rectMain = rectText;
    }
    
    UILabel *mainLabel = [[UILabel alloc] initWithFrame:rectMain];
    mainLabel.text = mainText;
    mainLabel.backgroundColor = [UIColor clearColor];
    
    CGFloat mainLabelTextSize = rectMain.size.height*5/6;
    if ([secondText length] <= 0)
    {
        mainLabelTextSize = rectMain.size.height*2/5;
        UIFont *font = [UIFont fontWithName:@"Helvetica" size:mainLabelTextSize];
        CGSize textSize = [mainText sizeWithAttributes:@{NSFontAttributeName:font}];

        if (textSize.width > rectMain.size.width)
        {
            mainLabelTextSize = rectMain.size.height/3;
            mainLabel.numberOfLines = 2;
        }
    }
    
    UIView *ret = nil;
    mainLabel.font = [UIFont fontWithName:@"Helvetica" size:mainLabelTextSize];
    mainLabel.textColor = textColor;
    ret = [[UIView alloc] initWithFrame:rect];
    ret.backgroundColor = bgColor;
    [ret addSubview:actionImageView];
    
    [ret addSubview:mainLabel];
    
    if ([secondText length] > 0) {
        UILabel *secondLabel = [[UILabel alloc] initWithFrame:rectSecond];
        secondLabel.text = secondText;
        secondLabel.backgroundColor = [UIColor clearColor];
        secondLabel.font = [UIFont fontWithName:@"Helvetica" size:rectSecond.size.height*5/6];
        secondLabel.textColor = textColor;
        [ret addSubview:secondLabel];
    }
    return ret;
}

/**
 * 生成WebView
 * showType -- 展示方式，包括路径（REQUEST）， HTML代码（视频也按此处理）
 * webDelegate -- WEBVIEW的代理
 */
- (UIView *)makeWebViewFrame:(CGRect)frame showType:(int)showType webDelegate:(id)webDelegate
{
    NSURL * bundleUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    NSArray * supportFeatures = @[AdViewMraidSupportsSMS,
                                  AdViewMraidSupportsTel,
                                  AdViewMraidSupportsCalendar,
                                  AdViewMraidSupportsStorePicture,
                                  AdViewMraidSupportsInlineVideo];

    AdViewMraidWebView * mraidWebView = [[AdViewMraidWebView alloc] initWithFrame:frame
                                                                     withHtmlData:self.adBody
                                                                      withBaseURL:bundleUrl
                                                                supportedFeatures:supportFeatures
                                                                         delegate:webDelegate
                                                                  serviceDelegate:webDelegate
                                                                  webViewDelegate:webDelegate];
    
    if ([webDelegate isKindOfClass:[AdViewAdManager class]])
    {
        AdViewAdManager * adViewManager = (AdViewAdManager *)webDelegate;
        adViewManager.adViewWebView = mraidWebView;
    }
    self.adWebLoaded = NO;
    return mraidWebView;
}

/**
 * 修正图片展示类型
 * showType -- 展示类型
 * imgItem -- 图片数据
 */
- (int)fixImageShowType:(int)showType Item:(AdImageItem*)imgItem
{
    int showTypeVal = showType;
    if (AdViewAdSHowType_FullImage == showTypeVal)
    {
        int nImgLen = (int)[imgItem.imgUrl length];
        if (nImgLen > 4 && [[[imgItem.imgUrl substringFromIndex:nImgLen-4] lowercaseString] isEqualToString:@".gif"])
        {
            showTypeVal = AdViewAdSHowType_FullGif;
        }
    }
    else if (AdViewAdSHowType_FullGif == showTypeVal)
    {
        int nImgLen = (int)[imgItem.imgUrl length];
        if (nImgLen > 4 && ![[[imgItem.imgUrl substringFromIndex:nImgLen-4] lowercaseString] isEqualToString:@".gif"])
        {
            showTypeVal = AdViewAdSHowType_FullImage;
        }
    }
    self.adShowType = showTypeVal;
    return showTypeVal;
}

//构建SpreadView除了logo的部分
- (UIView *)makeAdSpreadViewWithSize:(CGSize)size withWebDelegate:(id)webDelegate {
    //根据可供绘制的尺寸对Model中的广告原尺寸进行缩放
    CGSize adSize = CGSizeMake(_adWidth, _adHeight);
    [AdViewExtTool scaleEnlargesTheSize:size toSize:&adSize];
    
    AdViewAdSHowType showTypeVal = self.adShowType;
    int nImgFrame = self.nCurFrame;
    self.nCurFrame ++;
    
    if ([self.adImageItems count] > 0)
        nImgFrame %= [self.adImageItems count];
    else
        nImgFrame = 0;
    
    AdImageItem *imgItem0 = [self getAdImageItem:nImgFrame];
    showTypeVal = [self fixImageShowType:showTypeVal Item:imgItem0];
    spreadImgViewRect = CGRectMake(0, 0, 0, 0);

    UIView * contentView;
    if (AdViewAdSHowType_WebView == showTypeVal || AdViewAdSHowType_WebView_Content == showTypeVal || AdViewAdSHowType_WebView_Video == showTypeVal) {
        // 根据变形模式调整尺寸
        if(self.deformationMode == AdSpreadDeformationModeAll) {
            self.adHeight = (self.spreadType == 1) ? (size.height - size.width / 4) : size.height;
            self.adWidth = size.width;
        }
        contentView = [self makeWebViewFrame:CGRectMake(0, 0, adSize.width, adSize.height)
                                    showType:showTypeVal
                                 webDelegate:webDelegate];
    } else if (AdViewAdSHowType_FullGif == showTypeVal && nil != imgItem0.imgData) {
        CGSize orgSize = imgItem0.img.size;
        kOpenAPIScaleCGSize(&size, &orgSize);
        
        // 根据变形模式调整尺寸
        if(self.deformationMode == AdSpreadDeformationModeImage || self.deformationMode == AdSpreadDeformationModeAll) {
            orgSize.height = (self.spreadType == 1) ? (size.height - size.width / 4): size.height;
            orgSize.width = size.width;
        }
        
        contentView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, orgSize.width, orgSize.height)];
        contentView.userInteractionEnabled = NO;
        NSString *string = @"<meta charset='utf-8'><style type='text/css'>* { padding: 0px; margin: 0px;}a:link { text-decoration: none;}</style><div  style='width: 100%; height: 100%;'><img src=\"%@\" width=\"%dpx\" height=\"%dpx\" ></div>";
        string = [NSString stringWithFormat:string,imgItem0.imgUrl,(int)size.width,(int)size.height];
        [(UIWebView*)contentView loadHTMLString:string baseURL:nil];
    } else if (AdViewAdSHowType_AdFillImageText == showTypeVal) {
        UIImage* image = imgItem0.img;
        
        CGSize ruleSize = CGSizeMake(300, 250);
        scaleEnlargesTheSize(&size, &ruleSize);
        
        contentView = [[ImageTextInstlView alloc] initWithIconImage:image
                                                              Title:self.adTitle
                                                           subTitle:self.adSubText
                                                            message:self.adText
                                                        actinonType:self.adActionType
                                                           delegate:self];
        contentView.layer.cornerRadius = 4;
        contentView.layer.masksToBounds = YES;
        contentView.layer.borderWidth = 1;
        contentView.contentMode = UIViewContentModeScaleAspectFit;
        contentView.layer.borderColor = [[UIColor colorWithRed:1 green:1 blue:1 alpha:0.1] CGColor];
        contentView.frame = CGRectMake(0, 0, ruleSize.width, ruleSize.height);
    }
    else if (AdViewAdSHowType_Video == showTypeVal)
    {
        //视频格式
        AdViewVideoViewController * controller = [[AdViewVideoViewController alloc] initWithDelegate:webDelegate adverType:AdViewSpread];
        controller.enableAutoClose = YES;
        controller.allowAlertView = YES;
        [controller loadVideoWithData:[self.adBody dataUsingEncoding:NSUTF8StringEncoding]];
        contentView = controller.view;
    }
    else
    {
        UIImage *img = [self makeAdSpreadViewImageWithSize:size];
        CGSize imgViewSize = img.size;
        scaleEnlargesTheSize(&size, &imgViewSize);
        
        contentView = [[UIImageView alloc] initWithImage:img];
        
        // 根据变形模式调整尺寸
        if(self.deformationMode == AdSpreadDeformationModeImage || self.deformationMode == AdSpreadDeformationModeAll)
        {
            imgViewSize.height = (self.spreadType == 1) ? (size.height - size.width / 4): size.height;
            imgViewSize.width = size.width;
            contentView.contentMode = UIViewContentModeScaleToFill;
        }
        contentView.frame = CGRectMake(0, 0, imgViewSize.width, imgViewSize.height);
    }
    UIView * ret = nil;
    ret = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    ret.backgroundColor = [UIColor clearColor];
    
//暂时根据vat字段进行布局处理
//    [self tiaozhengsize:ret imageSize:contentView.frame.size bgViewSize:size];
    
    contentView.center = CGPointMake(ret.center.x, contentView.center.y);
    [self conversionClickSizeWith:contentView.frame.size];
    
    // 从新矫正点击区域
    CGRect clickRect = self.clickSize;
    clickRect.origin.x += contentView.frame.origin.x;
    clickRect.origin.y += contentView.frame.origin.y;
    self.clickSize = clickRect;
    
    // 测试点击区域的红框
//    UIView *view=[[UIView  alloc]initWithFrame:self.clickSize];
//    view.backgroundColor=[UIColor  clearColor];//填充色是透明的
//    view.layer.borderColor=[UIColor  redColor].CGColor;//边框的颜色：红色
//    view.layer.borderWidth=0.5;//边框的尺寸：0.5.在2倍图下就是1像素
//    [ret addSubview:view];
    
    [ret addSubview:contentView];
    [ret sendSubviewToBack:contentView];

    [self addLogoLabelWithView:contentView adType:AdViewSpread];
    return ret;
}

//view:返回的背景视图  imageViewSize:广告的真实尺寸
- (void)tiaozhengsize:(UIView*)view imageSize:(CGSize)imgViewSize bgViewSize:(CGSize)size{
    CGRect textViewRect = CGRectMake(0, imgViewSize.height, imgViewSize.width, imgViewSize.width/4);
    UIView *textView = [self makeAdSpreadTextViewWithFrame:textViewRect];
    
    CGFloat textViewHgt = (textView == nil) ? 0 : imgViewSize.width / 4; //为0的情况没有写。
    if (self.spreadVat == AdSpreadShowTypeNone) self.spreadVat = AdSpreadShowTypeCenter;
    if (imgViewSize.height == size.height && imgViewSize.width <= size.width)
    {
        self.spreadVat = AdSpreadShowTypeImageCover;
        textViewRect.origin.y = imgViewSize.height - imgViewSize.width/4;
    }
    else if(imgViewSize.width == size.width && imgViewSize.height < size.height)
    {
        if (imgViewSize.height + textViewHgt >= size.height)
        {
            self.spreadVat = AdSpreadShowTypeLogoOrTextCover;
            textViewRect.origin.y = size.height - textViewHgt;
        }
    }
    textView.frame = textViewRect;
    CGRect finalRect = CGRectMake(0, 0, size.width, imgViewSize.height + textViewHgt);
    
    switch (_spreadVat) {
        case AdSpreadShowTypeTop:{
            finalRect = CGRectMake(0, 0, size.width, imgViewSize.height + textViewHgt);
        }
            break;
        case AdSpreadShowTypeCenter:{
            finalRect = CGRectMake(0, (size.height - imgViewSize.height - textViewHgt)/2, size.width, imgViewSize.height + textViewHgt);
        }
            break;
        case AdSpreadShowTypeBottom:{
            finalRect = CGRectMake(0, (size.height - imgViewSize.height - textViewHgt), size.width, imgViewSize.height + textViewHgt);
        }
            break;
        case AdSpreadShowTypeAllCenter:{
            finalRect = CGRectMake(0, (size.height - imgViewSize.height - textViewHgt)/2, size.width, imgViewSize.height + textViewHgt);
        }break;
        case AdSpreadShowTypeImageCover:{
            finalRect = CGRectMake((size.width-imgViewSize.width)/2, (size.height - imgViewSize.height)/2, imgViewSize.width, imgViewSize.height);
        }break;
        case AdSpreadShowTypeLogoOrTextCover:{
            finalRect = CGRectMake(0, 0, imgViewSize.width, size.height);
        }break;
        default:
            break;
    }
    view.frame = finalRect;

    self.spreadImgViewRect = CGRectMake(finalRect.origin.x, finalRect.origin.y, imgViewSize.width, imgViewSize.height);
    
    if (textView) {
        textViewRect.origin.y += finalRect.origin.y;
        textViewRect.origin.x += finalRect.origin.x;
        self.spreadTextViewSize = textViewRect;
        [view addSubview:textView];
    }else
        self.spreadTextViewSize = CGRectMake(0, 0, 0, 0);
}

/*创建插屏返回的UIView*///12 -4 修改为此方法中不做center处理而是在返回uiview后再给赋值
- (UIView*)makeAdInstlViewWithSize:(CGSize)size
                       withBgColor:(UIColor*)bgColor
                     withTextColor:(UIColor*)textColor
                   withWebDelegate:(id)webDelegate
{
    UIView *ret = nil;
	AdViewAdSHowType showTypeVal = self.adShowType;
    self.adverType = AdViewInterstitial;

    int nImgFrame = self.nCurFrame;
    self.nCurFrame ++;
    
    if ([self.adImageItems count] > 0)
        nImgFrame %= [self.adImageItems count];
    else
        nImgFrame = 0;
    AdImageItem *imgItem0 = [self getAdImageItem:nImgFrame];
    //返回数据表示纯图片(此else就是为了纠一下错误)
    showTypeVal = [self fixImageShowType:showTypeVal Item:imgItem0];
    
	if (AdViewAdSHowType_WebView == showTypeVal ||
        AdViewAdSHowType_WebView_Content == showTypeVal ||
        AdViewAdSHowType_WebView_Video == showTypeVal)
    {
        //AdViewMraidWebView
        ret = [self makeWebViewFrame:CGRectMake(0, 0, self.adWidth, self.adHeight)
                            showType:showTypeVal
                         webDelegate:webDelegate];
        self.adInstlImageSize = CGSizeMake(self.adWidth, self.adHeight);
	}
    else if (AdViewAdSHowType_FullGif == showTypeVal && nil != imgItem0.imgData)
    {
        UIImage* image = imgItem0.img;
        self.adInstlImageSize = image.size; //gif我也记录一下它到大小
		CGSize orgSize = [self withTheProportion:self.adInstlImageSize withSize:size];
        //把计算好的尺寸复制给size
		kOpenAPIScaleCGSize(&size, &orgSize);
        
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        webView.userInteractionEnabled = NO;
        NSString *string = @"<meta charset='utf-8'><style type='text/css'>* { padding: 0px; margin: 0px;}a:link { text-decoration: none;}</style><div  style='width: 100%; height: 100%;'><img src=\"%@\" width=\"%dpx\" height=\"%dpx\" ></div>";
        string = [NSString stringWithFormat:string,imgItem0.imgUrl,(int)size.width,(int)size.height];
        [webView loadHTMLString:string baseURL:nil];
        ret = webView;
        ret.backgroundColor = [UIColor clearColor];
        ret.layer.cornerRadius = 4;
        ret.layer.masksToBounds = YES;
        ret.layer.borderWidth = 1;
        //填满整个view
        ret.contentMode = UIViewContentModeScaleAspectFit;
        ret.layer.borderColor = [[UIColor colorWithRed:1 green:1 blue:1 alpha:0.1] CGColor];
        
		ret.frame = CGRectMake(0, 0, size.width, size.height);
        self.clickSize = ret.frame;
	}
    else if (AdViewAdSHowType_AdFillImageText == showTypeVal) /*图文*/
    {
        UIImage* image = imgItem0.img;
        
        CGSize ruleSize = CGSizeMake(300, 250);
        scaleEnlargesTheSize(&size, &ruleSize);
        self.adInstlImageSize = ruleSize;

        ret = [[ImageTextInstlView alloc] initWithIconImage:image
                                                      Title:self.adTitle
                                                   subTitle:self.adSubText
                                                    message:self.adText
                                                actinonType:self.adActionType
                                                   delegate:self];
        ret.layer.cornerRadius = 4;
        ret.layer.masksToBounds = YES;
        ret.layer.borderWidth = 1;
        //填满整个view
        ret.contentMode = UIViewContentModeScaleAspectFit;
        ret.layer.borderColor = [[UIColor colorWithRed:1 green:1 blue:1 alpha:0.1] CGColor];
        ret.frame = CGRectMake(0, 0, self.adInstlImageSize.width, self.adInstlImageSize.height);
        self.clickSize = CGRectMake(0, ruleSize.height*0.68, ruleSize.width, ruleSize.height*0.32);
    }
    else if (AdViewAdSHowType_Video == showTypeVal)
    {
        //视频格式
        AdViewVideoViewController *controller = [[AdViewVideoViewController alloc] initWithDelegate:webDelegate adverType:_adverType];
        controller.enableAutoClose = NO;
        controller.allowAlertView = YES;
        [controller loadVideoWithData:[self.adBody dataUsingEncoding:NSUTF8StringEncoding]];
        ret = controller.view;
        self.adInstlImageSize = controller.view.frame.size;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        [webDelegate performSelector:@selector(setVideoController:) withObject:controller];
#pragma clang diagnostic pop
    }
    else /*这种情况是只是一张图片*/
    {
		UIImage* image = imgItem0.img;
        
        CGSize toSize = image.size;
        self.adInstlImageSize = image.size;
        
		toSize = [self withTheProportion:toSize withSize:size];
        
        ret = [[UIImageView alloc]initWithImage:image];
        
        ret.backgroundColor = [UIColor clearColor];
        ret.layer.cornerRadius = 4;
        ret.layer.masksToBounds = YES;
        ret.layer.borderWidth = 1;
        
        //填满整个view
        ret.contentMode = UIViewContentModeScaleAspectFit;
        ret.layer.borderColor = [[UIColor colorWithRed:1 green:1 blue:1 alpha:0.1] CGColor];
        ret.frame = CGRectMake(0, 0, toSize.width, toSize.height);
        self.clickSize = ret.frame;
    }
    
    [self addLogoLabelWithView:ret adType:AdViewInterstitial];
    
    return ret;
}

#pragma mark - 创建非视频Banner
- (UIView *)makeBannerWithSize:(CGSize)size
                   withBgColor:(UIColor *)bgColor
                 withTextColor:(UIColor *)textColor
               withWebDelegate:(id)webDelegate
{
    self.adverType = AdViewBanner;
    
    UIColor *BgColor = nil;
    UIColor *TextColor = nil;
    if (![self.adBgColor isEqualToString:@""] && self.adBgColor != nil)
        BgColor = [self hexStringToColor:self.adBgColor];
    else
        BgColor = bgColor;
    if (![self.adTextColor isEqualToString:@""] && self.adTextColor != nil)
        TextColor = [self hexStringToColor:self.adTextColor];
    else
        TextColor = textColor;
    
	UIView * ret = nil;
	AdViewAdSHowType showTypeVal = self.adShowType;
    
    int nImgFrame = self.nCurFrame;
    self.nCurFrame ++;
    
    if ([self.adImageItems count] > 0)
        nImgFrame %= [self.adImageItems count];
    else
        nImgFrame = 0;
    AdImageItem *imgItem0 = [self getAdImageItem:nImgFrame];
    showTypeVal = [self fixImageShowType:showTypeVal Item:imgItem0];
    
    
	if (AdViewAdSHowType_WebView == showTypeVal ||
        AdViewAdSHowType_WebView_Content == showTypeVal ||
        AdViewAdSHowType_WebView_Video == showTypeVal)
    {
        self.adWidth = size.width;
        self.adHeight = size.height;
        ret = [self makeWebViewFrame:CGRectMake(0, 0, size.width, size.height)  //mraid webview
                            showType:showTypeVal
                         webDelegate:webDelegate];
	}
    else if (AdViewAdSHowType_FullGif == showTypeVal && nil != imgItem0.imgData)
    {
        CGSize orgSize = imgItem0.img.size;
		kOpenAPIScaleCGSize(&size, &orgSize);
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        webView.userInteractionEnabled = NO;
        NSString *string = @"<meta charset='utf-8'><style type='text/css'>* { padding: 0px; margin: 0px;}a:link { text-decoration: none;}</style><div  style='width: 100%; height: 100%;'><img src=\"%@\" width=\"%dpx\" height=\"%dpx\" ></div>";
        string = [NSString stringWithFormat:string,imgItem0.imgUrl,(int)size.width,(int)size.height];
        [webView loadHTMLString:string baseURL:nil];
        ret = webView;
		ret.frame = CGRectMake(0, 0, size.width, size.height);
		ret.center = CGPointMake(size.width/2, size.height/2);
	}
    else if (AdViewAdSHowType_AdFillImageText == showTypeVal)
    {
        if(size.width < size.height * 3)
        {
            self.adShowType = AdViewAdSHowType_ImageText;
            UIImage* image = [self renderWithSize:size withBgColor: BgColor withTextColor: TextColor];
            
            int density = [AdViewExtTool getDensity];
            CGSize toSize = image.size;
            toSize.width /= density;
            toSize.height /= density;
            
            ret = [[UIImageView alloc] initWithImage:image];
            ret.frame = CGRectMake(0, 0, toSize.width, toSize.height);
        }
        else
        {
            UIView *view = [self MakeAdFillViewWithSize:size withBgColor:BgColor withTextColor:TextColor];
            ret = view;
            ret.frame = CGRectMake(0, 0, size.width, size.height);
        }
    }
    else
    {
#if  0
        UIView *view = [self makeAdFillViewWithSize:size withBgColor:BgColor withTextColor:TextColor];
        ret = [view retain];
        ret.frame = CGRectMake(0, 0, size.width, size.height);
#else
        UIImage* image = [self renderWithSize:size withBgColor: BgColor withTextColor: TextColor];

        int density = [AdViewExtTool getDensity];
        CGSize toSize = image.size;
        toSize.width /= density;
        toSize.height /= density;

        ret = [[UIImageView alloc] initWithImage:image];
        ret.frame = CGRectMake(0, 0, toSize.width, toSize.height);
#endif
	}
    [self addLogoLabelWithView:ret adType:AdViewBanner];
	return ret;
}

- (UIColor *)hexStringToColor:(NSString *) stringToConvert
{
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

- (AdImageItem *)getAdImageItem:(int)index                         //get AdImage.
{
    if (nil == self.adImageItems) return nil;
    
    if (index < 0 || [self.adImageItems count] <= index) return nil;
    
    AdImageItem *item = [self.adImageItems objectAtIndex:index];
    return item;
}

- (UIImage *)getAdImage:(int)index                         //get AdImage.
{
    return [[self getAdImageItem:index] img];
}

- (void)ensureImageItemsCount:(int)count {
    while ([self.adImageItems count] < count) {
        AdImageItem *item = [[AdImageItem alloc] init];
        [self.adImageItems addObject:item];
    }
}

// -1  --- Last
//set or append url info.
- (void)setAdImage:(int)index Url:(NSString*)str Append:(BOOL)bAppend  {
    if (index < 0 && index != LAST_IMAGEITEM) return;
    
    if (nil == self.adImageItems) {
        self.adImageItems = [NSMutableArray arrayWithCapacity:2];
    }
    [self ensureImageItemsCount:1];
    if (index == LAST_IMAGEITEM) index = (int)([self.adImageItems count] - 1);
    
    [self ensureImageItemsCount:index + 1];
    AdImageItem *item = [self getAdImageItem:index];
    if (nil == item) return;
    
    if (bAppend && item.imgUrl)
        item.imgUrl = [item.imgUrl stringByAppendingString:str];
    else item.imgUrl = str;
}

- (BOOL)needFetchImage
{
    if ([self.adActImgURL length] > 0 || [self.adBgImgURL length] > 0 || [self.adIconUrlStr length] > 0 || [self.adLogoURLStr length] > 0)
    {
        return YES;
    }
    
    for (AdImageItem *item in self.adImageItems)
    {
        if ([item.imgUrl length] > 0)
        {
            return YES;
        }
    }
    return NO;
}

//use only for full image. one image one frame(even gif).
- (int)totalFrame {
    int nRet = (int)[self.adImageItems count];
    if (nRet < 2) nRet = 2;
    return nRet;
}

- (int)currentFrame {
    return self.nCurFrame;
}

- (BOOL)needAnimDisplay {
    if ([self.adText length] > 0 && [self.adSubText length] > 0) {
        return YES;
    }
    return NO;
}

#pragma makr - getter methods
- (AdSpreadDeformationMode)deformationMode {
    if (deformationMode >= AdSpreadDeformationModeMax) {
        deformationMode = AdSpreadDeformationModeNone;
    }
    return deformationMode;
}


-(void) dealloc
{
    AdViewLogDebug(@"Dealloc AdViewContent");
    self.adId = nil;
    self.adInfo = nil;
    self.adText = nil;
    self.adSubText = nil;
	self.adBody = nil;			//web content.
    self.adBaseUrlStr = nil;
    self.adLinkType = nil;
    self.adLinkURL = nil;
    
    self.adImageItems = nil;       //array of AdImageItem
    
    self.adAppId = nil;
	self.adCopyrightStr = nil;
    
    self.adBgImgURL = nil;
    self.adBgImg = nil;
    
    self.adActImgURL = nil;
    self.adActImg = nil;
	self.adWebURL = nil;
    self.hostURL = nil;
	self.adWebRequest = nil;
    
    self.adBgColor = nil;
    self.adTextColor = nil;
    
    self.otherShowURL = nil;
    self.monSstring = nil;
    self.monCstring = nil;

    exchangeArr = nil;

    self.extendShowUrl = nil;
    self.extendClickUrl = nil;
}

@end

@implementation ImageTextInstlView
@synthesize titleView;
@synthesize icon;
@synthesize mainTitle;
@synthesize subTitle;
@synthesize mesLabel;
@synthesize downLoadBtn;
@synthesize toSize;

- (instancetype)initWithIconImage:(UIImage *)iconImage
                            Title:(NSString *)titleText
                         subTitle:(NSString *)subTitleText
                          message:(NSString *)message
                      actinonType:(AdViewAdActionType)actionType
                         delegate:(id)delegate
{
    if (self = [super init])
    {
        self.userInteractionEnabled = NO;
        
        self.backgroundColor = [self hexStringToColor:@"#ece8e5"];

//        self.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"title_back.png"]]; //顶部背景
        
        self.titleView = [[UIImageView alloc] initWithImage:[UIImage imagesNamedFromCustomBundle:@"title_back.png"]]; //顶部背景
        
        [self addSubview:self.titleView];
        
        self.icon = [[UIImageView alloc] initWithImage:iconImage]; //图标
        self.icon.layer.cornerRadius = 2.0;
        self.icon.layer.masksToBounds = YES;
        [self addSubview:self.icon];
        
        self.mainTitle = [[UILabel alloc] init];
        [self.mainTitle setText:titleText];
        [self.mainTitle setTextColor:[self hexStringToColor:@"#ffffff"]];
        [self addSubview:self.mainTitle];
        self.mainTitle.backgroundColor = [UIColor clearColor];
        
        if (subTitleText && [subTitleText length] > 0) {
            self.subTitle = [[UILabel alloc] init];
            [self.subTitle setText:subTitleText];
            [self.subTitle setTextColor:[self hexStringToColor:@"#ffffff"]];
            [self addSubview:self.subTitle];
        }
        
        NSString *downLoadStr = @"免费下载";
        if (actionType == AdViewAdActionType_Web) {
            downLoadStr = @"查看详情";
        }
        
        self.downLoadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        //self.downLoadBtn.backgroundColor = [UIColor clearColor];
        [self.downLoadBtn setTitle:downLoadStr forState:UIControlStateNormal];
        [self.downLoadBtn setTitleColor:[self hexStringToColor:@"#ffffff"] forState:UIControlStateNormal];
        [self.downLoadBtn setBackgroundColor:[self hexStringToColor:@"#2c91a6"]];
        [self.downLoadBtn.layer setCornerRadius:2];
        [self addSubview:self.downLoadBtn];
        
        self.mesLabel = [[UILabel alloc] init];
        self.mesLabel.textAlignment = NSTextAlignmentCenter;
        [self.mesLabel setTextColor:[self hexStringToColor:@"#3e3d3d"]];
        [self addSubview:self.mesLabel];
        self.mesLabel.numberOfLines = 0;
        self.mesLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.mesLabel.text = message;
        self.mesLabel.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    float fontSizeA = self.frame.size.height / 500 * 36;
    float fontSizeB = self.frame.size.height / 500 * 28;
    [self.mainTitle setFont:[UIFont systemFontOfSize:fontSizeA]];
    [self.subTitle setFont:[UIFont systemFontOfSize:fontSizeB]];
    [self.mesLabel setFont:[UIFont systemFontOfSize:fontSizeB]];
    [self.downLoadBtn.titleLabel setFont:[UIFont systemFontOfSize:fontSizeB]];
//    CGRect re = CGRectMake(0, self.frame.size.height * 0.76, self.frame.size.width, self.frame.size.height * 0.24);
//    CGContextRef ctx = UIGraphicsGetCurrentContext();
//    UIImage *image = [UIImage imageNamed:@"title_back.png"];
//    CGContextDrawImage(ctx, re, image.CGImage);
}
#define IMAGE_TEXT_TAP 8
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.toSize = self.frame.size;
    
    self.titleView.frame = CGRectMake(0, 0, toSize.width, toSize.height / 500.0 * 160.0);
    
    self.icon.frame = CGRectMake(titleView.frame.size.width * 0.0583,
                                 (titleView.frame.size.height - titleView.frame.size.height * 0.625) / 2,
                                 titleView.frame.size.height * 0.625,
                                 titleView.frame.size.height * 0.625);

    if (self.subTitle) {
        self.mainTitle.frame = CGRectMake(icon.frame.origin.x + icon.frame.size.width + IMAGE_TEXT_TAP,
                                          icon.frame.origin.y,
                                          toSize.width - icon.frame.origin.x - icon.frame.size.width,
                                          icon.frame.size.height / 2);
        self.subTitle.frame = CGRectMake(mainTitle.frame.origin.x,
                                         mainTitle.frame.origin.y + mainTitle.frame.size.height,
                                         mainTitle.frame.size.width,
                                         mainTitle.frame.size.height);

    }else
        self.mainTitle.frame = CGRectMake(icon.frame.origin.x + icon.frame.size.width + IMAGE_TEXT_TAP,
                                          icon.frame.origin.y + icon.frame.size.height / 4,
                                          toSize.width - icon.frame.origin.x - icon.frame.size.width,
                                          icon.frame.size.height / 2);
    
    self.downLoadBtn.frame = CGRectMake((toSize.width - toSize.width / 600 * 230) / 2,
                                        toSize.height / 500 * 410,
                                        toSize.width / 600 * 230,
                                        toSize.height / 500 * 60);
    self.mesLabel.frame = CGRectMake(icon.frame.origin.x,
                                     titleView.frame.size.height + titleView.frame.origin.y,
                                     toSize.width - icon.frame.origin.x * 2,
                                     toSize.height -
                                     titleView.frame.size.height -
                                     titleView.frame.origin.y -
                                     toSize.height +
                                     downLoadBtn.frame.origin.y);
}

-(UIColor *) hexStringToColor: (NSString *) stringToConvert
{
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

- (void)dealloc
{
    self.titleView = nil;
    self.icon = nil;
    self.mainTitle = nil;
    self.subTitle = nil;
    self.mesLabel = nil;
    self.downLoadBtn = nil;
}

@end
