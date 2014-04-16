//
//  XLCXMLObjectCreationAddition.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14-4-10.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import "XLCXMLCreation.h"

#import "XLCXMLObject.h"

@interface NSArray (XLCXMLCreation) <XLCXMLCreation>

@end

@implementation NSArray (XLCXMLCreation)

+ (id)xlc_createWithProperties:(XLCXMLObjectProperties *)props andContents:(NSArray *)contents
{
    return [contents copy] ?: [self new];
}

@end

@interface NSDictionary (XLCXMLCreation) <XLCXMLCreation>

@end

@implementation NSDictionary (XLCXMLCreation)

+ (id)xlc_createWithProperties:(XLCXMLObjectProperties *)props andContents:(NSArray *)contents
{
    return [props consumeAll];
}

@end

@interface XLCXMLObject (XLCXMLCreation) <XLCXMLCreation>

@end

@implementation XLCXMLObject (XLCXMLCreation)

+ (id)xlc_createWithXMLDictionary:(NSDictionary *)dict
{
    NSArray *contents = dict[@"#contents"];
    if ([contents count]) {
        id obj = contents[0];
        if ([obj isKindOfClass:[NSDictionary class]]) {
            return [self objectWithDictionary:obj];
        }
        return [self objectWithXMLString:[NSString stringWithFormat:@"<NSString>%@</NSString>", obj] error:NULL];
    }
    return [self new];
}

@end

@interface NSNumber (XLCXMLCreation) <XLCXMLCreation>

@end

@implementation NSNumber (XLCXMLCreation)

+ (id)xlc_createWithProperties:(XLCXMLObjectProperties *)props andContents:(NSArray *)contents
{
    NSString *str;
    
    if ([contents count]) {
        str = contents[0];
    } else {
        str = [props consumeSingle];
    }
    
    if ([str isKindOfClass:[NSString class]]) {
        str = [[str lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([str length]) {
            switch ([str characterAtIndex:0]) {
                case 'y':
                case 't':
                    return @YES;
                case 'n':
                case 'f':
                    return @NO;
            }
        }
        
        return [NSNumber numberWithDouble:[str doubleValue]];
    }
    
    return @0;
}

@end

@interface NSString (XLCXMLCreation) <XLCXMLCreation>

@end

@implementation NSString (XLCXMLCreation)

+ (id)xlc_createWithProperties:(XLCXMLObjectProperties *)props andContents:(NSArray *)contents
{
    return [[props consumeSingle] description] ?: [contents componentsJoinedByString:@""] ?: [self new];
}

@end

@interface NSNull (XLCXMLCreation) <XLCXMLCreation>

@end

@implementation NSNull (XLCXMLCreation)

+ (id)xlc_createWithXMLDictionary:(NSDictionary *)dict
{
    return [self null];
}

@end

#pragma mark -

@implementation XLCXMLObjectProperties {
    NSMutableDictionary *_dict;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        _dict = [dict mutableCopy];
    }
    return self;
}

- (id)consume:(id)key
{
    id obj = _dict[key];
    [_dict removeObjectForKey:key];
    return obj;
}

- (NSDictionary *)consumeAll
{
    NSDictionary *dict = _dict;
    _dict = nil;
    return dict;
}

- (id)consumeSingle
{
    return _dict.count == 1 ? _dict.allValues[0] : nil;
}

@end