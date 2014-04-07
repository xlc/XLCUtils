//
//  XLCXMLObjectTests.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14-3-30.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XLCXMLObject.h"

@interface XLCXMLObjectTests : XCTestCase

@end

@implementation XLCXMLObjectTests

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

- (void)testParseXML
{
    NSString *xml = @(R"(
    <!-- comment -->
    <test xmlns:x='https://github.com/xlc/XLCUtils'
        xmlns:y='https://github.com/xlc'
        >
        something!!
        <x:t2 x:t3='t4' y:t3='t5' t3='t6'/> <!-- comment -->
        <foo xmlns='https://example.com'> <!-- comment -->
            <x:bar a='b' x:a='c' />
            <bar />
            <foo.bar value='42'/>
            <y:foo x:bar='b'>
                lol
            </y:foo>
        </foo>
        <bar />
        this is some string in xml file.
    </test>
    <!-- comment -->
    )");
    
    NSDictionary *expected =
    @{
      @"#name" : @"test",
      @"#namespace" : @"",
      @"#contents" :
          @[
              @"something!!",
              @{
                  @"#name" : @"t2",
                  @"#namespace" : @"https://github.com/xlc/XLCUtils",
                  @"https://github.com/xlc/XLCUtils:t3" : @"t4",
                  @"https://github.com/xlc:t3" : @"t5",
                  @"t3" : @"t6"
                  },
              @{
                  @"#name" : @"foo",
                  @"#namespace" : @"https://example.com",
                  @"#contents" :
                      @[
                          @{
                              @"#name": @"bar",
                              @"#namespace" : @"https://github.com/xlc/XLCUtils",
                              @"a" : @"b",
                              @"https://github.com/xlc/XLCUtils:a" : @"c"
                              },
                          @{
                              @"#name" : @"bar",
                              @"#namespace" : @"https://example.com"
                              },
                          @{
                              @"#name" : @"foo.bar",
                              @"#namespace" : @"https://example.com",
                              @"value" : @"42"
                              },
                          @{
                              @"#name" : @"foo",
                              @"#namespace" : @"https://github.com/xlc",
                              @"https://github.com/xlc/XLCUtils:bar" : @"b",
                              @"#contents" : @[@"lol"]
                              }
                          ]
                  },
              @{
                  @"#name" : @"bar",
                  @"#namespace" : @""
                  },
              @"this is some string in xml file."
              ]
      };
    
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];
    
    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");
    XCTAssertEqualObjects(obj.root, expected);
    
}

- (void)testParseXMLMergeAttribute
{
    NSString *xml = @(R"(
    <test attr='42'>
        <test.value>
            <object />
            <object.attr> <!-- second element ignored -->
                <test/>
            </object.attr>
        </test.value>
        <test.empty /> <!-- empty element ignored -->
        <test.otherValue>
            some string
        </test.otherValue>
        <abc />
        <obj string='text string'>
            <obj.text>string text</obj.text>
            <obj.someValue>
                <obj>
                    <obj.someValue>
                        <test test='42'/>
                    </obj.someValue>
                </obj>
            </obj.someValue>
        </obj>
    </test>
    )");
    
    NSDictionary *expected =
    @{
      @"#name" : @"test",
      @"#namespace" : @"",
      @"attr" : @"42",
      @"value" : @{
              @"#name" : @"object",
              @"#namespace" : @""
              },
      @"otherValue" : @"some string",
      @"#contents" :
          @[
              @{
                  @"#name" : @"abc",
                  @"#namespace" : @""
                  },
              @{
                  @"#name" : @"obj",
                  @"#namespace" : @"",
                  @"string" : @"text string",
                  @"text" : @"string text",
                  @"someValue" :
                      @{
                          @"#name" : @"obj",
                          @"#namespace" : @"",
                          @"someValue" :
                              @{
                                  @"#name" : @"test",
                                  @"#namespace" : @"",
                                  @"test" : @"42"
                                  }
                          }
                  }
              ]
      };
    
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];
    
    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");
    XCTAssertEqualObjects(obj.root, expected);
    
}

@end
