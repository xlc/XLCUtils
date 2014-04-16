//
//  XLCXMLObject.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14-3-30.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import "XLCXMLObject.h"

#include <unordered_map>
#include <stack>

#import "XLCLogging.h"
#import "XLCAssertion.h"
#import "XLCXMLCreation.h"

static NSString * const XLCNamespaceURI     = @"https://github.com/xlc/XLCUtils";
static NSString * const XLCXMLAttributeName = @"https://github.com/xlc/XLCUtils:name";

struct XLCNSStringHash {
    NSUInteger operator()(NSString *s1) const {
        return [s1 hash];
    }
};

struct XLCNSStringCompare {
    BOOL operator()(NSString *s1, NSString *s2) const {
        return [s1 isEqualToString:s2];
    }
};

static id XLCCreateObjectFromDictionary(NSDictionary *dict, NSMutableDictionary *outputDict);

@interface XLCXMLObject () <NSXMLParserDelegate>

@end

@implementation XLCXMLObject {
    NSMutableDictionary *_root;
    std::unordered_map<NSString *, std::stack<NSString *>, XLCNSStringHash, XLCNSStringCompare> _namespaces;
    std::stack<NSMutableDictionary *> _current;
    std::stack<NSMutableArray *> _parent;
}

@synthesize root = _root;

+ (instancetype)objectWithContentsOfURL:(NSURL *)url error:(NSError **)error
{
    return [self objectWithXMLParser:[[NSXMLParser alloc] initWithContentsOfURL:url] error:error];
}

+ (instancetype)objectWithXMLString:(NSString *)str error:(NSError **)error
{
    return [self objectWithXMLParser:[[NSXMLParser alloc] initWithData:[str dataUsingEncoding:NSUTF8StringEncoding]] error:error];
}

+ (instancetype)objectWithXMLParser:(NSXMLParser *)parser error:(NSError **)error
{
    XLCXMLObject *obj = [[self alloc] init];

    parser.delegate = obj;
    parser.shouldProcessNamespaces = YES;
    parser.shouldReportNamespacePrefixes = YES;

    if ([parser parse]) {
        return obj;
    }

    *error = parser.parserError;

    return nil;
}

+ (instancetype)objectWithDictionary:(NSDictionary *)dict
{
    XLCXMLObject *obj = [[self alloc] init];
    obj->_root = [dict copy] ?: [NSDictionary dictionary];

    return obj;
}

#pragma mark -

- (id)create
{
    return [self createWithOutputDictionary:NULL];
}

- (id)createWithOutputDictionary:(NSDictionary **)outputDict
{
    XASSERT_NOTNULL(_root);

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (outputDict) {
        *outputDict = dict;
    }

    return XLCCreateObjectFromDictionary(_root, dict);
}

#pragma mark - NSXMLParserDelegate

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    _parent.push([NSMutableArray array]);
}

static void mergeAttribute(NSMutableDictionary *dict)
{
    if (!dict) return;

    NSMutableArray *array = dict[@"#contents"];
    NSString *name = dict[@"#name"];
    NSString *prefix = [name stringByAppendingString:@"."];
    NSString *ns = dict[@"#namespace"];

    for (id obj in [array copy]) {
        if ([obj isKindOfClass:[NSMutableDictionary class]]) {
            NSMutableDictionary *child = obj;

            mergeAttribute(child); // post-order

            NSString *childName = child[@"#name"];
            NSString *childNs = child[@"#namespace"];
            if ([childName hasPrefix:prefix] && [ns isEqualToString:childNs]) {
                NSString *attName = [childName substringFromIndex:prefix.length];
                NSMutableArray *contents = child[@"#contents"];
                switch (contents.count) {
                    case 0:
                        dict[attName] = [NSNull null];
                        break;

                    default:
                        XILOG(@"Element property contains more than one object, only first one used. %@", child);
                        // no break
                    case 1:
                        dict[attName] = [contents objectAtIndex:0];
                        break;
                }
                [array removeObject:child];
            }
        }
    }

    if (array.count == 0) {
        [dict removeObjectForKey:@"#contents"];
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    _root = _parent.top()[0];
    _parent.pop();

    mergeAttribute(_root);
}

- (void)parser:(NSXMLParser *)parser didStartMappingPrefix:(NSString *)prefix toURI:(NSString *)namespaceURI
{
    _namespaces[prefix].push(namespaceURI);
}

- (void)parser:(NSXMLParser *)parser didEndMappingPrefix:(NSString *)prefix
{
    _namespaces[prefix].pop();
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    dict[@"#name"] = elementName;
    dict[@"#namespace"] = namespaceURI;

    [attributeDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        NSArray *arr = [key componentsSeparatedByString:@":"];
        if ([arr count] == 1) {
            dict[key] = value;
        } else {
            if (_namespaces[arr[0]].empty()) {
                dict[key] = value;
            } else {
                NSString *newkey = [key substringFromIndex:[arr[0] length]];
                NSString *fullnewkey = [_namespaces[arr[0]].top() stringByAppendingString:newkey];
                dict[fullnewkey] = value;
            }
        }
    }];

    [_parent.top() addObject:dict];

    _current.push(dict);
    _parent.push([NSMutableArray array]);

    dict[@"#contents"] = _parent.top();
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([_current.top()[@"#contents"] count] == 0) {
        [_current.top() removeObjectForKey:@"#contents"];
    }
    _parent.pop();
    _current.pop();
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([string length] == 0) {
        return;
    }
    NSString *oldstr = [_parent.top() lastObject];
    if ([oldstr isKindOfClass:[NSString class]]) {
        string = [oldstr stringByAppendingString:string];
        [_parent.top() removeLastObject];
    }
    [_parent.top() addObject:string];

}

@end

#pragma mark - NSObject XLCXMLCreation

extern NSString *NSUnknownUserInfoKey;

static void XLCSetValueForKey(id obj, id value, id key)
{
    value = value == [NSNull null] ? nil : value;
    @try {
        [obj setValue:value forKey:key];
    }
    @catch (NSException *exception) {
        BOOL handled = NO;

        if ([[exception name] isEqualToString:NSUndefinedKeyException]) {

            NSDictionary *info = [exception userInfo];
            NSString *key = info[NSUnknownUserInfoKey];

            XILOG(@"Unable to set value '%@' for key path '%@' on object '%@'", value, key, obj);

            handled = YES;

        } else if ([[exception name] isEqualToString:NSInvalidArgumentException] &&
                   [value isKindOfClass:[NSString class]]) {
            static NSRegularExpression *regex;

            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                regex = [NSRegularExpression
                         regularExpressionWithPattern:@" (\\S+)Value\\]: unrecognized selector sent to instance 0x(\\S+)"
                         options:0
                         error:NULL];
            });

            NSString *reason = [exception reason];
            NSTextCheckingResult *match = [regex firstMatchInString:reason options:0 range:NSMakeRange(0, [reason length])];
            if (match) {
                // may be caused by unable to convert NSString to primitive type

                NSString *type = [reason substringWithRange:[match rangeAtIndex:1]];
                NSString *addressStr = [reason substringWithRange:[match rangeAtIndex:2]];
                unsigned long long address = 0;
                [[NSScanner scannerWithString:addressStr] scanHexLongLong:&address];
                if (address == (unsigned long long)value) { // make sure it is not something unrelated
                    NSString *str = value;
                    if ([type isEqualToString:@"char"]) {
                        if (str.length == 1) { // assume is char
                            value = @([str characterAtIndex:0]);
                        } else {    // assume is BOOL
                            value = @([str boolValue]);
                        }
                    } else {
                        if ([type isEqualToString:@"double"] || [type isEqualToString:@"float"]) {
                            value = @([str doubleValue]);
                        } else if ([type isEqualToString:@"CGPoint"] || [type isEqualToString:@"point"]) {
#if TARGET_OS_IPHONE
                            value = [NSValue valueWithCGPoint:CGPointFromString(str)];
#else
                            value = [NSValue valueWithPoint:NSPointFromString(str)];
#endif
                        } else if ([type isEqualToString:@"CGSize"] || [type isEqualToString:@"size"]) {
#if TARGET_OS_IPHONE
                            value = [NSValue valueWithCGSize:CGSizeFromString(str)];
#else
                            value = [NSValue valueWithSize:NSSizeFromString(str)];
#endif
                        } else if ([type isEqualToString:@"CGRect"] || [type isEqualToString:@"rect"]) {
#if TARGET_OS_IPHONE
                            value = [NSValue valueWithCGRect:CGRectFromString(str)];
#else
                            value = [NSValue valueWithRect:NSRectFromString(str)];
#endif
                        } else {
                            value = @([str longLongValue]);
                        }
                    }

                    [obj setValue:value forKeyPath:key];

                    handled = YES;
                }
            }

        }

        if (!handled) { // not expecting it, rethrow
            @throw;
        }
    }
}

static id XLCCreateNamespacedObject(NSDictionary *dict, NSMutableDictionary *outputDict)
{
    XASSERT([dict[@"#namespace"] isEqualToString:XLCNamespaceURI]);
    
    NSString *name = [dict[@"#name"] lowercaseString];
    
    using CommandBlock = id (^)(NSDictionary *dict, NSMutableDictionary *outputDict);
    static std::unordered_map<NSString *, CommandBlock, XLCNSStringHash, XLCNSStringCompare> commands
    {
        {@"ref", ^id(NSDictionary *dict, NSMutableDictionary *outputDict){
            return outputDict[dict[@"name"] ?: @""];
        }},
        
        {@"yes", ^id(NSDictionary *dict, NSMutableDictionary *outputDict){
            return @YES;
        }},
        
        {@"true", ^id(NSDictionary *dict, NSMutableDictionary *outputDict){
            return @YES;
        }},
        
        {@"no", ^id(NSDictionary *dict, NSMutableDictionary *outputDict){
            return @NO;
        }},
        
        {@"false", ^id(NSDictionary *dict, NSMutableDictionary *outputDict){
            return @NO;
        }},
        
        {@"null", ^id(NSDictionary *dict, NSMutableDictionary *outputDict){
            return nil;
        }},
        
        {@"nil", ^id(NSDictionary *dict, NSMutableDictionary *outputDict){
            return nil;
        }},
    };

    auto it = commands.find(name);
    if (it != commands.end()) {
        return it->second(dict, outputDict);
    }
    
    XILOG(@"Unknown element %@. %@", name, dict);
    
    return nil;
}

static id XLCCreateObjectFromDictionary(NSDictionary *dict, NSMutableDictionary *outputDict)
{
    if ([dict count] == 0) {
        return nil;
    }

    id obj = dict;

    NSString *name = dict[@"#name"];
    NSString *namespace_ = dict[@"#namespace"];
    NSArray *contents = dict[@"#contents"];

    if ([namespace_ length] == 0) { // empty namespace

        Class cls = NSClassFromString(name);
        if (cls) {
            if ([cls respondsToSelector:@selector(xlc_createWithXMLDictionary:)]) {
                obj = [cls xlc_createWithXMLDictionary:dict];
            } else {
                NSMutableArray *objectContents = [NSMutableArray array];
                for (id child in contents) {
                    id childObj = child;
                    if ([child isKindOfClass:[NSDictionary class]]) {
                        childObj = XLCCreateObjectFromDictionary(child, outputDict);
                    }
                    [objectContents addObject:childObj ?: [NSNull null]];
                }

                NSMutableDictionary *props = [dict mutableCopy];

                [dict enumerateKeysAndObjectsUsingBlock:^(id key, id child, BOOL *stop) {
                    if ([key isKindOfClass:[NSString class]] && ([key hasPrefix:XLCNamespaceURI] || [key hasPrefix:@"#"])) {
                        [props removeObjectForKey:key];
                    } else if ([child isKindOfClass:[NSDictionary class]]) {
                        props[key] = XLCCreateObjectFromDictionary(child, outputDict) ?: [NSNull null];
                    }
                }];
                
                XLCXMLObjectProperties *objectProps = [[XLCXMLObjectProperties alloc] initWithDictionary:props];
                if ([cls respondsToSelector:@selector(xlc_createWithProperties:andContents:)]) {
                    obj = [cls xlc_createWithProperties:objectProps andContents:objectContents];
                } else {
                    if (objectContents.count) {
                        XILOG(@"Element '%@' contains contents but ignored. Contents: %@", name, contents);
                    }
                    
                    obj = [[cls alloc] init];
                }
                
                if (obj) {
                    [[objectProps consumeAll] enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
                        XLCSetValueForKey(obj, value, key);
                    }];
                    
                } else {
                    XILOG(@"Unable to create object from class %@ with properties %@", cls, dict);
                }
                
            }

        }
    } else if ([namespace_ isEqualToString:XLCNamespaceURI]) {
        obj = XLCCreateNamespacedObject(dict, outputDict);
    }
    
    NSString *outputName = dict[XLCXMLAttributeName];
    if (outputName && obj) {
        outputDict[outputName] = obj;
    }

    return obj;

}

