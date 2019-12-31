//
//  ADVideoData.h
//  AdViewVideoSample
//
//  Created by AdView on 15-4-9.
//  Copyright (c) 2015年 AdView. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
    AVAdActionType_Unknown = 0,       //Judge by schema, http:// , https:// (no itunes) WebView.
    AVAdActionType_Web,               //UIWebView
    AVAdActionType_OpenURL,           //For some server, if unknow, default may use OpenURL.
    AVAdActionType_AppStore,
    AVAdActionType_Call,
    AVAdActionType_Sms,
    AVAdActionType_Mail,
    AVAdActionType_Map,
}AVAdActionType;

//PBM 是否自动播放等,属于openRTB协议,此处未完全包含所有枚举
typedef NS_ENUM(NSInteger, AdView_PBM) {
    AdView_PBM_AutoPlay = 1,
    AdView_PBM_UserAllow = 3
};

@interface ADVideoData : NSObject {
    NSString *htmlData;
    CGSize videoSize;
    NSArray *showSourceUrlArr;
    NSString *actClickUrlStr;
    NSString *adBody;
    AVAdActionType adActionType;
    NSArray *clickReportArr;
    NSArray *showReportArr;
    NSArray *otherPlatArray;
}

@property (nonatomic, assign) CGSize videoSize;
@property (nonatomic, strong) NSString *htmlData;
@property (nonatomic, strong) NSArray *showSourceUrlArr;
@property (nonatomic, strong) NSString *actClickUrlStr;
@property (nonatomic, strong) NSString *adBody;
@property (nonatomic, strong) NSArray *clickReportArr;
@property (nonatomic, strong) NSArray *showReportArr;
@property (nonatomic, assign) AVAdActionType adActionType;
@property (nonatomic, copy)   NSArray * otherPlatArray;     //三方兜底平台信息数组
@property (nonatomic, assign) AdView_PBM pbm;               //是否自动播放
@end
