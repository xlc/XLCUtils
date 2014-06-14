//
//  XLCPrototypeTests.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14/6/12.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XLCPrototype.h"

@interface XLCPrototypeTestsDummy : NSObject <NSCopying>

@property NSInteger intValue;
@property double doubleValue;
@property id objectValue;

@end

@implementation XLCPrototypeTestsDummy

- (id)copyWithZone:(NSZone *)zone
{
    XLCPrototypeTestsDummy *other = [[[self class] alloc] init];
    other.intValue = self.intValue;
    other.doubleValue = self.doubleValue;
    other.objectValue = self.objectValue;
    return other;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        XLCPrototypeTestsDummy *other = object;
        return
        other.intValue == self.intValue &&
        other.doubleValue == self.doubleValue &&
        other.objectValue == self.objectValue;
    }
    return NO;
}

@end

@interface XLCPrototypeTests : XCTestCase

@end

@implementation XLCPrototypeTests {
    NSMutableDictionary *_values;
    XLCPrototypeTestsDummy *_obj;
}

- (void)setUp
{
    [super setUp];
    
    _values = [NSMutableDictionary dictionary];
    _obj = [[XLCPrototypeTestsDummy alloc] init];
    _obj.intValue = 42;
    _obj.doubleValue = 12.5;
    _obj.objectValue = @"dummy";
    
    [XLCPrototype setPrototypeProvider:^NSDictionary *(NSString *name) {
        return _values[name];
    }];
}

- (void)tearDown
{
    [XLCPrototype setPrototypeProvider:nil];
    [XLCPrototype setUpdatePrototypeModifyExistingObjects:NO];
    [XLCPrototype removeAllPrototypes];
    
    [super tearDown];
}

- (void)testAssignDefaultPrototype
{
    id old = [_obj copy];
    _obj.xlc_prototype = [XLCPrototype prototypeForName:@"test"];
    XCTAssertEqualObjects(_obj, old, "assign default prototype should change nothing");
}

- (void)testAssignProvidedPrototype
{
    _values[@"test"] = @{@"intValue" : @23, @"objectValue" : @"object"};
    _values[@"othertest"] = @{@"doubleValue" : @5, @"objectValue" : @42};
    
    _obj.xlc_prototype = [XLCPrototype prototypeForName:@"test"];
    XCTAssertEqual(_obj.intValue, 23);
    XCTAssertEqualObjects(_obj.objectValue, @"object");
    
    _obj.xlc_prototype = nil;
    XCTAssertEqual(_obj.intValue, 23);
    XCTAssertEqualObjects(_obj.objectValue, @"object");
    
    _obj.xlc_prototype = [XLCPrototype prototypeForName:@"othertest"];
    XCTAssertEqual(_obj.doubleValue, 5);
    XCTAssertEqualObjects(_obj.objectValue, @42);
}

- (void)testNotUpdatePrototypeModifyExistingObjects
{
    [XLCPrototype setUpdatePrototypeModifyExistingObjects:NO];
    
    _obj.xlc_prototype = [XLCPrototype prototypeForName:@"test"];
    
    _obj.xlc_prototype[@"intValue"] = @1;
    
    XCTAssertEqual(_obj.intValue, 42);
    
    XLCPrototypeTestsDummy *obj2 = [[XLCPrototypeTestsDummy alloc] init];
    obj2.xlc_prototype = [XLCPrototype prototypeForName:@"test"];
    
    XCTAssertEqual(obj2.intValue, 1);
    
    _obj.xlc_prototype[@"intValue"] = @3;
    
    XCTAssertEqual(_obj.intValue, 42);
    XCTAssertEqual(obj2.intValue, 1);
}

- (void)testUpdatePrototypeModifyExistingObjects
{
    [XLCPrototype setUpdatePrototypeModifyExistingObjects:YES];
    
    _obj.xlc_prototype = [XLCPrototype prototypeForName:@"test"];
    
    _obj.xlc_prototype[@"intValue"] = @1;
    
    XCTAssertEqual(_obj.intValue, 1);
    
    XLCPrototypeTestsDummy *obj2 = [[XLCPrototypeTestsDummy alloc] init];
    obj2.xlc_prototype = [XLCPrototype prototypeForName:@"test"];
    
    XCTAssertEqual(obj2.intValue, 1);
    
    _obj.xlc_prototype[@"intValue"] = @3;
    
    XCTAssertEqual(_obj.intValue, 3);
    XCTAssertEqual(obj2.intValue, 3);
}

@end
