//
//  ADVASTUrlWithId.m
//  AdViewVideoSample
//
//  Created by AdView on 16/9/30.
//  Copyright © 2016年 AdView. All rights reserved.
//

#import "AdViewVastUrlWithId.h"

@implementation AdViewVastUrlWithId

- (id)initWithID:(NSString *)id_ url:(NSURL *)url
{
    self = [super init];
    if (self) {
        _id_ = id_;
        _url = url;;
    }
    return self;
}

@end
