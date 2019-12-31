//
//  AdViewAdapterAdFill.h
//  AdView
//
//  Created by AdView on 13-7-25.
//  用于选择服务器地址.请求参数的拼接

#import "AdViewAdapter.h"
#import "AdViewContent.h"

@interface AdViewAdapterAdFill : AdViewAdapter {
    NSTimer *_notifyTimer;
    NSString *repostHost;
    int urlNumber;
}
@property (copy, nonatomic) NSString *reportHost;
@property (nonatomic, strong) NSMutableDictionary * infoDict;   //保存需要上传的参数

- (void)initInfo;
@end
