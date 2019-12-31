//
//  AdCompAdapterImmob.h
//  AdViewSDK
//
//  Created by zhiwen on 12-8-30.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "AdCompAdapter.h"


@interface AdCompAdapterImmob : AdCompAdapter {
	NSMutableDictionary *infoDict;
}

- (void)initInfo;

@end