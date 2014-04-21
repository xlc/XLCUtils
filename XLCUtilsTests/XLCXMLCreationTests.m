//
//  XLCXMLCreationTests.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14-4-20.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <Cocoa/Cocoa.h>

#import "XLCXMLObject.h"

@interface XLCXMLCreationTests : XCTestCase

@end

@implementation XLCXMLCreationTests

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

@end
