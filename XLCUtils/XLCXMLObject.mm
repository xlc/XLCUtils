//
//  XLCXMLObject.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14-3-30.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import "XLCXMLObject.h"

#import "XLCLogging.h"
#import "XLCAssertion.h"

#include <unordered_map>
#include <stack>

static NSString * const XLCNamespaceURI = @"https://github.com/xlc/XLCUtils";

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

@interface XLCXMLObject () <NSXMLParserDelegate>

- (instancetype)initWithXMLParser:(NSXMLParser *)parser;

@end

@implementation XLCXMLObject {
    NSXMLParser *_parser;
    
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
    XLCXMLObject *obj = [[self alloc] initWithXMLParser:parser];
    
    parser.shouldProcessNamespaces = YES;
    parser.shouldReportNamespacePrefixes = YES;
    
    if ([parser parse]) {
        return obj;
    }
    
    *error = parser.parserError;
    
    return nil;
}

- (instancetype)initWithXMLParser:(NSXMLParser *)parser
{
    self = [super init];
    if (self) {
        _parser = parser;
        _parser.delegate = self;
    }
    return self;
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
    
    return dict;
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
                        XILOG(@"Empty element property. %@", child);
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
