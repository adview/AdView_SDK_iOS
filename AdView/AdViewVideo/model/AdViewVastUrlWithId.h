//
//  ADVASTUrlWithId.h
//  AdViewVideoSample
//
//  Created by AdView on 16/9/30.
//  Copyright © 2016年 AdView. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AdViewVastUrlWithId : NSObject

@property (nonatomic, copy, readonly) NSString *id_; // add trailing underscore to id_ to avoid conflict with reserved keyword "id".
@property (nonatomic, strong, readonly) NSURL *url;

- (id)initWithID:(NSString *)id_ url:(NSURL *)url;

@end
