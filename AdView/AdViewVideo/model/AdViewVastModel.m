//
//  ADVASTModel.m
//  AdViewVideoSample
//
//  Created by AdView on 16/9/30.
//  Copyright © 2016年 AdView. All rights reserved.
//

#import "AdViewVastModel.h"
#import "AdViewVastMediaFile.h"
#import "AdViewVastUrlWithId.h"
#import "AdViewVastXMLUtil.h"
#import "AdViewExtTool.h"
#import "AdViewVastMediaFilePicker.h"
#import "AdViewVastCreative.h"
#import "ADVASTCompanionModel.h"
#import "ADVASTIconModel.h"
#import "ADVGVastExtensionModel.h"

@interface AdViewVastModel() {
    NSMutableArray * _vastDocumentArray;
}

@property (nonatomic, strong) NSArray *wrapperImpressionArray;
@property (nonatomic, strong) NSArray *wrapperErrorArray;
@property (nonatomic, strong) NSMutableArray *wrapperTrackingArray;
@property (nonatomic, strong) NSArray *wrapperClickTrackingArray;
@property (nonatomic, strong) NSMutableArray <NSDictionary <ADVASTCompanionModel *, NSString *> *> * wrapperCompanionArray;
@property (nonatomic, strong) NSArray <ADVASTIconModel *> * wrapperIconArray;

// returns an array of VASTUrlWithId objects
- (NSArray *)resultsForQuery:(NSString *)query withDocumentData:(NSData*)document;

// returns the text content of both simple text and CDATA sections
- (NSString *)content:(NSDictionary *)node;
@end

@implementation AdViewVastModel
@synthesize adsArray;
@synthesize currentIndex;

- (instancetype)init
{
    if (self = [super init])
    {
        if (nil == adsArray) adsArray = [[NSMutableArray alloc] init];
        currentIndex = 0;
        self.wrapperNumber = 0;
    }
    return self;
}

- (void)dealloc
{
    if (self.adsArray != nil)
    {
        [self.adsArray removeAllObjects];
    }
    self.adsArray = nil;
    self.currentIndex = 0;
}

#pragma mark - wrapper ad data parse
//⚠️ 第一次 尝试获取wrapper,顺便解析每一次返回数据
- (void)parseWrapperData {
    NSData *document = [_vastDocumentArray lastObject];
    
    NSString *adQuery = @"//Impression";
    NSArray *impArr = [self impressions:adQuery withData:document];
    self.wrapperImpressionArray = [self.wrapperImpressionArray arrayByAddingObjectsFromArray:impArr];
    
    NSString *errorQuery = @"//Error";
    NSArray *errorArr = [self errors:errorQuery withData:document];
    self.wrapperErrorArray = [self.wrapperErrorArray arrayByAddingObjectsFromArray:errorArr];
    
    NSString *trackingQuery = @"//Linear//Tracking";
    NSDictionary *trackDict = [self trackingEvents:trackingQuery withData:document];
    if (trackDict.allKeys.count) {
        [self.wrapperTrackingArray addObject:trackDict];
    }
    
    NSString *clickTrackingQuery = @"//ClickTracking";
    NSArray *clickTrackingArray = [self clickTracking:clickTrackingQuery withData:document];
    self.wrapperClickTrackingArray = [self.wrapperClickTrackingArray arrayByAddingObjectsFromArray:clickTrackingArray];
    
    
    NSString *companionAdsQuery = @"//CompanionAds";
    NSDictionary *companionDict = [self getCompanionAdWithQueryString:companionAdsQuery withData:document];
    if ([companionDict allKeys].count) {
        [self.wrapperCompanionArray addObject:companionDict];
    }
    
    NSString *iconQuery = @"//Icons";
    NSArray *iconArray = [self iconFiles:iconQuery withData:document];
    self.wrapperIconArray = [self.wrapperIconArray arrayByAddingObjectsFromArray:iconArray];
}

#pragma mark - cleared Ad data method
//⚠️ 第二次解析 遍历解析 每个Ad的信息
- (AdViewVastModel *)getInLineAvailableAd {
    NSString * adQuery = @"/VAST/Ad";
    NSData * document = [_vastDocumentArray lastObject];
    NSArray * adArray = adViewPerformXMLXPathQuery(document, adQuery);
    for (NSDictionary *result in adArray) {
        AdViewVastAdModel * vastAdModel = [[AdViewVastAdModel alloc] init];
        NSUInteger index = [adArray indexOfObject:result] + 1;

        //⚠️ 获取可用的用于播放的creative to do: 解析VPAID
        vastAdModel.creativeArray = [self getAvailableCreativeAndInfo:index];
        vastAdModel.extesionArray = [self getAvailableExtensionInfoIndex:index];
        
        // 获取相关伴随
        NSString *query = [NSString stringWithFormat:@"/VAST/Ad[%tu]//CompanionAds",index];
        vastAdModel.compaionsDict = [self getCompanionAdWithQueryString:query withData:document];
        
        // wrapper伴随与广告伴随合并
        if (self.wrapperCompanionArray.count) {
            NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
            for (NSDictionary *wrapperCompanionDict in self.wrapperCompanionArray) {
                for (NSString *key in [wrapperCompanionDict allKeys]) {
                    if ([vastAdModel.compaionsDict objectForKey:key]) {
                        NSMutableArray *array = [NSMutableArray arrayWithArray:[wrapperCompanionDict objectForKey:key]];
                        [array arrayByAddingObjectsFromArray:[vastAdModel.compaionsDict objectForKey:key]];
                        [tempDict setObject:array forKey:key];
                    } else {
                        [tempDict setObject:[wrapperCompanionDict objectForKey:key] forKey:key];
                    }
                }
            }
            vastAdModel.compaionsDict = tempDict;
        }
        
        NSString *errQuery = [NSString stringWithFormat:@"/VAST/Ad[%tu]//Error",index];
        NSArray *errArr = [self errors:errQuery withData:document];
        if (nil != errArr && errArr.count > 0) {
            vastAdModel.errorArrary = errArr;
        }
        if (self.wrapperErrorArray.count) {
            vastAdModel.wrapperErrArray = self.wrapperErrorArray;
        }
        
        NSString *impQuery = [NSString stringWithFormat:@"/VAST/Ad[%tu]//Impression",index];
        NSArray *impArr = [self impressions:impQuery withData:document];
        if (nil != impArr && impArr.count > 0) {
            vastAdModel.impressionArray = impArr;
        }
        if (self.wrapperImpressionArray.count) {
            vastAdModel.wrapperImpArray = self.wrapperImpressionArray;
        }
        
        vastAdModel.sequence = @"999";
        NSArray *attributes = result[@"nodeAttributeArray"];
        for (NSDictionary *attribute in attributes)
        {
            NSString *name = attribute[@"attributeName"];
            if ([name isEqualToString:@"sequence"])
            {
                NSString *sequence = attribute[@"nodeContent"];
                vastAdModel.sequence = sequence;
            }
        }
        [adsArray addObject:vastAdModel];
    }
    
    // 按照sequence排序，从小到大排序
    adsArray = [[adsArray sortedArrayUsingComparator:^NSComparisonResult(AdViewVastAdModel * model1, AdViewVastAdModel * model2) {
        return [model1.sequence compare:model2.sequence];
    }] mutableCopy];
    return self;
}

//⚠️ 获取creative
- (NSArray*)getAvailableCreativeAndInfo:(NSUInteger)index
{
    NSMutableArray *creativeArray = [[NSMutableArray alloc] init];
    
    NSData *document = [_vastDocumentArray lastObject];
    NSString *query = [NSString stringWithFormat:@"/VAST/Ad[%tu]//Creative[Linear]",index];
    NSArray *arr = adViewPerformXMLXPathQuery(document, query);
    if (!arr || arr.count == 0) {
        return nil;
    }
    
    for (NSDictionary * result in arr)
    {
        NSUInteger creativeIndex = [arr indexOfObject:result] + 1;
        
        NSString *durationQuery = [NSString stringWithFormat:@"/VAST/Ad[%tu]//Creative[%tu]//Duration",index,creativeIndex];
        NSArray *durationArr = adViewPerformXMLXPathQuery(document, durationQuery);
        
        NSString *mediaQuery = [NSString stringWithFormat:@"/VAST/Ad[%tu]//Creative[%tu]//MediaFile",index,creativeIndex];
        BOOL fileAvailable = NO;
        NSArray * mediaFilesArray = [self mediaFiles:mediaQuery];   //构造MediaFile模型数组
        
        for (AdViewVastMediaFile *mediaFile in mediaFilesArray)
        {
            //判断MediaFiles数组中是否有可解析的MediaFile
            fileAvailable = (fileAvailable || [AdViewVastMediaFilePicker isMIMETypeCompatible:mediaFile]);
        }
        
        if (!fileAvailable)
        {
            AdViewLogDebug(@"第 %tu creative 没有可用mediaFile",creativeIndex);
            continue;
        }
        
        AdViewVastCreative *fModel = [[AdViewVastCreative alloc] init];
        fModel.mediaFiles = mediaFilesArray;
        AdViewLogDebug(@"%@",mediaFilesArray);
        if (durationArr && durationArr.count) {
            NSString *timeStr = [self content:durationArr.firstObject];
            fModel.duration = [self changeTimeString:timeStr];
        }
        
        // 解析sequence
        fModel.sequence = @"999";
        NSArray *attributes = result[@"nodeAttributeArray"];
        for (NSDictionary *attribute in attributes) {
            NSString *name = attribute[@"attributeName"];
            if ([name isEqualToString:@"sequence"]) {
                NSString *sequence = attribute[@"nodeContent"];
                fModel.sequence = sequence;
            }
        }
        
        //获取skip值
        NSString *skipStr = [NSString stringWithFormat:@"/VAST/Ad[%tu]//Creative[%tu]/Linear",index,creativeIndex];
        NSArray *linerArr = adViewPerformXMLXPathQuery(document, skipStr);
        NSDictionary *inlineDict = [linerArr firstObject];
        NSArray *inlineAttributes = inlineDict[@"nodeAttributeArray"];
        fModel.skipoffset = @"-1";
        for (NSDictionary *attribute in inlineAttributes) {
            NSString *name = attribute[@"attributeName"];
            if ([name isEqualToString:@"skipoffset"]) {
                NSString *skipOffset = attribute[@"nodeContent"];
                if (nil != skipOffset && skipOffset.length > 0) {
                    fModel.skipoffset = [self changeTimeString:skipOffset];
                }
            }
        }
        
        //获取监听网址等。。。
        NSString *trackQuery = [NSString stringWithFormat:@"/VAST/Ad[%tu]//Creative[%tu]//Tracking",index,creativeIndex];
        NSDictionary *trackDict = [self trackingEvents:trackQuery withData:document];
        if (nil != trackDict && trackDict.allKeys.count > 0) {
            fModel.trackings = trackDict;
        }
        fModel.wrapperTrackingArray = self.wrapperTrackingArray;
        
        NSString *cliThrQuery = [NSString stringWithFormat:@"/VAST/Ad[%tu]//Creative[%tu]//ClickThrough",index,creativeIndex];
        AdViewVastUrlWithId *urlWithId = [self clickThrough:cliThrQuery withData:document];
        if (nil != urlWithId) {
            fModel.clickThrough = urlWithId;
        }
        
        NSString *cliTrackQuery = [NSString stringWithFormat:@"/VAST/Ad[%tu]//Creative[%tu]//ClickTracking",index,creativeIndex];
        NSArray *cliTrackArr = [self clickTracking:cliTrackQuery withData:document];
        if (nil != cliTrackArr && cliTrackArr.count > 0) {
            fModel.clickTrackings = cliTrackArr;
        }
        fModel.wrapperClickTrackingArray = self.wrapperClickTrackingArray;
        
        NSString *iconQuery = [NSString stringWithFormat:@"/VAST/Ad[%tu]//Creative[%tu]//Icon",index,creativeIndex];
        NSArray *iconArr = [self iconFiles:iconQuery withData:document];
        if (iconArr && iconArr.count) {
            fModel.iconArray = iconArr;
        }
        if (self.wrapperIconArray.count) {
            [self.wrapperIconArray arrayByAddingObjectsFromArray:iconArr];
            fModel.iconArray = self.wrapperIconArray;
        }
        
        NSString * adParametersQuery = [NSString stringWithFormat:@"//Linear/AdParameters"];
        NSArray * adParametersArray = [self adParameters:adParametersQuery withData:document];
        fModel.adParametersArray = adParametersArray;
        
        [creativeArray addObject:fModel];
    }
    
    NSArray *newArr = [creativeArray sortedArrayUsingComparator:^NSComparisonResult(AdViewVastCreative *model1,AdViewVastCreative *model2){
        return [model1.sequence compare:model2.sequence];
    }];
    return newArr;
}

//获取extension
- (NSArray *)getAvailableExtensionInfoIndex:(NSInteger)index {
    NSMutableArray * retArray = [[NSMutableArray alloc] init];
    
    NSData *document = [_vastDocumentArray lastObject];
    NSString *query = [NSString stringWithFormat:@"/VAST/Ad[%tu]/InLine/Extensions",index];
    NSArray * extensionsNodeArray = adViewPerformXMLXPathQuery(document, query);

    NSDictionary * extensionsDict = [extensionsNodeArray firstObject];  //有且只有一个Extensions标签
    NSArray * extensionArray = extensionsDict[@"nodeChildArray"];       //获取Extension数组
    for (NSDictionary * extensionNodeDict in extensionArray) {
        NSString * extensionType = extensionNodeDict[@"nodeAttributeArray"][0][@"nodeContent"];
        if ([extensionType isEqualToString:@"AdVerifications"]) {
            NSDictionary * verification = extensionNodeDict[@"nodeChildArray"][0][@"nodeChildArray"][0];
            
            NSString * vendor = verification[@"nodeAttributeArray"][0][@"nodeContent"];
            NSString * javaScriptResource = nil;
            NSString * verificationParameters = nil;
            NSMutableDictionary * trackingEvents = [NSMutableDictionary new];
            
            for (NSDictionary * childNode in verification[@"nodeChildArray"]) {
                if ([childNode[@"nodeName"] isEqualToString:@"JavaScriptResource"]) {
                    javaScriptResource = childNode[@"nodeChildArray"][0][@"nodeContent"];
                } else if ([childNode[@"nodeName"] isEqualToString:@"VerificationParameters"]) {
                    verificationParameters = childNode[@"nodeChildArray"][0][@"nodeContent"];
                } else if ([childNode[@"nodeName"] isEqualToString:@"TrackingEvents"]) {
                    NSArray * trackings = childNode[@"nodeChildArray"];
                    for (NSDictionary * tracking in trackings) {
                        NSString * trackingURL = tracking[@"nodeChildArray"][0][@"nodeContent"];
                        NSString * trackingEventName = tracking[@"nodeAttributeArray"][0][@"nodeContent"];
                        [trackingEvents setObject:trackingURL forKey:trackingEventName];
                    }
                }
            }
            ADVGVastExtensionModel * extensionModel = [ADVGVastExtensionModel new];
            extensionModel.vendor = vendor;
            extensionModel.typeString = extensionType;
            extensionModel.verificationParameters = verificationParameters;
            extensionModel.VerificationScriptURLString = javaScriptResource;
            extensionModel.trackingEvents = trackingEvents;
            [retArray addObject:extensionModel];
        }
    }
    return retArray;
}

- (NSMutableDictionary *)getCompanionAdWithQueryString:(NSString*)query withData:(NSData*)documentData {
    NSArray *arr = adViewPerformXMLXPathQuery(documentData, query);
    NSMutableDictionary *infoDict = [[NSMutableDictionary alloc] init];
    
    if (arr && arr.count > 0) {
        for (NSDictionary *result in arr) {
            NSUInteger index = [arr indexOfObject:result] + 1;
            NSArray *attributes = result[@"nodeAttributeArray"];
            if (attributes) {
                for (NSDictionary *attribute in attributes) {
                    NSString *name = attribute[@"attributeName"];
                    if ([name isEqualToString:@"required"]) {
                        NSString *required = attribute[@"nodeContent"];
                        if (required && required.length) {
                            NSArray <ADVASTCompanionModel *> * companions = [self companion:[NSString stringWithFormat:@"%@[%tu]/Companion",query,index]];
                            if (companions && companions.count > 0) {
                                [infoDict setObject:companions forKey:required];
                            }
                        }
                    }
                }
            } else {
                //不带required属性的
                NSArray <ADVASTCompanionModel *> * companions = [self companion:[NSString stringWithFormat:@"%@[%tu]/Companion",query,index]];
                if (companions && companions.count > 0) {
                    [infoDict setObject:companions forKey:@"all"];
                }
            }
        }
    }
    return infoDict;
}

- (NSArray <ADVASTCompanionModel *>*)companion:(NSString*)query {
    NSData *document = [_vastDocumentArray lastObject];
    NSArray *arr = adViewPerformXMLXPathQuery(document, query);
    if (nil == arr || arr.count <= 0) return nil;
    
    NSMutableArray <ADVASTCompanionModel *> * companionArr = [[NSMutableArray alloc] init];
    
    for (NSDictionary *result in arr) {
        ADVASTCompanionModel *comModel = [[ADVASTCompanionModel alloc] init];
        comModel.wrapperNumber = self.wrapperNumber;
        NSUInteger index = [arr indexOfObject:result] + 1;
        
        NSMutableDictionary*  companionDict = [[NSMutableDictionary alloc] init];
        NSArray *attributes = result[@"nodeAttributeArray"];
        for (NSDictionary *attribute in attributes) {
            NSString *name = attribute[@"attributeName"];
            NSString *content = attribute[@"nodeContent"];
            [companionDict setObject:content forKey:name];
        }
        comModel.contentDict = companionDict;
        
        NSArray *childArray = result[@"nodeChildArray"];
        if ([childArray count] > 0) {
            for (NSDictionary *childNode in childArray) {
                if ([childNode[@"nodeName"] isEqualToString:@"HTMLResource"]) {
                    NSString *htmlResource = [self content:childNode];
                    if (htmlResource && htmlResource.length > 0) {
                        comModel.htmlSourceStr = htmlResource;
                    }
                }else if ([childNode[@"nodeName"] isEqualToString:@"IFrameResource"]) {
                    NSString *iframeResource = [self content:childNode];
                    if (iframeResource && iframeResource.length > 0) {
                        comModel.iframeSourceStr = iframeResource;
                    }
                }else if ([childNode[@"nodeName"] isEqualToString:@"StaticResource"]) {
                    NSString *staticResource = [self content:childNode];
                    NSArray *attributesArr = childNode[@"nodeAttributeArray"];
                    NSMutableDictionary *sDict = [NSMutableDictionary dictionary];
                    for (NSDictionary *attribute in attributesArr) {
                        NSString *name = attribute[@"attributeName"];
                        if ([name isEqualToString:@"type"]) {
                            NSString *typeStr = attribute[@"nodeContent"];
                            if (typeStr && typeStr.length > 0) {
                                [sDict setObject:typeStr forKey:name];
                            }
                        }
                    }
                    if (staticResource && staticResource.length > 0) {
                        [sDict setObject:staticResource forKey:@"StaticResource"];
                        comModel.staticSourceDict = sDict;
                    }
                }
            }
        }
        
        NSArray *companionClickThrough = adViewPerformXMLXPathQuery(document, [NSString stringWithFormat:@"%@[%tu]//CompanionClickThrough",query,index]);
        NSMutableArray *cCTArr = [[NSMutableArray alloc] init];
        for (NSDictionary * dict in companionClickThrough) {
            NSString *urlString = [self content:dict];
            if (urlString && urlString.length > 0)
                [cCTArr addObject:urlString];
        }
        if (cCTArr.count > 0) {
            comModel.clickThroughArr = cCTArr;
        }
        
        
        NSArray *companionClickTracking= adViewPerformXMLXPathQuery(document, [NSString stringWithFormat:@"%@[%tu]//CompanionClickTracking",query,index]);
        NSMutableArray *cCTrArr = [[NSMutableArray alloc] init];
        for (NSDictionary * dict in companionClickTracking) {
            NSString *urlString = [self content:dict];
            if (urlString && urlString.length > 0)
                [cCTrArr addObject:urlString];
        }
        if (cCTrArr.count > 0) {
            comModel.clickTrackingsArr = cCTrArr;
        }
        
        NSArray *Tracking = adViewPerformXMLXPathQuery(document, [NSString stringWithFormat:@"%@[%tu]//Tracking",query,index]);
        // 取出trackings中的所有监听事件
        NSMutableDictionary *eventDict = [[NSMutableDictionary alloc] init];
        for (NSDictionary * resultT in Tracking) {
            NSString *urlString = [self content:result];
            NSArray *attributes = resultT[@"nodeAttributeArray"];
            for (NSDictionary *attribute in attributes) {
                NSString *name = attribute[@"attributeName"];
                if ([name isEqualToString:@"event"]) {
                    NSString *event = attribute[@"nodeContent"];
                    NSMutableArray *newEventArray = [NSMutableArray array];
                    NSArray *oldEventArray = [eventDict valueForKey:event];
                    if (oldEventArray)
                    {
                        [newEventArray addObjectsFromArray:oldEventArray];
                    }
//                    NSURL *eventURL = [self urlWithCleanString:urlString];
                    if (nil != urlString && urlString.length > 0)
                    {
                        [newEventArray addObject:urlString];
                        [eventDict setValue:newEventArray forKey:event];
                    }
                }
            }
        }
        
        if ([eventDict allKeys].count > 0) {
            comModel.trackingsDict = eventDict;
        }
        
        [companionArr addObject:comModel];
        companionDict = nil;
    }
    return companionArr;
}

- (NSArray *)iconFiles:(NSString*)query withData:(NSData*)documentData
{
    NSArray *iconArr = adViewPerformXMLXPathQuery(documentData, query);
    NSMutableArray *iconArray = [[NSMutableArray alloc] init]; // 容器
    if (nil == iconArr || iconArr.count <= 0) return nil;
    for (NSDictionary *icon in iconArr)
    {
        ADVASTIconModel *iconModel = [[ADVASTIconModel alloc] init];
        iconModel.wrapperNumber = self.wrapperNumber;
        NSString *htmlResource;
        NSString *iframeResource;
        NSString *staticResource;
        
        NSMutableDictionary *conDict = [[NSMutableDictionary alloc] init];
        NSArray *attributes = icon[@"nodeAttributeArray"];
        for (NSDictionary *attribute in attributes)
        {
            NSString *name = attribute[@"attributeName"];
            NSString *content = attribute[@"nodeContent"];
            if ([name isEqualToString:@"offset"] || [name isEqualToString:@"duration"])
            {
                content = [self changeTimeString:content];
            }
            [conDict setObject:content forKey:name];
        }
        iconModel.contentDict = conDict;
        
        NSArray *childArray = icon[@"nodeChildArray"];
        if ([childArray count] > 0)
        {
            // return the first array element that is not a comment
            for (NSDictionary *childNode in childArray)
            {
                if ([childNode[@"nodeName"] isEqualToString:@"HTMLResource"])
                {
                    htmlResource = [self content:childNode];
                    if (htmlResource && htmlResource.length > 0)
                    {
                        iconModel.htmlSourceStr = htmlResource;
                    }
                }
                else if ([childNode[@"nodeName"] isEqualToString:@"IFrameResource"])
                {
                    iframeResource = [self content:childNode];
                    if (iframeResource && iframeResource.length > 0) {
                        iconModel.iframeSourceStr = iframeResource;
                    }
                }
                else if ([childNode[@"nodeName"] isEqualToString:@"StaticResource"])
                {
                    NSArray *attributesArr = childNode[@"nodeAttributeArray"];
                    NSMutableDictionary *sDict = [NSMutableDictionary dictionary];
                    for (NSDictionary *attribute in attributesArr)
                    {
                        NSString *name = attribute[@"attributeName"];
                        if ([name isEqualToString:@"type"])
                        {
                            NSString *typeStr = attribute[@"nodeContent"];
                            if (typeStr && typeStr.length > 0)
                            {
                                [sDict setObject:typeStr forKey:name];
                            }
                        }
                    }
                    staticResource = [self content:childNode];
                    if (staticResource && staticResource.length > 0)
                    {
                        [sDict setObject:staticResource forKey:@"StaticResource"];
                        iconModel.staticSourceDict = sDict;
                    }
                }
            }
        }
        
        NSArray *iconClickThrough = adViewPerformXMLXPathQuery(documentData, [NSString stringWithFormat:@"%@[1]//IconClickThrough",query]);
        NSMutableArray *iCTArr = [[NSMutableArray alloc] init];
        for (NSDictionary * dict in iconClickThrough) {
            NSString *urlString = [self content:dict];
            if (urlString && urlString.length > 0)
                [iCTArr addObject:urlString];
        }
        if (iCTArr.count > 0) {
            iconModel.clickThroughArr = iCTArr;
        }
        
        NSArray *iconClickTracking= adViewPerformXMLXPathQuery(documentData, [NSString stringWithFormat:@"%@[1]//IconClickTracking",query]);
        NSMutableArray *iCTrArr = [[NSMutableArray alloc] init];
        for (NSDictionary * dict in iconClickTracking) {
            NSString *urlString = [self content:dict];
            if (urlString && urlString.length > 0)
                [iCTrArr addObject:urlString];
        }
        if (iCTrArr.count > 0) {
            iconModel.clickTrackingsArr = iCTrArr;
        }
        
        NSArray *iconViewTracking = adViewPerformXMLXPathQuery(documentData, [NSString stringWithFormat:@"%@[1]//IconViewTracking",query]);
        NSMutableArray *iVTArr = [[NSMutableArray alloc] init];
        for (NSDictionary * dict in iconViewTracking) {
            NSString *urlString = [self content:dict];
            if (urlString && urlString.length > 0) {
                //            NSURL *url = [self urlWithCleanString:urlString];
                [iVTArr addObject:urlString];
            }
        }
        if (iVTArr.count > 0) {
            iconModel.viewTrackingsArr = iVTArr;
        }
        [iconArray addObject:iconModel];
    }
    return iconArray;
}

- (NSArray *)adParameters:(NSString *)query withData:(NSData *)documentData
{
    NSArray * adParametersArray = adViewPerformXMLXPathQuery(documentData, query);
    return adParametersArray;
}

#pragma mark - "private" method
// It should be used only be the VAST2Parser to build the model.
// It should not be used by anybody else receiving the model object.
- (void)addVASTDocument:(NSData *)vastDocument {
    if (!_vastDocumentArray) {
        _vastDocumentArray = [NSMutableArray array];
    }
    [_vastDocumentArray addObject:vastDocument];
}

#pragma mark - public method
- (NSString *)vastVersion {
    // sanity check
    if ([_vastDocumentArray count] == 0) {
        return nil;
    }
    
    NSString *version;
    NSString *query = @"/VAST/@version";
    NSArray *results = adViewPerformXMLXPathQuery([_vastDocumentArray firstObject], query);
    
    if (results.count > 0) {
        NSDictionary *attribute = results.firstObject;
        version = attribute[@"nodeContent"];
    }
    return version;
}

- (NSArray *)errors:(NSString*)queryStr withData:(NSData*)documentData{
    NSString *query = (queryStr != nil)?queryStr:@"//Error";
    return [self resultsForQuery:query withDocumentData:documentData];
}

- (NSArray *)impressions:(NSString*)queryStr withData:(NSData*)documentData
{
    NSString * query = (queryStr != nil) ? queryStr : @"//Impression";
    return  [self resultsForQuery:query withDocumentData:documentData];
}

- (NSDictionary *)trackingEvents:(NSString*)queryStr withData:(NSData*)documentData{
    NSMutableDictionary *eventDict;
    NSString *query = (queryStr != nil)?queryStr:@"//Linear//Tracking";
    
    NSArray *results = adViewPerformXMLXPathQuery(documentData, query);
    for (NSDictionary *result in results) {
        // use lazy initialization
        if (!eventDict) {
            eventDict = [NSMutableDictionary dictionary];
        }
        NSString *urlString = [self content:result];
        NSArray *attributes = result[@"nodeAttributeArray"];
        for (NSDictionary *attribute in attributes) {
            NSString *name = attribute[@"attributeName"];
            if ([name isEqualToString:@"event"]) {
                NSString *event = attribute[@"nodeContent"];
                NSMutableArray *newEventArray = [NSMutableArray array];
                NSArray *oldEventArray = [eventDict valueForKey:event];
                if (oldEventArray) {
                    [newEventArray addObjectsFromArray:oldEventArray];
                }
                //                    NSURL *eventURL = [self urlWithCleanString:urlString];
                if (nil != urlString && urlString.length > 0) {
                    [newEventArray addObject:urlString];
                    [eventDict setValue:newEventArray forKey:event];
                }
            }
        }
    }
    
    AdViewLogDebug(@"VAST - Model: returning event dictionary with %tu event(s)",[eventDict count]);
    for (NSString *event in [eventDict allKeys]) {
        NSArray *array = [eventDict valueForKey:event];
        AdViewLogDebug(@"VAST - Model: %@ has %tu URL(s)",event,[array count]);
    }
    return eventDict;
}

- (AdViewVastUrlWithId *)clickThrough:(NSString*)queryStr withData:(NSData*)documentData{
    NSString *query = (queryStr != nil)?queryStr:@"//ClickThrough";
    NSArray *array = [self resultsForQuery:query withDocumentData:documentData];
    // There should be at most only one array element.
    return array.firstObject;
}

- (NSArray *)clickTracking:(NSString*)queryStr withData:(NSData*)documentData{
    NSString *query = (queryStr != nil)?queryStr:@"//ClickTracking";
    return [self resultsForQuery:query withDocumentData:documentData];
}

//构造MediaFileModel
- (NSArray *)mediaFiles:(NSString *)queryStr {
    NSMutableArray *mediaFileArray;
    NSString *query = (queryStr != nil)?queryStr:@"//MediaFile";
    
    for (NSData *document in _vastDocumentArray) {
        NSArray *results = adViewPerformXMLXPathQuery(document, query);
        for (NSDictionary *result in results) {
            
            // use lazy initialization
            if (!mediaFileArray) {
                mediaFileArray = [NSMutableArray array];
            }
            
            NSString *id_;
            NSString *delivery;
            NSString *type;
            NSString *bitrate;
            NSString *width;
            NSString *height;
            NSString *scalable;
            NSString *maintainAspectRatio;
            NSString *apiFramework;
            
            NSArray *attributes = result[@"nodeAttributeArray"];
            for (NSDictionary *attribute in attributes) {
                NSString *name = attribute[@"attributeName"];
                NSString *content = attribute[@"nodeContent"];
                if ([name isEqualToString:@"id"]) {
                    id_ = content;
                } else  if ([name isEqualToString:@"delivery"]) {
                    delivery = content;
                } else  if ([name isEqualToString:@"type"]) {
                    type = content;
                } else  if ([name isEqualToString:@"bitrate"]) {
                    bitrate = content;
                } else  if ([name isEqualToString:@"width"]) {
                    width = content;
                } else  if ([name isEqualToString:@"height"]) {
                    height = content;
                } else  if ([name isEqualToString:@"scalable"]) {
                    scalable = content;
                } else  if ([name isEqualToString:@"maintainAspectRatio"]) {
                    maintainAspectRatio = content;
                } else  if ([name isEqualToString:@"apiFramework"]) {
                    apiFramework = content;
                }
            }
            NSString *urlString = [self content:result];
            if (urlString != nil) {
                urlString = [[self urlWithCleanString:urlString] absoluteString];
            }
            
            AdViewVastMediaFile *mediaFile = [[AdViewVastMediaFile alloc]
                                          initWithId:id_
                                          delivery:delivery
                                          type:type
                                          bitrate:bitrate
                                          width:width
                                          height:height
                                          scalable:scalable
                                          maintainAspectRatio:maintainAspectRatio
                                          apiFramework:apiFramework
                                          url:urlString];
            
            [mediaFileArray addObject:mediaFile];
        }
    }
    
    return mediaFileArray;
}

#pragma mark - helper methods
- (BOOL)isLastCreative {
    if (self.currentIndex == self.adsArray.count - 1) {
        AdViewVastAdModel *admodel = [self.adsArray objectAtIndex:self.currentIndex];
        if (admodel.currentIndex == admodel.creativeArray.count - 1) {
            return YES;
        }
    }
    return NO;
}

- (void)resetCurrentIndex {
    for (AdViewVastAdModel * admodel in self.adsArray) {
        admodel.currentIndex = 0;
    }
    self.currentIndex = 0;
}

- (AdViewVastAdModel *)getCurrentAd {
    if (self.currentIndex >= self.adsArray.count) {
        return nil;
    }
    return [self.adsArray objectAtIndex:self.currentIndex];
}

- (NSURL *)getCurrentURL {
    if (self.currentIndex >= self.adsArray.count) {
        return nil;
    }
    AdViewVastAdModel *adModel = [self.adsArray objectAtIndex:self.currentIndex];
    NSURL *url = [adModel getCurrentAvailableUrl];
    return url;
}

- (AdViewVastMediaFile *)getCurrentMediaFile {
    if (self.currentIndex >= self.adsArray.count) {
        return nil;
    }
    AdViewVastAdModel *adModel = [self.adsArray objectAtIndex:self.currentIndex];
    AdViewVastMediaFile *mediaFile = [adModel getCurrentMediaFile];
    return mediaFile;
}

//设置当前播放的视频序号
- (void)adjustCurrentIndex
{
    AdViewVastAdModel *adModel = [self.adsArray objectAtIndex:self.currentIndex];
    adModel.currentIndex ++;
    if (adModel.currentIndex >= adModel.creativeArray.count)
    {
        self.currentIndex++;
    }
}

- (NSString*)changeTimeString:(NSString*)timeString {
    NSArray *timeArr = [timeString componentsSeparatedByString:@":"];
    if (timeArr && timeArr.count == 3) {
        int time = 0;
        time += ([timeArr.firstObject intValue] * 3600);
        time += ([[timeArr objectAtIndex:1] intValue] * 60);
        time += [timeArr.lastObject intValue];
        return [NSString stringWithFormat:@"%d",time];
    }
    return @"-1";
}

- (NSArray <AdViewVastUrlWithId *>*)resultsForQuery:(NSString *)query withDocumentData:(NSData*)document
{
    NSMutableArray * retArray;
    NSString *elementName = [query stringByReplacingOccurrencesOfString:@"/" withString:@""];
    NSArray *results = adViewPerformXMLXPathQuery(document, query);
    for (NSDictionary *result in results)
    {
        if (!retArray)
        {
            retArray = [NSMutableArray array];
        }
        NSString *urlString = [self content:result];
        
        NSString *id_; // add underscore to avoid confusion with kewyord id
        NSArray *attributes = result[@"nodeAttributeArray"];
        for (NSDictionary *attribute in attributes)
        {
            NSString *name = attribute[@"attributeName"];
            if ([name isEqualToString:@"id"])
            {
                id_ = attribute[@"nodeContent"];
                break;
            }
        }
        AdViewVastUrlWithId * impression = [[AdViewVastUrlWithId alloc] initWithID:id_ url:[self urlWithCleanString:urlString]];
        [retArray addObject:impression];
    }
    AdViewLogDebug(@"VAST - Model: returning %@ array with %tu element(s)",elementName,[retArray count]);
    return retArray;
}

- (NSString *)content:(NSDictionary *)node
{
    // this is for string data
    if ([node[@"nodeContent"] length] > 0) {
        return node[@"nodeContent"];
    }
    
    // this is for CDATA
    NSArray *childArray = node[@"nodeChildArray"];
    if ([childArray count] > 0) {
        // return the first array element that is not a comment
        for (NSDictionary *childNode in childArray) {
            if ([childNode[@"nodeName"] isEqualToString:@"comment"]) {
                continue;
            }
            return childNode[@"nodeContent"];
        }
    }
    return nil;
}

- (NSURL*)urlWithCleanString:(NSString *)string
{
    NSString *cleanUrlString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];  // remove leading, trailing \n or space
    cleanUrlString = [cleanUrlString stringByReplacingOccurrencesOfString:@"|" withString:@"%7c"];
    return [NSURL URLWithString:cleanUrlString];                                                                            // return the resulting URL
}

#pragma mark - 懒加载
- (NSArray *)wrapperImpressionArray
{
    if (!_wrapperImpressionArray)
    {
        _wrapperImpressionArray = [[NSArray alloc] init];
    }
    return _wrapperImpressionArray;
}

- (NSArray *)wrapperErrorArray {
    if (!_wrapperErrorArray) {
        _wrapperErrorArray = [NSArray array];
    }
    return _wrapperErrorArray;
}

- (NSMutableArray *)wrapperTrackingArray {
    if (!_wrapperTrackingArray) {
        _wrapperTrackingArray = [NSMutableArray array];
    }
    return _wrapperTrackingArray;
}

- (NSArray *)wrapperClickTrackingArray {
    if (!_wrapperClickTrackingArray) {
        _wrapperClickTrackingArray = [NSArray array];
    }
    return _wrapperClickTrackingArray;
}

- (NSMutableArray<NSDictionary<ADVASTCompanionModel *,NSString *> *> *)wrapperCompanionArray
{
    if (!_wrapperCompanionArray)
    {
        _wrapperCompanionArray = [NSMutableArray array];
    }
    return _wrapperCompanionArray;
}

-(NSArray<ADVASTIconModel *> *)wrapperIconArray
{
    if (!_wrapperIconArray)
    {
        _wrapperIconArray = [NSArray array];
    }
    return _wrapperIconArray;
}

@end
