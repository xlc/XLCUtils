//
//  XLCAdditionsTests.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14-4-22.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSString+XLCAdditions.h"

@interface XLCAdditionsTests : XCTestCase

@end

@implementation XLCAdditionsTests

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

- (void)testNSStringHasNonWhitespaceCharacter
{
    XCTAssertFalse([@"" xlc_hasNonWhitespaceCharacter]);
    XCTAssertFalse([@"  " xlc_hasNonWhitespaceCharacter]);
    XCTAssertFalse([@"\t" xlc_hasNonWhitespaceCharacter]);
    XCTAssertFalse([@"\t  \t  \t  \t " xlc_hasNonWhitespaceCharacter]);
    
    XCTAssertTrue([@"\n" xlc_hasNonWhitespaceCharacter]);
    XCTAssertTrue([@"a" xlc_hasNonWhitespaceCharacter]);
    XCTAssertTrue([@"  a  " xlc_hasNonWhitespaceCharacter]);
    XCTAssertTrue([@"\t\n\t" xlc_hasNonWhitespaceCharacter]);
}

@end
