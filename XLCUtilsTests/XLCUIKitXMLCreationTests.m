//
//  XLCUIKitXMLCreationTests.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14-5-25.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XLCXMLObject.h"

@interface XLCUIKitXMLCreationTests : XCTestCase

@end

@implementation XLCUIKitXMLCreationTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (id)createFromXML:(NSString *)xml
{
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];
    
    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");
    
    return [obj create];
}

- (void)testCreateUIColorRGB
{
    {
        NSString *xml = @"<UIColor red='0.5' />";
        id color = [self createFromXML:xml];
        XCTAssertEqualObjects(color, [[UIColor alloc] initWithRed:0.5 green:0 blue:0 alpha:1]);
    }
    
    {
        NSString *xml = @"<UIColor green='0.4' />";
        id color = [self createFromXML:xml];
        XCTAssertEqualObjects(color, [[UIColor alloc] initWithRed:0 green:0.4 blue:0 alpha:1]);
    }
    
    {
        NSString *xml = @"<UIColor blue='0.3' />";
        id color = [self createFromXML:xml];
        XCTAssertEqualObjects(color, [[UIColor alloc] initWithRed:0 green:0 blue:0.3 alpha:1]);
    }
    
    {
        NSString *xml = @"<UIColor red='0.1' blue='1' green='0.2' alpha='0.7' />";
        id color = [self createFromXML:xml];
        XCTAssertEqualObjects(color, [[UIColor alloc] initWithRed:0.1 green:0.2 blue:1 alpha:0.7]);
    }
}

- (void)testCreateUIColorHSB
{
    NSString *xml = @"<UIColor hue='0.1' saturation='0.2' brightness='0.3' alpha='0.4' />";
    id color = [self createFromXML:xml];
    XCTAssertEqualObjects(color, [[UIColor alloc] initWithHue:0.1f saturation:0.2f brightness:0.3f alpha:0.4f]);
}

- (void)testCreateUIColorWhite
{
    NSString *xml = @"<UIColor white='0.2' alpha='0.4' />";
    id color = [self createFromXML:xml];
    XCTAssertEqualObjects(color, [[UIColor alloc] initWithWhite:0.2 alpha:0.4]);
}

- (void)testCreateUIColorName
{
    {
        NSString *xml = @"<UIColor name='purple' />";
        id color = [self createFromXML:xml];
        XCTAssertEqualObjects(color, [UIColor purpleColor]);
    }
    
    {
        NSString *xml = @"<UIColor name='clear' />";
        id color = [self createFromXML:xml];
        XCTAssertEqualObjects(color, [UIColor clearColor]);
    }
}

- (void)testCreateUIColorValue
{
    NSString *xml = @"<UIColor value='#123456' />";
    id color = [self createFromXML:xml];
    float ff = 0xFF;
    XCTAssertEqualObjects(color, [[UIColor alloc] initWithRed:0x12/ff green:0x34/ff blue:0x56/ff alpha:1]);
}

@end
