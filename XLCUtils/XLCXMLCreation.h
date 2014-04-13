//
//  XLCXMLCreation.h
//  XLCUtils
//
//  Created by Xiliang Chen on 14-4-8.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol XLCXMLCreation <NSObject>

@optional

+ (id)xlc_createWithProperties:(NSDictionary *)props andContents:(NSArray *)contents;
+ (id)xlc_createWithXMLDictionary:(NSDictionary *)dict;

@end

