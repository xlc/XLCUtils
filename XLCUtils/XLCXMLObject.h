//
//  XLCXMLObject.h
//  XLCUtils
//
//  Created by Xiliang Chen on 14-3-30.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XLCXMLObject : NSObject

@property (nonatomic, readonly) NSDictionary *root;

+ (instancetype)objectWithContentsOfURL:(NSURL *)url error:(NSError **)error;
+ (instancetype)objectWithXMLString:(NSString *)str error:(NSError **)error;
+ (instancetype)objectWithXMLParser:(NSXMLParser *)parser error:(NSError **)error;
+ (instancetype)objectWithDictionary:(NSDictionary *)dict;

- (id)create;
- (id)createWithContextDictionary:(NSMutableDictionary *)dict;

@end
