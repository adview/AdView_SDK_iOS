#import <CoreLocation/CLLocationManager.h>
@class AdViewView;
extern NSString *const AdView_IABConsent_CMPPresent;
extern NSString *const AdView_IABConsent_SubjectToGDPR;
extern NSString *const AdView_IABConsent_ConsentString;
extern NSString *const AdView_IABConsent_ParsedPurposeConsents;
extern NSString *const AdView_IABConsent_ParsedVendorConsents;

@protocol AdViewGDPRProcotol <NSObject>
@optional
/**
 Set to YES if a CMP implementing this specification is present in the application.
 Ideally set by the Publisher as soon as possible but can also be set by the CMP alternatively.

 @return If implementing this specification
 */
- (BOOL)CMPPresent;

/**
 GDPR Applicability
 
 @return allow GDPR
 */
- (BOOL)subjectToGDPR;

/**
 GDPR ConsentString
 
 @return the ConsentString
 */
- (NSString *)userConsentString;

/**
 String (of "0" and "1") where the character in position N indicates the consent status to purpose ID N as defined in the Global Vendor List.
 String of consent given to enable simple checking. First character from the left being Purpose 1, ...

 @return @"0" or @"1"
 */
- (NSString *)parsedPurposeConsents;

/**
 String (of "0" and "1") where the character in position N indicates the consent status to vendor ID N as defined in the Global Vendor List.
 String of consent given to enable simple checking. First character from the left being Vendor 1, ...

 @return @"0" or @"1"
 */
- (NSString *)parsedVendorConsents;
@end

@protocol AdViewViewDelegate <AdViewGDPRProcotol>
@required
/**
 The application id, you can register here: http://www.adview.com/web/overseas

 @return appid
 */
- (NSString *)appId;

/**
 Show Ad in this viewController or viewController.view

 @return a present viewController
 */
- (UIViewController *)viewControllerForShowModal;

@optional

/**
 * Ad request success
 */
- (void)didReceivedAd:(AdViewView *)adView;

/**
 * Ad request faild
 */
- (void)didFailToReceiveAd:(AdViewView *)adView Error:(NSError*)error;

/**
 Ad will show

 @param adView The Adview
 */
- (void)adViewWillPresentScreen:(AdViewView *)adView;

/**
 Ad dismissed

 @param adView The Adview
 */
- (void)adViewDidDismissScreen:(AdViewView *)adView;


/**
 Ad did finished show, you can close Ad or request new Ad again

 @param adview The Adview
 */
- (void)adViewDidFinishShow:(AdViewView *)adview;

/**
 Useless
 
 @return NSString
 */
- (NSString *)appPwd;

- (UIColor  *)adTextColor;
- (UIColor  *)adBackgroundColor;
- (NSString *)adBackgroundImgName;
- (NSString *)logoImgName;
- (BOOL)usingHTML5;

/**
 Open the AppStore inside your application, default is YES
 
 @return BOOL
 */
- (BOOL)usingSKStoreProductViewController;

/**
 <=0 - none, <15 - 15, unit: seconds

 @return The interval
 */
- (int)autoRefreshInterval;

/**
 -1  - none, 0 - fix, 1 - random

 @return GradientColorType
 */
- (int)gradientBgType;

- (BOOL)testMode;
- (BOOL)usingCache;
- (BOOL)logMode;
- (int)configVersion;
- (CLLocation*)getLocation;

/**
 move the center of a ad. Etc: return 20.f means move the ad's center down 20px

 @return float
 */
- (float)moveCentr;

/**
 select and uniform scale, should between 0.8 - 1.2

 @return float
 */
- (float)scaleProportion;

/**
 * wkwebview需要提前添加到视图
 */
- (void)needPreAddView:(AdViewView *)adview;

/**
 Ad request host.
 
 @return The host
 */
- (NSString *)AdViewViewHost;
@end
