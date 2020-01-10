//
//  AdViewMraidView.h
//  AdViewHello
//
//  Created by AdView on 15-1-20.
//
//  承载mraidWebView变形的Controller

#import <UIKit/UIKit.h>

@class AdViewMraidModalViewController;
@class AdViewMraidOrientation;

@protocol AdViewMraidModalViewControllerDelegate <NSObject>
- (void)mraidModalViewControllerDidRotate:(AdViewMraidModalViewController *)modalViewController;
@end

@interface AdViewMraidModalViewController : UIViewController
@property (nonatomic, unsafe_unretained) id<AdViewMraidModalViewControllerDelegate> delegate;
- (id)initWithOrientationProperties:(AdViewMraidOrientation *)orientationProperties;
- (void)forceToOrientation:(AdViewMraidOrientation *)orientationProperties;
@end
