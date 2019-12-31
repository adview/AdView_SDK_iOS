//
//  ADVASTAdModel.m
//  KOpenAPIAdView
//
//  Created by AdView on 2018/4/27.
//

#import "AdViewVastAdModel.h"
#import "AdViewVastCreative.h"
#import "AdViewVastMediaFilePicker.h"
#import "AdViewExtTool.h"
#import "ADVASTCompanionModel.h"

@interface AdViewVastAdModel()
@property (assign, nonatomic) BOOL didReportImpression; // 是否已经发送过展示汇报
@end

@implementation AdViewVastAdModel
@synthesize currentIndex;
- (instancetype)init {
    if (self = [super init]) {
        self.currentIndex = 0;
        self.didReportImpression = NO;
    }
    return self;
}

- (NSURL *)getCurrentAvailableUrl {
    if (currentIndex >= self.creativeArray.count) {
        return nil;
    }
    AdViewVastCreative *fileModel = [self.creativeArray objectAtIndex:currentIndex];
    NSURL *url = [AdViewVastMediaFilePicker pick:fileModel.mediaFiles].url;
    return url;
}

- (AdViewVastMediaFile *)getCurrentMediaFile {
    if (currentIndex >= self.creativeArray.count) {
        return nil;
    }
    AdViewVastCreative *fileModel = [self.creativeArray objectAtIndex:currentIndex];
    return fileModel.mediaFile;
}

- (void)reportImpressionTracking {
    if (self.didReportImpression) {
        return; // 每条ad只发送一次展示汇报如果发送过就不再发送
    }
    AdViewLogDebug(@"mediafile report impression trackings");
    if (self.impressionArray && self.impressionArray.count) {
        for (AdViewVastUrlWithId *urlWithId in self.impressionArray) {
            NSURL *trackingURL = [NSURL URLWithString:[[AdViewExtTool sharedTool] replaceDefineString:[urlWithId.url absoluteString]]];
            AdViewLogDebug(@"VAST - Event Processor:mediafile send impression url %@",[trackingURL absoluteString]);
            NSMutableURLRequest* trackingURLrequest = [NSMutableURLRequest requestWithURL:trackingURL];
            trackingURLrequest.HTTPMethod = @"GET";
            trackingURLrequest.timeoutInterval = 5;
            [NSURLConnection connectionWithRequest:trackingURLrequest delegate:nil];
        }
    }
    
    // wrapper 相关包装展示汇报
    if (self.wrapperImpArray && self.wrapperImpArray.count) {
        for (AdViewVastUrlWithId *urlWithId in self.wrapperImpArray) {
            NSURL *trackingURL = [NSURL URLWithString:[[AdViewExtTool sharedTool] replaceDefineString:[urlWithId.url absoluteString]]];
            AdViewLogDebug(@"VAST - Event Processor:wrapper send impression url %@",[trackingURL absoluteString]);
            NSMutableURLRequest* trackingURLrequest = [NSMutableURLRequest requestWithURL:trackingURL];
            trackingURLrequest.HTTPMethod = @"GET";
            trackingURLrequest.timeoutInterval = 5;
            [NSURLConnection connectionWithRequest:trackingURLrequest delegate:nil];
        }
    }
    
    self.didReportImpression = YES;
}

- (void)reportErrorsTracking {
    if (self.errorArrary && self.errorArrary.count) {
        for (AdViewVastUrlWithId *urlWithId in self.errorArrary) {
            NSURL *trackingURL = [NSURL URLWithString:[[AdViewExtTool sharedTool] replaceDefineString:[urlWithId.url absoluteString]]];
            AdViewLogDebug(@"VAST - Event Processor:mediafile send error url %@",[trackingURL absoluteString]);
            NSMutableURLRequest* trackingURLrequest = [NSMutableURLRequest requestWithURL:trackingURL];
            trackingURLrequest.HTTPMethod = @"GET";
            trackingURLrequest.timeoutInterval = 5;
            [NSURLConnection connectionWithRequest:trackingURLrequest delegate:nil];
        }
    }
    
    // wrapper 相关错误汇报
    if (self.wrapperErrArray && self.wrapperErrArray.count)
    {
        for (AdViewVastUrlWithId *urlWithId in self.wrapperErrArray)
        {
            NSURL *Url = [NSURL URLWithString:[[AdViewExtTool sharedTool] replaceDefineString:[urlWithId.url absoluteString]]];
            AdViewLogDebug(@"VAST - Event Processor:wrapper send error url %@",[Url absoluteString]);
            NSMutableURLRequest* trackingURLrequest = [NSMutableURLRequest requestWithURL:Url];
            trackingURLrequest.HTTPMethod = @"GET";
            trackingURLrequest.timeoutInterval = 5;
            [NSURLConnection connectionWithRequest:trackingURLrequest delegate:nil];
        }
    }
}

- (NSArray*)getAvailableCompaionsWithSize:(CGSize)showArea {
    NSMutableArray *companionArr = [NSMutableArray array];
    NSArray *allArr = [self.compaionsDict objectForKey:@"all"];
    if (allArr && allArr.count) {
        [companionArr addObjectsFromArray:allArr];
    }
    NSArray *anyArr = [self.compaionsDict objectForKey:@"any"];
    if (anyArr && anyArr.count) {
        [companionArr addObject:anyArr.firstObject];
    }
    
    if (!companionArr || companionArr.count <= 0) {
        return nil;
    }
    
    // 只取前四个ADVASTCompanionModel
    for (int i = 4; i < companionArr.count; i++) {
        [companionArr removeObjectAtIndex:i];
    }
 
    [companionArr sortUsingComparator:^NSComparisonResult(ADVASTCompanionModel *obj1, ADVASTCompanionModel *obj2) {
        CGFloat width1 = [[obj1.contentDict objectForKey:@"width"] floatValue];
        CGFloat height1 = [[obj1.contentDict objectForKey:@"height"] floatValue];
        CGFloat width2 = [[obj2.contentDict objectForKey:@"width"] floatValue];
        CGFloat height2 = [[obj2.contentDict objectForKey:@"height"] floatValue];
        NSComparisonResult result = width1/height1 > width2/height2?NSOrderedAscending:NSOrderedDescending;
        return result;
    }];
    
    // 位置数组，如果位置被占就移除该位置
    NSMutableArray *positionArr = [NSMutableArray arrayWithObjects:@"left",@"right",@"top",@"bottom",nil];
//    CGFloat limitWidth = 0;
    CGFloat limitHeight = 0; // 目前只做了所有占位伴随调整，尽量避免覆盖
    for (int i = 0; i < companionArr.count; i++) {
        ADVASTCompanionModel *model = [companionArr objectAtIndex:i];
        CGFloat width = [[model.contentDict objectForKey:@"width"] floatValue];
        CGFloat height = [[model.contentDict objectForKey:@"height"] floatValue];
        if (width > showArea.width || height > showArea.height) {
            CGFloat wScale = width / showArea.width;
            CGFloat hScale = height / showArea.height;
            CGFloat scale = wScale > hScale ? wScale : hScale;
            width /= scale;
            height /= scale;
            [model.contentDict setValue:[NSString stringWithFormat:@"%f",width] forKey:@"width"];
            [model.contentDict setValue:[NSString stringWithFormat:@"%f",height] forKey:@"height"];
        }
        if ([positionArr containsObject:@"bottom"]) {
            if (width/height<2 && companionArr.count<=2) {
                NSString *yString = [NSString stringWithFormat:@"%f",(showArea.height - height)/2];
                [model.contentDict setValue:@"left" forKey:@"xPosition"];
                [model.contentDict setValue:yString forKey:@"yPosition"];
                [positionArr removeObject:@"bottom"];
                [positionArr removeObject:@"top"];
                [positionArr removeObject:@"left"];
            }else {
                NSString *xString = [NSString stringWithFormat:@"%f",(showArea.width - width)/2];
                [model.contentDict setValue:xString forKey:@"xPosition"];
                [model.contentDict setValue:@"bottom" forKey:@"yPosition"];
                [positionArr removeObject:@"bottom"];
                limitHeight += height;
            }
        }else if ([positionArr containsObject:@"top"]) {
            if (width/height<2 && companionArr.count<=3) {
                NSString *yString = [NSString stringWithFormat:@"%f",(showArea.height - limitHeight - height)/2];
                [model.contentDict setValue:@"left" forKey:@"xPosition"];
                [model.contentDict setValue:yString forKey:@"yPosition"];
                [positionArr removeObject:@"top"];
                [positionArr removeObject:@"left"];
            }else {
                NSString *xString = [NSString stringWithFormat:@"%f",(showArea.width - width)/2];
                [model.contentDict setValue:xString forKey:@"xPosition"];
                [model.contentDict setValue:@"top" forKey:@"yPosition"];
                [positionArr removeObject:@"top"];
                limitHeight -= height;
            }
        }else if ([positionArr containsObject:@"left"]) {
            NSString *yString = [NSString stringWithFormat:@"%f",(showArea.height - limitHeight - height)/2];
            [model.contentDict setValue:@"left" forKey:@"xPosition"];
            [model.contentDict setValue:yString forKey:@"yPosition"];
            [positionArr removeObject:@"left"];
        }else{
            NSString *yString = [NSString stringWithFormat:@"%f",(showArea.height - limitHeight - height)/2];
            [model.contentDict setValue:@"right" forKey:@"xPosition"];
            [model.contentDict setValue:yString forKey:@"yPosition"];
            [positionArr removeObject:@"right"];
        }
    }
    return companionArr;
}

@end
