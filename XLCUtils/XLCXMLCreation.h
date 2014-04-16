//
//  XLCXMLCreation.h
//  XLCUtils
//
//  Created by Xiliang Chen on 14-4-8.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XLCXMLObjectProperties;

@protocol XLCXMLCreation <NSObject>

@optional

+ (id)xlc_createWithProperties:(XLCXMLObjectProperties *)props andContents:(NSArray *)contents;
+ (id)xlc_createWithXMLDictionary:(NSDictionary *)dict;

@end

@interface XLCXMLObjectProperties : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dict;

- (id)consume:(id)key;
- (NSDictionary *)consumeAll;

- (id)consumeSingle;

@end