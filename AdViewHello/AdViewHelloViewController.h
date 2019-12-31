//
//  AdViewHelloViewController.h
//  AdViewHello
//
//  Created by AdView on 10-11-24.
//  Copyright 2010 AdView. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AdViewHelloViewController : UIViewController
@property (strong, nonatomic) NSMutableDictionary *setDict;
- (void)setUILogInfo:(NSString*)str;
- (void)setUIStatusInfo:(NSString*)str;
- (IBAction)nextAdAction:(id)sender;
- (IBAction)nextSizeAction:(id)sender;
- (IBAction)toggleTestAction:(id)sender;
@end

