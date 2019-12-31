//
//  ADURLConnection.h
//  AdViewVideoSample
//
//  Created by AdView on 15-4-9.
//  Copyright (c) 2015年 AdView. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "ADVideoData.h"
#import "AdViewDefinesPublic.h"

@class ADURLConnection;
@interface AVTemporaryData : NSObject {
    NSString* appID;
    NSString* posID;
    AdViewVideoType videoType;
}

@property (strong, nonatomic) NSString* appID;
@property (strong, nonatomic) NSString* posID;
@property (assign, nonatomic) AdViewVideoType videoType;

@property (nonatomic, assign) BOOL CMPPresent;
@property (nonatomic, assign) BOOL subjectToGDPR;
@property (nonatomic, copy)   NSString * consentString;
@property (nonatomic, copy)   NSString * parsedPurposeConsents;
@property (nonatomic, copy)   NSString * parsedVendorConsents;
@property (nonatomic, copy)   NSString * ccpaString;
@end

@protocol ADURLConnectionDelegate <NSObject>

- (void)connectionDidFinshedLoadingWithUrlConnection:(ADURLConnection *)connection;

- (void)connectionFailedLoadingWithError:(NSError*)error;
@end

typedef enum {
    ADURLConnectionTypeDefault,
    ADURLConnectionTypeGetData,
}ADURLConnectionType;

@interface ADURLConnection : NSObject {
    ADVideoData *videoData;
    id<ADURLConnectionDelegate> __weak conDelegate;
}

@property (nonatomic, strong) ADVideoData *videoData;
@property (nonatomic, weak) id<ADURLConnectionDelegate> conDelegate;

- (id)initWithConnectionType:(ADURLConnectionType)connectionType withTemporaryData:(AVTemporaryData*)data delegate:(id<ADURLConnectionDelegate>)delegate;

@end
