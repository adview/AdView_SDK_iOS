//
//  ADVASTXMLUtil.m
//  AdViewVideoSample
//
//  Created by AdView on 16/9/30.
//  Copyright © 2016年 AdView. All rights reserved.
//

#import "AdViewVastXMLUtil.h"
#import "AdViewExtTool.h"
#import <libxml/tree.h>
#import <libxml/xpath.h>
#include <libxml/xmlschemastypes.h>

#define LIBXML_SCHEMAS_ENABLED

#pragma mark - error/warning callback functions

void adViewDocumentParserErrorCallback(void *ctx, const char *msg, ...)
{
    va_list args;
    va_start (args, msg);
    char *s = va_arg(args, char*);
    NSString *errMsg;
    if(s){
        errMsg = [[NSString stringWithCString:s encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if ([errMsg length] > 0) {
        AdViewLogDebug(@"VAST- XML Util:Document parser error:%@",errMsg);
    }
    va_end(args);
}

void adViewSchemaParserErrorCallback(void *ctx, const char *msg, ...)
{
    va_list args;
    va_start (args, msg);
    char *s = va_arg(args, char*);
    NSString *errMsg = [[NSString stringWithCString:s encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([errMsg length] > 0) {
        AdViewLogDebug(@"VAST- XML Util:Schema parser error:%@",errMsg);
    }
    va_end(args);
}

void adViewSchemaParserWarningCallback(void *ctx, const char *msg, ...)
{
    va_list args;
    va_start (args, msg);
    char *s = va_arg(args, char*);
    NSString *errMsg = [[NSString stringWithCString:s encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([errMsg length] > 0) {
        AdViewLogDebug(@"VAST- XML Util:Schema parser warning:%@",errMsg);
    }
    va_end(args);
}

void adViewSchemaValidationErrorCallback(void *ctx, const char *msg, ...)
{
    va_list args;
    va_start (args, msg);
    char *s = va_arg(args, char*);
    NSString *errMsg = [[NSString stringWithCString:s encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([errMsg length] > 0) {
        AdViewLogDebug(@"VAST- XML Util:Schema validation error:%@",errMsg);
    }
    va_end(args);
}

void adViewSchemaValidationWarningCallback(void *ctx, const char *msg, ...)
{
    va_list args;
    va_start (args, msg);
    char *s = va_arg(args, char*);
    NSString *errMsg = [[NSString stringWithCString:s encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([errMsg length] > 0) {
        AdViewLogDebug(@"VAST- XML Util:Schema validation warning:%@",errMsg);
    }
    va_end(args);
}

#pragma mark - internal helper functions

NSDictionary *adViewDictionaryForNode(xmlNodePtr currentNode, NSMutableDictionary *parentResult)
{
    NSMutableDictionary *resultForNode = [NSMutableDictionary dictionary];
    
    if (currentNode->name) {
        NSString *currentNodeContent = [NSString stringWithCString:(const char *)currentNode->name encoding:NSUTF8StringEncoding];
        resultForNode[@"nodeName"] = currentNodeContent;
    }
    
    if (currentNode->content && currentNode->type != XML_DOCUMENT_TYPE_NODE) {
        NSString *currentNodeContent = [NSString stringWithCString:(const char *)currentNode->content encoding:NSUTF8StringEncoding];
        
        if ([resultForNode[@"nodeName"] isEqual:@"text"] && parentResult) {
            currentNodeContent = [currentNodeContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            NSString *existingContent = parentResult[@"nodeContent"];
            NSString *newContent;
            if (existingContent) {
                newContent = [existingContent stringByAppendingString:currentNodeContent];
            } else {
                newContent = currentNodeContent;
            }
            
            parentResult[@"nodeContent"] = newContent;
            return nil;
        }
        
        resultForNode[@"nodeContent"] = currentNodeContent;
    }
    
    xmlAttr *attribute = currentNode->properties;
    
    if (attribute) {
        NSMutableArray *attributeArray = [NSMutableArray array];
        while (attribute) {
            NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
            NSString *attributeName = [NSString stringWithCString:(const char *)attribute->name encoding:NSUTF8StringEncoding];
            if (attributeName) {
                attributeDictionary[@"attributeName"] = attributeName;
            }
            
            if (attribute->children) {
                NSDictionary *childDictionary = adViewDictionaryForNode(attribute->children, attributeDictionary);
                if (childDictionary) {
                    attributeDictionary[@"attributeContent"] = childDictionary;
                }
            }
            
            if ([attributeDictionary count] > 0) {
                [attributeArray addObject:attributeDictionary];
            }
            attribute = attribute->next;
        }
        
        if ([attributeArray count] > 0) {
            resultForNode[@"nodeAttributeArray"] = attributeArray;
        }
    }
    
    xmlNodePtr childNode = currentNode->children;
    if (childNode) {
        NSMutableArray *childContentArray = [NSMutableArray array];
        while (childNode) {
            NSDictionary *childDictionary = adViewDictionaryForNode(childNode, resultForNode);
            if (childDictionary) {
                [childContentArray addObject:childDictionary];
            }
            childNode = childNode->next;
        }
        if ([childContentArray count] > 0) {
            resultForNode[@"nodeChildArray"] = childContentArray;
        }
    }
    
    return resultForNode;
}

NSArray *adViewPerformXPathQuery(xmlDocPtr doc, NSString *query)
{
    AdViewLogDebug(@"解析-%@",query);
    xmlXPathContextPtr xpathCtx;        //XPATH 上下文指针
    xmlXPathObjectPtr xpathObj;         //XPATH 对象指针 用来存储查询结果
    
    xpathCtx = xmlXPathNewContext(doc); //创建一个XPath上下文指针
    if (xpathCtx == NULL)
    {
        AdViewLogDebug(@"VAST- XML Util:Unable to create XPath context.");
        return nil;
    }
    
    //查询XPath表达式，得到一个查询结果
    xpathObj = xmlXPathEvalExpression((xmlChar *)[query cStringUsingEncoding:NSUTF8StringEncoding], xpathCtx);
    if (xpathObj == NULL)
    {
        AdViewLogDebug(@"VAST- XML Util:Unable to evaluate XPath.");
        return nil;
    }
    
    xmlNodeSetPtr nodes = xpathObj->nodesetval; //使用xpathObj->nodesetval得到节点集合指针，其中包含了所有符合Xpath查询结果的节点
    if (!nodes)
    {
        AdViewLogDebug(@"VAST- XML Util:Nodes was nil.");
        return nil;
    }
    
    NSMutableArray * resultNodes = [NSMutableArray array];
    for (NSInteger i = 0; i < nodes->nodeNr; i++)
    {
        NSDictionary *nodeDictionary = adViewDictionaryForNode(nodes->nodeTab[i], nil);
        if (nodeDictionary)
        {
            [resultNodes addObject:nodeDictionary];
        }
    }
    
    //释放对象指针、上下文指针
    xmlXPathFreeObject(xpathObj);
    xmlXPathFreeContext(xpathCtx);
    return resultNodes;
}

#pragma mark - "public" API
//字符串是否可以XML解析
BOOL adViewValidateXMLDocSyntax(NSData *document)
{
    BOOL retval = YES;
    xmlSetGenericErrorFunc(NULL, (xmlGenericErrorFunc)adViewDocumentParserErrorCallback);
    
    //字符串转为XML文档
    xmlDocPtr doc = xmlReadMemory([document bytes], (int)[document length], "", NULL, 0); // XML_PARSE_RECOVER);
    if (doc == NULL)
    {
        AdViewLogDebug(@"VAST- XML Util:Unable to parse.");
        retval = NO;
    }
    else
    {
        xmlFreeDoc(doc);    //释放节点
    }
    xmlCleanupParser();
    return retval;
}

BOOL adViewValidateXMLDocAgainstSchema(NSData *document, NSData *schemaData)
{
    xmlSetGenericErrorFunc(NULL, (xmlGenericErrorFunc)adViewDocumentParserErrorCallback);
    
    // load XML document
    xmlDocPtr doc = xmlReadMemory([document bytes], (int)[document length], "", NULL, 0); // XML_PARSE_RECOVER);
    if (doc == NULL) {
        AdViewLogDebug(@"VAST- XML Util:Unable to parse.");
        xmlCleanupParser();
        return NO;
    }
    
    xmlLineNumbersDefault(1);
    
    xmlSchemaParserCtxtPtr parserCtxt = xmlSchemaNewMemParserCtxt([schemaData bytes], (int)[schemaData length]);
    
    xmlSchemaSetParserErrors(parserCtxt,
                             (xmlSchemaValidityErrorFunc)adViewSchemaParserErrorCallback,
                             (xmlSchemaValidityWarningFunc)adViewSchemaParserWarningCallback,
                             NULL);
    
    xmlSchemaPtr schema = xmlSchemaParse(parserCtxt);
    xmlSchemaFreeParserCtxt(parserCtxt);
    
    // xmlSchemaDump(stdout, schema); //To print schema dump
    
    xmlSchemaValidCtxtPtr validCtxt = xmlSchemaNewValidCtxt(schema);
    xmlSchemaSetValidErrors(validCtxt,
                            (xmlSchemaValidityErrorFunc)adViewSchemaValidationErrorCallback,
                            (xmlSchemaValidityWarningFunc)adViewSchemaValidationWarningCallback,
                            NULL);
    int ret = xmlSchemaValidateDoc(validCtxt, doc);
    if (ret == 0) {
        AdViewLogDebug(@"VAST- XML Util:document is valid.");
    } else if (ret > 0) {
        AdViewLogDebug(@"VAST- XML Util:document is invalid.");
    } else {
        AdViewLogDebug(@"VAST- XML Util:validation generated an internal error.");
    }
    
    xmlSchemaFreeValidCtxt(validCtxt);
    xmlFreeDoc(doc);
    
    // free the resource
    if (schema != NULL) {
        xmlSchemaFree(schema);
    }
    
    xmlSchemaCleanupTypes();
    xmlCleanupParser();
    xmlMemoryDump();
    
    return (ret == 0);
}

NSArray * adViewPerformXMLXPathQuery(NSData *document, NSString *query)
{
    xmlDocPtr doc;
    doc = xmlReadMemory([document bytes], (int)[document length], "", NULL, 0); // XML_PARSE_RECOVER);
    if (doc == NULL)
    {
        AdViewLogDebug(@"VAST - XML Util:Unable to parse.");
        return nil;
    }
    NSArray * result = adViewPerformXPathQuery(doc, query);
    xmlFreeDoc(doc);
    return result;
}
