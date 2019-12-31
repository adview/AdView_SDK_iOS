//
//  ADVAST2Parser.h
//  AdViewVideoSample
//
//  Created by AdView on 16/10/9.
//  Copyright © 2016年 AdView. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AdViewVastError.h"

@class AdViewVastModel;

@interface AdViewVast2Parser : NSObject

- (void)parseWithUrl:(NSURL *)url completion:(void (^)(AdViewVastModel *, AdViewVastError))block;
- (void)parseWithData:(NSData *)vastData completion:(void (^)(AdViewVastModel *, AdViewVastError))block;;

@end
