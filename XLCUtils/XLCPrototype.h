//
//  XLCPrototype.h
//  XLCUtils
//
//  Created by Xiliang Chen on 14/6/12.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSDictionary * (^XLCPrototypeProvider)(NSString *name);

@interface XLCPrototype : NSObject

+ (XLCPrototypeProvider)prototypeProvider;
+ (void)setPrototypeProvider:(XLCPrototypeProvider)provider;

+ (BOOL)isUpdatePrototypeModifyExistingObjects;
+ (void)setUpdatePrototypeModifyExistingObjects:(BOOL)value;

+ (void)removeAllPrototypes; // only useful for unit test

+ (instancetype)prototypeForName:(NSString *)name;

- (id)objectForKeyedSubscript:(NSString *)key;
- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key;

@end

@interface NSObject (XLCPrototype)

@property (nonatomic) XLCPrototype *xlc_prototype;

@end
