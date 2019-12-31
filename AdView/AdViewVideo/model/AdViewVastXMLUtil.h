//
//  ADVASTXMLUtil.h
//  AdViewVideoSample
//
//  Created by AdView on 16/9/30.
//  Copyright © 2016年 AdView. All rights reserved.
//

#import <Foundation/Foundation.h>

BOOL adViewValidateXMLDocSyntax(NSData *document);                         // check for valid XML syntax using xmlReadMemory
BOOL adViewValidateXMLDocAgainstSchema(NSData *document, NSData *schema);  // check for valid VAST 2.0 syntax using xmlSchemaValidateDoc & vast_2.0.1.xsd schema
NSArray *adViewPerformXMLXPathQuery(NSData *document, NSString *query);    // parse the document for the xpath in 'query' using xmlXPathEvalExpression

