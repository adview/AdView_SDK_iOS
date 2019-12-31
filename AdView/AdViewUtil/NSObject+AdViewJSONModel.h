//
//  NSObject+JSONModel.h
//  XiaoWeiTreasure
//
//  Created by AdView on 15/10/26.
//  Copyright © 2015年 unakayou. All rights reserved.
//  模型 - 字典

#import <Foundation/Foundation.h>

@interface NSObject (AdViewJSONModel) <NSCoding>
//@interface NSObject (JSONModel)<NSCoding, NSCopying, NSMutableCopying>

/**
 *  类方法字典生成模型
 */
+ (instancetype)modelFromJSONDictionary:(NSDictionary *)dict;

/**
 *  对象通过字典初始化属性
 */
- (BOOL)reflectDataFromOtherObject:(NSDictionary *)dic;

/**
 *  对象转化成字典
 */
- (NSDictionary *)dictionaryFromObject;

/**
 *  通过另一个模型更新数据
 */
- (instancetype)updateModelWithAnotherModel:(NSObject *)model;

/**
 *  格式化出类名
 */
- (NSString *)getClassName:(NSString *)attributes;

@end
