//
//  NSObject+JSONModel.m
//  XiaoWeiTreasure
//
//  Created by AdView on 15/10/26.
//  Copyright © 2015年 unakayou. All rights reserved.
//

#import "NSObject+AdViewJSONModel.h"
#import <objc/runtime.h>

@implementation NSObject (AdViewJSONModel)

+ (instancetype)modelFromJSONDictionary:(NSDictionary *)dict {
    if (nil == dict) {
        return nil;
    }
    id model = [self new];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        //属性名称
        NSString *propertyName = [[NSString alloc] initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        //属性类型
        NSString *propertyType = [[NSString alloc] initWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
        
        if ([[dict allKeys] containsObject:propertyName]) {
            id value = [dict valueForKey:propertyName];
            if (![value isKindOfClass:[NSNull class]] && value != nil) {
                if ([value isKindOfClass:[NSDictionary class]]) {
                    Class aClass = [[NSBundle mainBundle] classNamed:[self getClassName:propertyType]];
                    id pro = [aClass modelFromJSONDictionary:value];
                    [model setValue:pro forKey:propertyName];
                } else {
                    [model setValue:value forKey:propertyName];
                }
            }
        }
    }
    free(properties);
    return model;
}


- (NSDictionary *)dictionaryFromObject {
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    //获取property数量
    unsigned int outCount;
    objc_property_t * properties = class_copyPropertyList([self class], &outCount);
    
    for (int i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString * propertyName = [[NSString alloc] initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];       //property名字
        SEL function = NSSelectorFromString(propertyName);
        
        if ([self respondsToSelector:function]) {
//            id value = [self performSelector:function withObject:nil];
            IMP imp = [self methodForSelector:function];
            id (*func)(id, SEL) = (void *)imp;
            id value = func(self, function);
            
            if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
                [dict setObject:value forKey:propertyName];
            } else if ([value isKindOfClass:[NSDictionary class]]) {
                //如果objc里面有另外一个dict,需要另外判断
            }
        }
    }
    return dict;
}

- (BOOL)reflectDataFromOtherObject:(NSDictionary *)dic {
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [[NSString alloc] initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        NSString *propertyType = [[NSString alloc] initWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
        
        if ([[dic allKeys] containsObject:propertyName]) {
            id value = [dic valueForKey:propertyName];
            if (![value isKindOfClass:[NSNull class]] && value != nil) {
                if ([value isKindOfClass:[NSDictionary class]]) {
                    id pro = [self createInstanceByClassName:[self getClassName:propertyType]];
                    [pro reflectDataFromOtherObject:value];
                    [self setValue:pro forKey:propertyName];
                } else {
                    [self setValue:value forKey:propertyName];
                }
            }
        }
    }
    
    free(properties);
    return YES;
}

- (NSString *)getClassName:(NSString *)attributes {
    NSInteger index = [attributes rangeOfString:@"\""].location + 1;
    if (index <= attributes.length) {
        NSString *type = [attributes substringFromIndex:index];
        type = [type substringToIndex:[type rangeOfString:@"\""].location];
        return type;
    }
    return attributes;
}

-(id) createInstanceByClassName: (NSString *)className {
    Class aClass = [[NSBundle mainBundle] classNamed:className];
    id anInstance = [[aClass alloc] init];
    return anInstance;
}

- (instancetype)updateModelWithAnotherModel:(NSObject *)model {
    unsigned int outCount, subCount;
    
    objc_property_t * properties = class_copyPropertyList([self class], &outCount);     //本身的属性
    objc_property_t * subProperties = class_copyPropertyList([model class], &subCount); //传进来的属性

    for (int i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString * propertyName = [[NSString alloc] initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        NSString * propertyType = [[NSString alloc] initWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
        
        for (int j = 0; j < subCount; j++) {
            objc_property_t subProperty = subProperties[j];
            NSString * subPropertyName = [[NSString alloc] initWithCString:property_getName(subProperty) encoding:NSUTF8StringEncoding];
            NSString * subPropertyType = [[NSString alloc] initWithCString:property_getAttributes(subProperty) encoding:NSUTF8StringEncoding];
            
            if ([propertyName isEqualToString:subPropertyName] && [propertyType isEqualToString:subPropertyType]) {
                NSValue * value = [model valueForKey:propertyName];
                if (value != nil) {
                    [self setValue:value forKey:propertyName];
                    break;
                }
            }
        }
    }
    free(properties);
    free(subProperties);
    return self;
}

//解档
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [self init]) {
        Class c = self.class;
        // 截取类和父类的成员变量
        while (c && c != [NSObject class]) {
            unsigned int count = 0;
            Ivar * ivars = class_copyIvarList(c, &count);
            for (int i = 0; i < count; i++) {
                NSString * key = [NSString stringWithUTF8String:ivar_getName(ivars[i])];
                id value = [aDecoder decodeObjectForKey:key];
                [self setValue:value forKey:key];
            }
            // 获得c的父类
            c = [c superclass];
            free(ivars);
        }
    }
    return self;
}

//归档
- (void)encodeWithCoder:(NSCoder *)aCoder {
    Class c = self.class;
    // 截取类和父类的成员变量
    while (c && c != [NSObject class]) {
        unsigned int count = 0;
        Ivar *ivars = class_copyIvarList(c, &count);
        for (int i = 0; i < count; i++) {
            Ivar ivar = ivars[i];
            NSString *key = [NSString stringWithUTF8String:ivar_getName(ivar)];
            id value = [self valueForKey:key];
            [aCoder encodeObject:value forKey:key];
        }
        c = [c superclass];
        // 释放内存
        free(ivars);
    }
}

//- (id)copyWithZone:(NSZone *)zone
//{
//    id objCopy = [[[self class] allocWithZone:zone] init];
//    Class clazz = [self class];
//    u_int count;
//    objc_property_t* properties = class_copyPropertyList(clazz, &count);
//    NSMutableArray* propertyArray = [NSMutableArray arrayWithCapacity:count];
//    
//    for (int i = 0; i < count ; i++)
//    {
//        const char* propertyName = property_getName(properties[i]);
//        [propertyArray addObject:[NSString  stringWithCString:propertyName encoding:NSUTF8StringEncoding]];
//    }
//    
//    free(properties);
//    for (int i = 0; i < count ; i++)
//    {
//        NSString *name=[propertyArray objectAtIndex:i];
//        id value=[self valueForKey:name];
//        if([value respondsToSelector:@selector(copyWithZone:)])
//        {
//            [objCopy setValue:[value copy] forKey:name];
//            
//        }
//        else
//        {
//            [objCopy setValue:value  forKey:name];
//        }
//    }
//    return objCopy;
//}
//
//- (id)mutableCopyWithZone:(NSZone *)zone
//{
//    id objCopy = [[[self class] allocWithZone:zone] init];
//    Class clazz = [self class];
//    u_int count;
//    objc_property_t * properties = class_copyPropertyList(clazz, &count);
//    NSMutableArray * propertyArray = [NSMutableArray arrayWithCapacity:count];
//    for (int i = 0; i < count ; i++)
//    {
//        const char* propertyName = property_getName(properties[i]);
//        [propertyArray addObject:[NSString  stringWithCString:propertyName     encoding:NSUTF8StringEncoding]];
//    }
//    free(properties);
//    
//    for (int i = 0; i < count ; i++)
//    {
//        NSString *name=[propertyArray objectAtIndex:i];
//        id value=[self valueForKey:name];
//        
//        if([value respondsToSelector:@selector(mutableCopyWithZone:)])
//        {
//            [objCopy setValue:[value mutableCopy] forKey:name];
//            
//        }
//        else
//        {
//            [objCopy setValue:value forKey:name];
//            
//        }
//    }
//    return objCopy;
//}

@end
