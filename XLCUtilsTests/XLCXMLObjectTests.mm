
//  XLCXMLObjectTests.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14-3-30.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "XLCXMLObject.h"

@interface XLCXMLObjectTestDummy : NSObject

@property NSString *stringValue;
@property BOOL boolValue;
@property id objectValue;
@property int intValue;
@property unsigned unsignedValue;
@property long long longlongValue;
@property float floatValue;
@property double doubleValue;
@property CGPoint pointValue;
@property CGRect rectValue;
@property CGSize sizeValue;

@end

@implementation XLCXMLObjectTestDummy @end

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
            <bar value='42'/>
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
                              @"#name" : @"bar",
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
        <test.empty />
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
      @"empty" : [NSNull null],
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

- (void)testCreateNSObject
{
    NSString *xml = @"<NSObject />";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    id result = [obj create];
    XCTAssert([result isMemberOfClass:[NSObject class]], "is NSObject");
}

- (void)testCreateArray
{
    NSString *xml = @"<NSArray> some string <NSString /> <NSNumber /> <NSNull /> 42 </NSArray>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    id result = [obj create];
    XCTAssertEqualObjects(result, (@[@"some string", @"", @0, [NSNull null], @"42"]));
}

- (void)testCreateDictionary
{
    NSString *xml =
    @"<NSDictionary key='val' otherKey='val2'>"
        "<NSDictionary.specialKey><NSArray /></NSDictionary.specialKey>"
        "<NSDictionary.empty />"
    "</NSDictionary>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    id result = [obj create];
    XCTAssertEqualObjects(result, (@{@"key":@"val", @"otherKey":@"val2", @"specialKey":@[], @"empty":[NSNull null]}));
}

- (void)testCreateXLCXMLObject
{
    NSString *xml =
    @"<XLCXMLObject>"
        "<NSDictionary key='val' otherKey='val2'>"
            "<NSDictionary.specialKey><NSArray /></NSDictionary.specialKey>"
            "<NSDictionary.empty />"
        "</NSDictionary>"
    "</XLCXMLObject>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    XLCXMLObject *result = [obj create];
    XCTAssert([result isKindOfClass:[XLCXMLObject class]]);

    id result2 = [result create];
    XCTAssertEqualObjects(result2, (@{@"key":@"val", @"otherKey":@"val2", @"specialKey":@[], @"empty":[NSNull null]}));
}

- (void)testCreateNSNumberEmpty
{
    NSString *xml = @"<NSNumber />";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    id result = [obj create];
    XCTAssertEqualObjects(result, @0);
}

- (void)testCreateNSNumberWithContent
{
    NSString *xml = @"<NSNumber>42.5</NSNumber>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    id result = [obj create];
    XCTAssertEqualObjects(result, @42.5);
}

- (void)testCreateNSNumberWithAttritube
{
    NSString *xml = @"<NSNumber value='123'/>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    id result = [obj create];
    XCTAssertEqualObjects(result, @123);
}

- (void)testCreateNSNumberWithYES
{
    NSString *xml = @"<NSNumber value='YES'/>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    id result = [obj create];
    XCTAssertEqualObjects(result, @YES);
}

- (void)testCreateNSNumberWithNO
{
    NSString *xml = @"<NSNumber value='NO'/>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    id result = [obj create];
    XCTAssertEqualObjects(result, @NO);
}

- (void)testCreateNSNumberWithTrue
{
    NSString *xml = @"<NSNumber value='true'/>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    id result = [obj create];
    XCTAssertEqualObjects(result, @YES);
}

- (void)testCreateNSNumberWithFalse
{
    NSString *xml = @"<NSNumber value='false'/>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    id result = [obj create];
    XCTAssertEqualObjects(result, @NO);
}

- (void)testCreateNSString
{
    NSString *xml = @"<NSString value=' some string '/>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    id result = [obj create];
    XCTAssertEqualObjects(result, @" some string ");
}

- (void)testCreateWithString
{
    NSString *xml = @"<XLCXMLObjectTestDummy stringValue='some string' />";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    XLCXMLObjectTestDummy *result = [obj create];
    XCTAssert([result isKindOfClass:[XLCXMLObjectTestDummy class]]);
    XCTAssertEqualObjects(result.stringValue, @"some string");
}

- (void)testCreateWithObject
{
    NSString *xml = @"<XLCXMLObjectTestDummy><XLCXMLObjectTestDummy.objectValue><NSArray /></XLCXMLObjectTestDummy.objectValue></XLCXMLObjectTestDummy>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    XLCXMLObjectTestDummy *result = [obj create];
    XCTAssert([result isKindOfClass:[XLCXMLObjectTestDummy class]]);
    XCTAssertEqualObjects(result.objectValue, @[]);
}

- (void)testCreateWithObjectNil
{
    NSString *xml = @"<XLCXMLObjectTestDummy><XLCXMLObjectTestDummy.objectValue><NSNull /></XLCXMLObjectTestDummy.objectValue></XLCXMLObjectTestDummy>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    XLCXMLObjectTestDummy *result = [obj create];
    XCTAssert([result isKindOfClass:[XLCXMLObjectTestDummy class]]);
    XCTAssertNil(result.objectValue);
}

- (void)testCreateWithPrimitiveTypeBool
{
    NSString *xml = @"<XLCXMLObjectTestDummy boolValue='YES'/>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    XLCXMLObjectTestDummy *result = [obj create];
    XCTAssert([result isKindOfClass:[XLCXMLObjectTestDummy class]]);
    XCTAssertEqual(result.boolValue, YES);
}

- (void)testCreateWithPrimitiveTypeInt
{
    NSString *xml = @"<XLCXMLObjectTestDummy intValue='-23'/>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    XLCXMLObjectTestDummy *result = [obj create];
    XCTAssert([result isKindOfClass:[XLCXMLObjectTestDummy class]]);
    XCTAssertEqual(result.intValue, -23);
}

- (void)testCreateWithPrimitiveTypeDouble
{
    NSString *xml = @"<XLCXMLObjectTestDummy doubleValue='12.5' />";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    XLCXMLObjectTestDummy *result = [obj create];
    XCTAssert([result isKindOfClass:[XLCXMLObjectTestDummy class]]);
    XCTAssertEqual(result.doubleValue, 12.5);
}

- (void)testCreateWithPrimitiveTypeFloat
{
    NSString *xml = @"<XLCXMLObjectTestDummy floatValue='22.5' />";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    XLCXMLObjectTestDummy *result = [obj create];
    XCTAssert([result isKindOfClass:[XLCXMLObjectTestDummy class]]);
    XCTAssertEqual(result.floatValue, 22.5);
}

- (void)testCreateWithPrimitiveTypeUnsigned
{
    NSString *xml = @"<XLCXMLObjectTestDummy unsignedValue='42' />";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    XLCXMLObjectTestDummy *result = [obj create];
    XCTAssert([result isKindOfClass:[XLCXMLObjectTestDummy class]]);
    XCTAssertEqual(result.unsignedValue, 42);
}

- (void)testCreateWithPrimitiveTypeLongLong
{
    NSString *xml = @"<XLCXMLObjectTestDummy longlongValue='9223372036854775807' />";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    XLCXMLObjectTestDummy *result = [obj create];
    XCTAssert([result isKindOfClass:[XLCXMLObjectTestDummy class]]);
    XCTAssertEqual(result.longlongValue, 9223372036854775807LL);
}

- (void)testCreateWithStructTypeCGPoint
{
    NSString *xml = @"<XLCXMLObjectTestDummy pointValue='{1.5, 2.25}' />";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    XLCXMLObjectTestDummy *result = [obj create];
    XCTAssert([result isKindOfClass:[XLCXMLObjectTestDummy class]]);
    XCTAssertEqual(result.pointValue.x, 1.5);
    XCTAssertEqual(result.pointValue.y, 2.25);
}

- (void)testCreateWithStructTypeCGSize
{
    NSString *xml = @"<XLCXMLObjectTestDummy sizeValue='{1.5, 2.25}' />";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    XLCXMLObjectTestDummy *result = [obj create];
    XCTAssert([result isKindOfClass:[XLCXMLObjectTestDummy class]]);
    XCTAssertEqual(result.sizeValue.width, 1.5);
    XCTAssertEqual(result.sizeValue.height, 2.25);
}

- (void)testCreateWithStructTypeCGRect
{
    NSString *xml = @"<XLCXMLObjectTestDummy rectValue='{{1.5, 2.25}, {3, 4.5}}' />";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    XLCXMLObjectTestDummy *result = [obj create];
    XCTAssert([result isKindOfClass:[XLCXMLObjectTestDummy class]]);
    XCTAssertEqual(result.rectValue.origin.x, 1.5);
    XCTAssertEqual(result.rectValue.origin.y, 2.25);
    XCTAssertEqual(result.rectValue.size.width, 3);
    XCTAssertEqual(result.rectValue.size.height, 4.5);
}

- (void)testCreateWithOutput
{
    NSString *xml = @"<NSArray xmlns:x='https://github.com/xlc/XLCUtils' x:name='array'>"
    "<NSString x:name='string' value='nsstring' /> <NSNumber /> <NSArray>  <NSNumber value='42.5' x:name='number' /> </NSArray>"
    "</NSArray>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    NSDictionary *dict;
    [obj createWithOutputDictionary:&dict];

    XCTAssertEqualObjects(dict, (@{ @"string" : @"nsstring", @"number" : @42.5, @"array" : @[@"nsstring", @0, @[@42.5]] }));
}

- (void)testCreateWithRef
{
    NSString *xml =
    @"<NSArray xmlns:x='https://github.com/xlc/XLCUtils'>"
        "<NSNumber x:name='number' value='42' />"
        "<XLCXMLObjectTestDummy>"
            "<XLCXMLObjectTestDummy.objectValue>"
                "<XLCXMLObjectTestDummy>"
                    "<XLCXMLObjectTestDummy.stringValue>"
                        "<NSString value='some string' x:name='str' />"
                    "</XLCXMLObjectTestDummy.stringValue>"
                    "<XLCXMLObjectTestDummy.objectValue>"
                        "<x:Ref name='number' />"
                    "</XLCXMLObjectTestDummy.objectValue>"
                "</XLCXMLObjectTestDummy>"
            "</XLCXMLObjectTestDummy.objectValue>"
            "<XLCXMLObjectTestDummy.stringValue>"
                "<x:Ref name='str' />"
            "</XLCXMLObjectTestDummy.stringValue>"
        "</XLCXMLObjectTestDummy>"
    "</NSArray>";
;
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];
    XCTAssertNil(error, "no error");

    XLCXMLObjectTestDummy *result = [obj create][1];
    XLCXMLObjectTestDummy *result2 = result.objectValue;
    XCTAssertEqualObjects(result.stringValue, @"some string");
    XCTAssertEqualObjects(result2.objectValue, @42);
}

- (void)testCreateYES
{
    NSString *xml = @"<x:YES xmlns:x='https://github.com/xlc/XLCUtils' />";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    id result = [obj create];
    XCTAssertEqualObjects(result, @YES);
}

- (void)testCreateNO
{
    NSString *xml = @"<x:NO xmlns:x='https://github.com/xlc/XLCUtils' />";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    id result = [obj create];
    XCTAssertEqualObjects(result, @NO);
}

- (void)testCreateTrue
{
    NSString *xml = @"<x:true xmlns:x='https://github.com/xlc/XLCUtils' />";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    id result = [obj create];
    XCTAssertEqualObjects(result, @YES);
}

- (void)testCreateFalse
{
    NSString *xml = @"<x:false xmlns:x='https://github.com/xlc/XLCUtils' />";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    id result = [obj create];
    XCTAssertEqualObjects(result, @NO);
}

- (void)testCreateNil
{
    NSString *xml =
    @"<NSArray xmlns:x='https://github.com/xlc/XLCUtils'>"
        "<x:nil />"
    "</NSArray>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    id result = [obj create];
    XCTAssertEqualObjects(result, @[[NSNull null]]);
}

- (void)testCreateNull
{
    NSString *xml =
    @"<NSArray xmlns:x='https://github.com/xlc/XLCUtils'>"
        "<x:null />"
    "</NSArray>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    id result = [obj create];
    XCTAssertEqualObjects(result, @[[NSNull null]]);
}

- (void)testVoid
{
    NSString *xml =
    @"<NSArray xmlns:x='https://github.com/xlc/XLCUtils'>"
        "<x:void>"
            "<NSNumber value='42' x:name='num' />"
        "</x:void>"
    "</NSArray>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    NSDictionary *output;
    id result = [obj createWithOutputDictionary:&output];
    XCTAssertEqualObjects(result, @[], "should not add NSNull");
    XCTAssertEqualObjects(output[@"num"], @42, "side effect should be evaluated");
}

- (void)testSet {
    NSString *xml =
    @"<NSArray xmlns:x='https://github.com/xlc/XLCUtils'>"
        "<NSDictionary x:name='dict' />"
        "<x:Set object='dict' key='dict2'>"
            "<NSDictionary />"
        "</x:Set>"
        "<x:Set object='dict' key='str' value='val' />"
        "<x:Set keyPath='dict2.key'>"
            "<x:Set.object>"
                "<x:Ref name='dict' />"
            "</x:Set.object>"
            "<x:Set.value>"
                "<NSNumber value='42' />"
            "</x:Set.value>"
        "</x:Set>"
    "</NSArray>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    NSDictionary *output;
    id result = [obj createWithOutputDictionary:&output];
    XCTAssertEqualObjects(result, (@[@{ @"dict2" : @{ @"key" : @42 }, @"str" : @"val" }]));
}

- (void)testGet {
    NSString *xml =
    @"<NSArray xmlns:x='https://github.com/xlc/XLCUtils'>"
        "<x:void>"
            "<NSDictionary x:name='dict' a='1' b='2'>"
                "<NSDictionary.c>"
                    "<NSDictionary d='3' />"
                "</NSDictionary.c>"
            "</NSDictionary>"
        "</x:void>"
        "<x:Get object='dict' key='a' />"
        "<x:Get object='dict' key='b' />"
        "<x:Get keyPath='c.d'>"
            "<x:Get.object>"
                "<x:Ref name='dict' />"
            "</x:Get.object>"
        "</x:Get>"
    "</NSArray>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    NSDictionary *output;
    id result = [obj createWithOutputDictionary:&output];
    XCTAssertEqualObjects(result, (@[ @"1", @"2", @"3" ]));
}

- (void)testPostAction {
    NSString *xml =
    @"<NSDictionary xmlns:x='https://github.com/xlc/XLCUtils' x:name='dict'>"
        "<x:PostAction>"
            "<x:Set key='dict2'>" // without object default to parent object
                "<NSDictionary />"
            "</x:Set>"
            "<x:Set object='dict' key='str' value='val' />"
            "<x:Set keyPath='dict2.key'>"
                "<x:Set.object>"
                    "<x:Ref name='dict' />"
                "</x:Set.object>"
                "<x:Set.value>"
                    "<NSNumber value='42' />"
                "</x:Set.value>"
            "</x:Set>"
        "</x:PostAction>"
    "</NSDictionary>";
    NSError *error;
    XLCXMLObject *obj = [XLCXMLObject objectWithXMLString:xml error:&error];

    XCTAssertNil(error, "no error");
    XCTAssertNotNil(obj, "have obj");

    NSDictionary *output;
    id result = [obj createWithOutputDictionary:&output];
    XCTAssertEqualObjects(result, (@{ @"dict2" : @{ @"key" : @42 }, @"str" : @"val" }));
}

@end
