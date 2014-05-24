//
//  XLCAppKitXMLCreationTests.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14-4-20.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <Cocoa/Cocoa.h>

#import "XLCXMLObject.h"

@interface XLCAppKitXMLCreationTests : XCTestCase

@end

@implementation XLCAppKitXMLCreationTests

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

- (void)testCreateNSView
{
    NSString *xml =
    @"<NSSplitView>"
        "<NSView>"
            "<NSTextView />"
        "</NSView>"
        "<NSTextField />"
    "</NSSplitView>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];
    
    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");
    
    NSSplitView *result = [obj create];
    XCTAssert([result isKindOfClass:[NSSplitView class]]);
    
    NSView *view = result.subviews[0];
    XCTAssert([view isKindOfClass:[NSView class]]);
    
    NSTextView *textView = view.subviews[0];
    XCTAssert([textView isKindOfClass:[NSTextView class]]);
    
    NSTextField *textField = result.subviews[1];
    XCTAssert([textField isKindOfClass:[NSTextField class]]);
}

- (void)testCreateNSFontDefaultFont
{
    NSString *xml = @"<NSFont />";
    NSFont *font = [self createFromXML:xml];
    XCTAssertEqualObjects(font, [NSFont systemFontOfSize:[NSFont systemFontSize]]);
}

- (void)testCreateNSFontWithName
{
    {
        NSString *xml = @"<NSFont name='Menlo' />";
        NSFont *font = [self createFromXML:xml];
        XCTAssertEqualObjects(font, [NSFont fontWithName:@"Menlo" size:[NSFont systemFontSize]]);
    }
    
    {
        NSString *xml = @"<NSFont family='Menlo' />";
        NSFont *font = [self createFromXML:xml];
        XCTAssertEqualObjects(font, [NSFont fontWithName:@"Menlo" size:[NSFont systemFontSize]]);
    }
}

- (void)testCreateNSFontWithSize
{
    NSString *xml = @"<NSFont size='20.5' />";
    NSFont *font = [self createFromXML:xml];
    XCTAssertEqualObjects(font, [NSFont systemFontOfSize:20.5]);
}

- (void)testCreateNSFontWithWeight
{
    NSString *xml = @"<NSFont weight='15' />";
    NSFont *font = [self createFromXML:xml];
    XCTAssertEqualObjects(font, [[NSFontManager sharedFontManager] convertFont:[NSFont systemFontOfSize:[NSFont systemFontSize]] toHaveTrait:NSBoldFontMask]);
}

- (void)testCreateNSFontWithBold
{
    NSString *xml = @"<NSFont bold='YES' />";
    NSFont *font = [self createFromXML:xml];
    XCTAssertEqualObjects(font, [NSFont boldSystemFontOfSize:[NSFont systemFontSize]]);
}

- (void)testCreateNSFontWithItalic
{
    NSString *xml = @"<NSFont name='Menlo' italic='YES' />";
    NSFont *font = [self createFromXML:xml];
    XCTAssertEqualObjects(font, [[NSFontManager sharedFontManager] convertFont:[NSFont fontWithName:@"Menlo" size:[NSFont systemFontSize]] toHaveTrait:NSItalicFontMask]);
}

- (void)testCreateNSColorRGB
{
    {
        NSString *xml = @"<NSColor red='0.5' />";
        id color = [self createFromXML:xml];
        XCTAssertEqualObjects(color, [NSColor colorWithCalibratedRed:0.5 green:0 blue:0 alpha:1]);
    }
    
    {
        NSString *xml = @"<NSColor green='0.4' />";
        id color = [self createFromXML:xml];
        XCTAssertEqualObjects(color, [NSColor colorWithCalibratedRed:0 green:0.4 blue:0 alpha:1]);
    }
    
    {
        NSString *xml = @"<NSColor blue='0.3' />";
        id color = [self createFromXML:xml];
        XCTAssertEqualObjects(color, [NSColor colorWithCalibratedRed:0 green:0 blue:0.3 alpha:1]);
    }
    
    {
        NSString *xml = @"<NSColor red='0.1' blue='1' green='0.2' alpha='0.7' />";
        id color = [self createFromXML:xml];
        XCTAssertEqualObjects(color, [NSColor colorWithCalibratedRed:0.1 green:0.2 blue:1 alpha:0.7]);
    }
}

- (void)testCreateNSColorHSB
{
    NSString *xml = @"<NSColor hue='0.1' saturation='0.2' brightness='0.3' alpha='0.4' />";
    id color = [self createFromXML:xml];
    XCTAssertEqualObjects(color, [NSColor colorWithCalibratedHue:0.1f saturation:0.2f brightness:0.3f alpha:0.4f]);
}

- (void)testCreateNSColorWhite
{
    NSString *xml = @"<NSColor white='0.2' alpha='0.4' />";
    id color = [self createFromXML:xml];
    XCTAssertEqualObjects(color, [NSColor colorWithCalibratedWhite:0.2 alpha:0.4]);
}

- (void)testCreateNSColorName
{
    {
        NSString *xml = @"<NSColor name='purple' />";
        id color = [self createFromXML:xml];
        XCTAssertEqualObjects(color, [NSColor purpleColor]);
    }

    {
        NSString *xml = @"<NSColor name='text' />";
        id color = [self createFromXML:xml];
        XCTAssertEqualObjects(color, [NSColor textColor]);
    }
}

- (void)testCreateNSColorValue
{
    NSString *xml = @"<NSColor value='#123456' />";
    id color = [self createFromXML:xml];
    float ff = 0xFF;
    XCTAssertEqualObjects(color, [NSColor colorWithCalibratedRed:0x12/ff green:0x34/ff blue:0x56/ff alpha:1]);
}

@end
