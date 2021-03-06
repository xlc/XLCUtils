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

#include <dlfcn.h>

#import "XLCUtilsLogPrivate.h"

#import "XLCAssertion.h"
#import "XLCXMLCreation.h"

static NSString * const XLCNamespaceURI = @"https://github.com/xlc/XLCUtils";
static NSString * const XLCKeyNamespaceURI = @"https://github.com/xlc/XLCUtils/key";
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
    NSUInteger _index;
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

    if (error) {
        *error = parser.parserError;
    }

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
    return [self createWithContextDictionary:nil];
}

- (id)createWithContextDictionary:(NSMutableDictionary *)dict;
{
    XLCAssertNotNull(_root);

    if (!dict) {
        dict = [NSMutableDictionary dictionary];
    }

    id result = XLCCreateObjectFromDictionary(_root, dict);
    return result == [NSNull null] ? nil : result;
}

#pragma mark - NSXMLParserDelegate

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    _parent.push([NSMutableArray array]);
    _index = 0;
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
            
            NSString *attName;
            
            if ([childName hasPrefix:prefix] && [ns isEqualToString:childNs]) {
                attName = [childName substringFromIndex:prefix.length];
            } else if ([childNs isEqualToString:XLCKeyNamespaceURI]) {
                attName = childName;
            }
            
            if (attName) {
                NSMutableArray *contents = child[@"#contents"];
                switch (contents.count) {
                    case 0:
                        dict[attName] = [NSNull null];
                        break;
                        
                    default:
                        XLCUtilsLogInfo(@"Element property contains more than one object, only first one used. %@", child);
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
    dict[@"#index"] = @(_index++);

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

static void XLCSetValueForKey(id obj, id value, id key, BOOL useKeyPath)
{
    value = value == [NSNull null] ? nil : value;
    @try {
        if (useKeyPath) {
            [obj setValue:value forKeyPath:key];
        } else {
            [obj setValue:value forKey:key];
        }
        
    }
    @catch (NSException *exception) {
        BOOL handled = NO;

        if ([[exception name] isEqualToString:NSUndefinedKeyException]) {

            NSDictionary *info = [exception userInfo];
            NSString *key = info[@"NSUnknownUserInfoKey"];

            XLCUtilsLogInfo(@"Unable to set value '%@' for key path '%@' on object '%@'", value, key, obj);

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

                    if (useKeyPath) {
                        [obj setValue:value forKeyPath:key];
                    } else {
                        [obj setValue:value forKey:key];
                    }

                    handled = YES;
                }
            }

        }

        if (!handled) { // not expecting it, rethrow
            @throw;
        }
    }
}

static NSDictionary * XLCEvaluateDictionary(NSDictionary *dict, NSMutableDictionary *outputDict)
{
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:dict.count];
    
    NSArray *contents = dict[@"#contents"];
    NSMutableArray *newcontents = [NSMutableArray arrayWithCapacity:contents.count];
    
    std::deque<std::tuple<int, id, id>> items;
    
    for (id key in [dict allKeys]) {
        id val = dict[key];
        NSInteger index = -1;
        if ([val isKindOfClass:[NSDictionary class]]) {
            index = [val[@"#index"] integerValue];
        }
        items.emplace_back(index, key, dict[key]);
    }
    
    NSInteger prevIndex = -1;
    for (id val in contents) {
        if ([val isKindOfClass:[NSDictionary class]]) {
            prevIndex = [val[@"#index"] integerValue];
        }
        items.emplace_back(prevIndex, (id)nil, val);
    }
    
    std::stable_sort(items.begin(), items.end(), [](std::tuple<int, id, id> const &p1, std::tuple<int, id, id> const &p2) {
        return std::get<0>(p1) < std::get<0>(p2);
    });
    
    for (auto &tuple : items)
    {
        id key = std::get<1>(tuple);
        id child = std::get<2>(tuple);
        id newchild = child;
        if ([key isKindOfClass:[NSString class]] && ([key hasPrefix:XLCNamespaceURI] || [key hasPrefix:@"#"])) {
            newchild = nil;
        } else if ([child isKindOfClass:[NSDictionary class]]) {
            if ([child[@"#name"] caseInsensitiveCompare:@"postaction"] == NSOrderedSame) {
                XLCUtilsLogInfo(@"object ignored: %@", child);
            } else {
                newchild = XLCCreateObjectFromDictionary(child, outputDict);
                if (key && !newchild) {
                    newchild = [NSNull null];
                }
            }
        }
        if (newchild) {
            if (key) {
                result[key] = newchild;
            } else {
                [newcontents addObject:newchild];
            }
        }
    }
    
    if (newcontents.count) {
        result[@"#contents"] = newcontents;
    } else {
        [result removeObjectForKey:@"#contents"];
    }
    
    return result;
}

static id XLCCreateNamespacedObject(NSDictionary *dict, NSMutableDictionary *outputDict)
{
    XLCAssertDebug([dict[@"#namespace"] isEqualToString:XLCNamespaceURI]);
    
    NSString *name = [dict[@"#name"] lowercaseString];
    
    using CommandBlock = id (^)(NSDictionary *dict, NSMutableDictionary *outputDict);
    static std::unordered_map<NSString *, CommandBlock, XLCNSStringHash, XLCNSStringCompare> commands
    {
        {@"ref", ^id(NSDictionary *dict, NSMutableDictionary *outputDict){
            return outputDict[dict[@"name"] ?: @""] ?: [NSNull null];
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
            return [NSNull null];
        }},
        
        {@"nil", ^id(NSDictionary *dict, NSMutableDictionary *outputDict){
            return [NSNull null];
        }},
        
        {@"void", ^id(NSDictionary *dict, NSMutableDictionary *outputDict){
            XLCEvaluateDictionary(dict, outputDict);
            return nil;
        }},
        
        {@"set", ^id(NSDictionary *dict, NSMutableDictionary *outputDict){
            dict = XLCEvaluateDictionary(dict, outputDict);
            id obj = dict[@"object"];
            if (!obj) {
                obj = outputDict[@"#self"]; // in post action
            } else if ([obj isKindOfClass:[NSString class]]) {
                obj = outputDict[obj];
            }
            if (obj && obj != [NSNull null]) {
                id value = dict[@"value"];
                if (!value) {
                    NSArray *content = dict[@"#contents"];
                    if ([content count]) {
                        value = content[0];
                    }
                }
                NSString *key = dict[@"key"];
                NSString *keyPath = dict[@"keyPath"];
                if (key) {
                    XLCSetValueForKey(obj, value, key, NO);
                } else if (keyPath) {
                    XLCSetValueForKey(obj, value, keyPath, YES);
                }
            }
            
            return nil;
        }},
        
        {@"get", ^id(NSDictionary *dict, NSMutableDictionary *outputDict){
            dict = XLCEvaluateDictionary(dict, outputDict);
            id obj = dict[@"object"];
            if (!obj) {
                obj = outputDict[@"#self"]; // in post action
            } else if ([obj isKindOfClass:[NSString class]]) {
                obj = outputDict[obj];
            }
            if (obj && obj != [NSNull null]) {
                NSString *key = dict[@"key"];
                NSString *keyPath = dict[@"keyPath"];
                if (key) {
                    return [obj valueForKey:key];
                } else if (keyPath) {
                    return [obj valueForKeyPath:keyPath];
                }
            }
            
            return [NSNull null];
        }},
        
        {@"symbol", ^id(NSDictionary *dict, NSMutableDictionary *outputDict){
            NSString *name = dict[@"name"];
            if ([name length]) {
                __strong id *ptr = (__strong id *)dlsym(RTLD_DEFAULT, [name UTF8String]);
                if (ptr) {
                    return *ptr;
                }
            }
            
            return nil;
        }},
    };

    auto it = commands.find(name);
    if (it != commands.end()) {
        return it->second(dict, outputDict);
    }
    
    XLCUtilsLogInfo(@"Unknown element '%@'. %@", name, dict);
    
    return nil;
}

static id XLCCreateObjectFromDictionary(NSDictionary *dict, NSMutableDictionary *outputDict)
{
    if ([dict count] == 0) {
        return nil;
    }

    id obj;

    NSString *name = dict[@"#name"];
    NSString *namespace_ = dict[@"#namespace"];
    NSArray *contents = dict[@"#contents"];

    if ([namespace_ length] == 0) { // empty namespace

        Class cls = NSClassFromString(name);
        if (cls) {
            if ([cls respondsToSelector:@selector(xlc_createWithXMLDictionary:)]) {
                obj = [cls xlc_createWithXMLDictionary:dict] ?: [NSNull null];
            } else {
                
                NSMutableArray *postactions = [NSMutableArray array];
                
                NSMutableArray *objectContents = [NSMutableArray array];
                NSMutableDictionary *props = [NSMutableDictionary dictionaryWithCapacity:dict.count];
                
                std::deque<std::tuple<int, id, id>> items;
                
                for (id key in [dict allKeys]) {
                    id val = dict[key];
                    NSInteger index = -1;
                    if ([val isKindOfClass:[NSDictionary class]]) {
                        index = [val[@"#index"] integerValue];
                    }
                    items.emplace_back(index, key, dict[key]);
                }
                
                NSInteger prevIndex = -1;
                for (id val in contents) {
                    if ([val isKindOfClass:[NSDictionary class]]) {
                        prevIndex = [val[@"#index"] integerValue];
                    }
                    items.emplace_back(prevIndex, (id)nil, val);
                }
                
                std::stable_sort(items.begin(), items.end(), [](std::tuple<int, id, id> const &p1, std::tuple<int, id, id> const &p2) {
                    return std::get<0>(p1) < std::get<0>(p2);
                });
                
                for (auto &tuple : items)
                {
                    id key = std::get<1>(tuple);
                    id child = std::get<2>(tuple);
                    id newchild = child;
                    if ([key isKindOfClass:[NSString class]] && ([key hasPrefix:XLCNamespaceURI] || [key hasPrefix:@"#"])) {
                        newchild = nil;
                    } else if ([child isKindOfClass:[NSDictionary class]]) {
                        if ([child[@"#name"] caseInsensitiveCompare:@"postaction"] == NSOrderedSame) {
                            [postactions addObjectsFromArray:child[@"#contents"]];
                        } else {
                            newchild = XLCCreateObjectFromDictionary(child, outputDict);
                            if (key && !newchild) {
                                newchild = [NSNull null];
                            }
                        }
                    }
                    if (newchild) {
                        if (key) {
                            props[key] = newchild;
                        } else {
                            [objectContents addObject:newchild];
                        }
                    }
                }
                
                XLCXMLObjectProperties *objectProps = [[XLCXMLObjectProperties alloc] initWithDictionary:props];
                if ([cls respondsToSelector:@selector(xlc_createWithProperties:andContents:)]) {
                    obj = [cls xlc_createWithProperties:objectProps andContents:objectContents];
                } else {
                    if (objectContents.count) {
                        XLCUtilsLogInfo(@"Element '%@' contains contents but ignored. Contents: %@", name, contents);
                    }
                    
                    obj = [[cls alloc] init];
                }
                
                if (obj) {
                    [[objectProps consumeAll] enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
                        XLCSetValueForKey(obj, value, key, YES);
                    }];
                    
                    NSString *outputName = dict[XLCXMLAttributeName];
                    if (outputName && obj) {
                        outputDict[outputName] = obj;
                    }
                    
                    id oldself = outputDict[@"#self"];
                    outputDict[@"#self"] = obj;
                    for (id child in postactions) {
                        if ([child isKindOfClass:[NSDictionary class]]) {
                            XLCCreateObjectFromDictionary(child, outputDict);
                        }
                    }
                    if (oldself) {
                        outputDict[@"#self"] = oldself;
                    } else {
                        [outputDict removeObjectForKey:@"#self"];
                    }
                    
                } else {
                    XLCUtilsLogInfo(@"Unable to create object from class %@ with properties %@", cls, dict);
                    obj = [NSNull null];
                }
                
            }

        } else {
            XLCUtilsLogInfo(@"Class '%@' not found", name);
        }
        
    } else if ([namespace_ isEqualToString:XLCNamespaceURI]) {
        obj = XLCCreateNamespacedObject(dict, outputDict);
        NSString *outputName = dict[XLCXMLAttributeName];
        if (outputName && obj) {
            outputDict[outputName] = obj;
        }
    }

    return obj;

}

