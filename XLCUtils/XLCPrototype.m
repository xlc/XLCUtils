//
//  XLCPrototype.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14/6/12.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import "XLCPrototype.h"

#import <objc/runtime.h>

#import "XLCLogging.h"

@interface XLCPrototype ()

@property NSMutableDictionary *values;
@property NSHashTable *objects;

+ (void)assignPrototype:(XLCPrototype *)proto toObject:(id)object;
+ (void)setValue:(NSString *)key forKey:(id)value toObject:(id)object;

@end

static XLCPrototypeProvider prototypeProvider;
static BOOL updatePrototypeModifyExistingObjects;
static NSMutableDictionary *prototypeDict;

@implementation XLCPrototype

+(void)initialize
{
    if (self == [XLCPrototype class]) {
        prototypeDict = [NSMutableDictionary dictionary];
    }
}

+ (XLCPrototypeProvider)prototypeProvider
{
    return prototypeProvider;
}

+ (void)setPrototypeProvider:(XLCPrototypeProvider)provider
{
    prototypeProvider = provider;
}

+ (BOOL)isUpdatePrototypeModifyExistingObjects
{
    return updatePrototypeModifyExistingObjects;
}

+ (void)setUpdatePrototypeModifyExistingObjects:(BOOL)value
{
    updatePrototypeModifyExistingObjects = value;
}

+ (id)prototypeForName:(NSString *)name
{
    name = name ?: @"";
    @synchronized(self) {
        XLCPrototype *proto = prototypeDict[name];
        if (!proto) {
            proto = [[self alloc] init];
            proto.values = [prototypeProvider(name) mutableCopy] ?: [NSMutableDictionary dictionary];
            proto.objects = [NSHashTable weakObjectsHashTable];
            prototypeDict[name] = proto;
        }
        return proto;
    }
}

+ (void)assignPrototype:(XLCPrototype *)prototype toObject:(id)object
{
    if (!object) {
        return;
    }
    XLCPrototype *proto;
    proto = [object xlc_prototype];
    if (proto) {
        [proto.objects removeObject:object];
    }
    
    proto = prototype;
    
    if (proto) {
        [proto.objects addObject:object];
        
        [proto.values enumerateKeysAndObjectsUsingBlock:^(id key, id val, BOOL *stop) {
            [self setValue:val forKey:key toObject:object];
        }];
    }
}

+ (void)setValue:(NSString *)value forKey:(id)key toObject:(id)object
{
    id oldval = [object valueForKey:key];
    if (![oldval isEqual:value]) {
        [object setValue:value forKey:key];
    }
}

+ (void)removeAllPrototypes
{
    [prototypeDict removeAllObjects];
}

#pragma mark -

- (void)setValue:(id)value forKey:(NSString *)key
{
    [self.values setValue:value forKey:key];
    if (updatePrototypeModifyExistingObjects) {
        for (id obj in self.objects) {
            [XLCPrototype setValue:value forKey:key toObject:obj];
        }
    }
}

- (id)valueForKey:(NSString *)key
{
    return [self.values valueForKey:key];
}

- (id)objectForKeyedSubscript:(NSString *)key
{
    return self.values[key];
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key
{
    [self setValue:obj forKey:key];
}

@end

@implementation NSObject (XLCPrototype)

static void *prototypeKey = &prototypeKey;

- (XLCPrototype *)xlc_prototype
{
    return objc_getAssociatedObject(self, prototypeKey);
}

- (void)setXlc_prototype:(XLCPrototype *)proto
{
    objc_setAssociatedObject(self, prototypeKey, proto, OBJC_ASSOCIATION_RETAIN);
    [XLCPrototype assignPrototype:proto toObject:self];
}

@end