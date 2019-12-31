//
//  AdViewContent.h
//  AdViewHello
//
//  Created by AdView on 13-1-23.
//  广告Model 用于组建出一个广告

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocationManager.h>
#import "AdViewDefines.h"

typedef enum {
	GradientColorType_None = -1,
	GradientColorType_Fix = 0,
	GradientColorType_Random,
}GradientColorType;

//用于存放请求参数的model
@interface AdViewAdCondition : NSObject
@property (nonatomic, strong) NSString * appId;
@property (nonatomic, strong) NSString * appPwd;
@property (nonatomic, strong) NSString * positionId;
@property (nonatomic, assign) CGSize  adSize;
@property (nonatomic, assign) BOOL adTest;
@property (nonatomic, assign) BOOL hasLocationVal;
@property (nonatomic, assign) CLLocationDegrees longitude;
@property (nonatomic, assign) CLLocationDegrees latitude;
@property (nonatomic, assign) CLLocationAccuracy accuracy;
@property (nonatomic, assign) AdvertType adverType;
@property (nonatomic, assign) BOOL bUseHtml5;
@property (nonatomic, assign) int adCount;

@property (nonatomic, assign) BOOL gdprApplicability;               //用户是否遵循GDPR
@property (nonatomic, copy)   NSString * consentString;             //GDRP许可字符串

@property (nonatomic, assign) BOOL CMPPresent;
@property (nonatomic, copy)   NSString * parsedPurposeConsents;
@property (nonatomic, copy)   NSString * parsedVendorConsents;

@property (nonatomic, copy)   NSString * CCPAString;                //加州CCPA隐私策略
@end

@interface AdImageItem : NSObject
{
    NSString *imgUrl;
    NSData   *imgData;
    UIImage  *img;
}
@property (strong) NSString *imgUrl;
@property (strong) NSData   *imgData;
@property (strong) UIImage  *img;
@end

#define LAST_IMAGEITEM      -1

@interface AdViewContent : NSObject
{
	AdViewAdPlatType adPlatType;		//adview app, or suizong.
	BOOL adWebLoaded;
    
    NSMutableDictionary *colorBG;
    NSString* adId;
    NSString* adInfo;
    NSString* adText;
    NSString* adSubText;
    NSString* adTitle;          //插屏图文的主标题
	NSString* adBody;			//web content.
    NSString* adBaseUrlStr;
    NSString* adLinkType;
    NSString* adLinkURL;
    
    NSMutableArray *adImageItems;       //array of AdImageItem
    
    NSString* errorReportQuery;
    
    NSString* adAppId;
	NSString* adCopyrightStr;
    
    NSString* adBgImgURL;
    UIImage*  adBgImg;
    
    NSString* adActImgURL;
    UIImage*  adActImg;
	    
	CGSize      adInstlImageSize;       /*记录图片大小*/
    
	AdViewAdActionType			adActionType;
	AdViewContentErrorType		adParseError;
	
	NSString*     adWebURL;
    NSString*     hostURL;          /*记录host网址*/
	NSURLRequest *adWebRequest;
    
    NSString *adBgColor;
    NSString *adTextColor;
    
    NSString *clickArea;
    NSString *otherShowURL;
    
    int     src;
    int     nCurFrame;
    int     severAgent;
    int     severAgentAdvertiser;
    NSString *monSstring;           //展示代发网址
    NSString *monCstring;           //点击代发网址
    
    CGRect clickSize; //开屏可点击区域
    CGRect spreadTextViewSize; //开屏文字部分区域（可点击）
    int forceTime; //强制展示时间
    int relayTime; //延迟展示时间
    NSTimeInterval cacheTime; //图片缓存时间戳
    int spreadType; //开屏类型（目前暂指是否含有logo） 1 -- 有logo；2 -- 没有logo
    
    NSDictionary *extendShowUrl;    // 扩展需要代发的展示汇报
    NSArray *extendClickUrl;        // 扩展需要代发的点击汇报
    AdSpreadShowType spreadVat;     //开屏摆放方式
    int maxClickNum;                //单条广告点击次数上限
    
    NSString *clickPosition;        //点击相对位置
    CGRect spreadImgViewRect;       //开屏图片&图文 的 frame
    
    NSDictionary *nativeDict;//原生广告数组
}
@property (nonatomic, assign) AdViewAdPlatType adPlatType;     //广告API请求平台类型
@property (nonatomic, assign) BOOL		adWebLoaded;

//@property (nonatomic) ColorSchemes colorScheme;
@property (nonatomic, strong) NSMutableDictionary *colorBG;

@property (nonatomic, strong) NSString* adId;
@property (nonatomic, strong) NSString* adInfo;
@property (nonatomic, strong) NSString* adText;
@property (nonatomic, strong) NSString* adSubText;
@property (nonatomic, strong) NSString* adTitle;

@property (nonatomic, strong) NSString* adBody;
@property (nonatomic, strong) NSString* adBaseUrlStr;

@property (nonatomic, assign) AdViewAdSHowType adShowType;
@property (nonatomic, strong) NSString* adLinkType;
@property (nonatomic, strong) NSString* adLinkURL;      //if not nil, if webview req same, think to openLink
@property (nonatomic, strong) NSString* fallBack;       //点击跳转链接替换字段（原生专用）防止scheme被拒问题
@property (nonatomic, strong) NSString* deepLink;       //深链接

@property (strong) NSMutableArray *adImageItems;

@property (nonatomic, strong) NSString* errorReportQuery;

@property (nonatomic, strong) NSString* adAppId;
@property (nonatomic, strong) NSString* adCopyrightStr;

@property (nonatomic, strong) NSString* adBgImgURL;
@property (nonatomic, strong) UIImage*  adBgImg;

@property (nonatomic, strong) NSString* adLogoURLStr;   //广告来源标示图标url
@property (nonatomic, strong) UIImage* adLogoImg;

@property (nonatomic, strong) NSString* adIconUrlStr;   //广告文字标示图标url
@property (nonatomic, strong) UIImage* adIconImg;

@property (nonatomic, strong) NSString* adActImgURL;
@property (nonatomic, strong) UIImage* adActImg;

@property (nonatomic, assign) CGSize    adInstlImageSize;//图片大小

@property (nonatomic, assign) AdViewAdActionType			adActionType;

@property (nonatomic, assign) AdViewContentErrorType	adParseError;			//like NoFill error.

@property (nonatomic, strong) NSString* adWebURL;       //think as the ad url.(will show in webview), if not same, think as openLink
@property (nonatomic, strong) NSString* hostURL; //记录host网址

@property (nonatomic, strong) NSURLRequest *adWebRequest;

@property (nonatomic, assign) GradientColorType adRenderBgColorType;

@property (nonatomic, strong) NSString *adBgColor;
@property (nonatomic, strong) NSString *adTextColor;

@property (nonatomic, assign) CGRect spreadImgViewRect;
@property (nonatomic, strong) NSString *otherShowURL;

@property (assign, nonatomic) int  src;
@property (assign) int nCurFrame;       //current frame.
@property (assign, nonatomic) int severAgent;
@property (assign, nonatomic) int severAgentAdvertiser;

@property (nonatomic, strong) NSString *monSstring; //展示代发网址
@property (nonatomic, strong) NSString *monCstring; //点击代发网址

@property (nonatomic, assign) CGFloat adWidth;      //广告尺寸
@property (nonatomic, assign) CGFloat adHeight;

@property (nonatomic, assign) CGRect clickSize;
@property (nonatomic, assign) CGRect spreadTextViewSize;
@property (nonatomic, assign) int forceTime;                //开屏规定时间，单位秒
@property (nonatomic, assign) int relayTime;                //开屏延长时间，单位秒
@property (nonatomic, assign) NSTimeInterval cacheTime;
@property (nonatomic, assign) int spreadType;               //1.有LOGO 2.无LOGO
@property (nonatomic, assign) AdSpreadShowType spreadVat;
@property (nonatomic, assign) AdSpreadDeformationMode deformationMode;
@property (nonatomic, assign) AdvertType adverType;

@property (nonatomic, strong) NSDictionary *extendShowUrl;  //上报展示URL.里面可能有我们 + 上游 x n
@property (nonatomic, strong) NSArray *extendClickUrl;
@property (nonatomic, assign) int maxClickNum;
@property (nonatomic, copy) NSDictionary *miniProgramDict;

@property (nonatomic, strong) NSDictionary *nativeDict;     //原生广告数组

- (void)renderTextInContext:(CGContextRef)context
                       Rect:(CGRect)rect
                  TextColor:(UIColor*)textColor;

- (UIImage*)renderWithSize:(CGSize)size
               withBgColor:(UIColor*)bgColor
             withTextColor:(UIColor*)textColor;

- (instancetype)initWithAppId:(NSString *)appId;

/**
 创建Banner

 @param size 尺寸
 @param bgColor 背景颜色
 @param textColor 字体颜色
 @param webDelegate delegate
 @return 构造好的BannerView
 */
-(UIView*)makeBannerWithSize:(CGSize)size withBgColor:(UIColor*)bgColor withTextColor:(UIColor*)textColor withWebDelegate:(id)webDelegate;

/*
 * 创建插屏  -返回 UIView
 */
-(UIView*)makeAdInstlViewWithSize:(CGSize)size withBgColor:(UIColor*)bgColor withTextColor:(UIColor*)textColor withWebDelegate:(id)webDelegate;

/*
 * 创建开屏
 */
- (UIView *)makeAdSpreadViewWithSize:(CGSize)size withWebDelegate:(id)webDelegate;

/*
 * 换算比例 每次旋转换算一下得出需要展示广告到尺寸
 */
- (CGSize)withTheProportion:(CGSize)imagesize withSize:(CGSize)showSize;

- (void)addLogoLabelWithView:(UIView*)ret adType:(AdvertType)adType;

- (BOOL)needFetchImage;
- (AdImageItem *)getAdImageItem:(int)index;
- (UIImage *)getAdImage:(int)index;                      //get AdImage.
- (void)setAdImage:(int)index Url:(NSString*)str Append:(BOOL)bAppend;  //set or append url info.

//use only for full image. one image one frame(even gif).
- (int)totalFrame;
- (int)currentFrame;

//图文广告需不需要动画
- (BOOL)needAnimDisplay;

//图文广告动画切换
- (void)animExchangeAd:(UIView*)view;

@end


@protocol ImageTextInstlViewClickDelegate <NSObject>

- (void)downLoadBtnClick:(id)sender;

@end

@interface ImageTextInstlView : UIView
@property (nonatomic, strong) UIView * titleView;   //蓝色标题背景
@property (nonatomic, strong) UIImageView * icon;   //图标
@property (nonatomic, strong) UILabel * mainTitle;  //主标题
@property (nonatomic, strong) UILabel * subTitle;   //副标题
@property (nonatomic, strong) UILabel * mesLabel;   //广告语
@property (nonatomic, strong) UIButton* downLoadBtn;//下载按钮
@property (nonatomic, assign) CGSize toSize;

- (instancetype)initWithIconImage:(UIImage *)iconImage
                            Title:(NSString *)title
                         subTitle:(NSString *)subTitle
                          message:(NSString *)message
                       actinonType:(AdViewAdActionType)actionType
                         delegate:(id)delegate;
@end
