//
//  XLCTraceTests.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14/8/2.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import "XLCTrace.h"

@interface XLCTraceTests : XCTestCase

@end

@implementation XLCTraceTests {
    XLCTrace *_trace;
    int _line;
}

- (XLCTraceInfo *)createInfo {
    XLCTraceInfo *info = [[XLCTraceInfo alloc] init];
    info->filename = "filename";
    info->function = "function";
    info->lineno = _line++;
    info->time = 1234;
    info->threadId = 12;
    return info;
}

- (void)setUp {
    [super setUp];
    
    _trace = [XLCTrace traceWithName:@"TestTrace"];
    _line = 0;
}

- (void)tearDown {
    _trace = nil;
    
    [super tearDown];
}

- (void)testInMemoryBufferOutput {
    XLCTraceInMemoryBufferOutput *output = [[XLCTraceInMemoryBufferOutput alloc] init];
    output.capacity = 4;
    
    [output didAddToTrace:_trace];
    
    [output processInfo:[self createInfo]];
    [output processInfo:[self createInfo]];
    [output processInfo:[self createInfo]];
    
    NSArray *buffer = output.buffer;
    XCTAssertEqual(((XLCTraceInfo *)buffer[0])->lineno, 0);
    XCTAssertEqual(((XLCTraceInfo *)buffer[1])->lineno, 1);
    XCTAssertEqual(((XLCTraceInfo *)buffer[2])->lineno, 2);
    
    [output processInfo:[self createInfo]];
    [output processInfo:[self createInfo]];
    buffer = output.buffer;
    
    XCTAssertEqual(((XLCTraceInfo *)buffer[0])->lineno, 1);
    XCTAssertEqual(((XLCTraceInfo *)buffer[1])->lineno, 2);
    XCTAssertEqual(((XLCTraceInfo *)buffer[2])->lineno, 3);
    XCTAssertEqual(((XLCTraceInfo *)buffer[3])->lineno, 4);
    
    [output processInfo:[self createInfo]];
    [output processInfo:[self createInfo]];
    buffer = output.buffer;
    
    XCTAssertEqual(((XLCTraceInfo *)buffer[0])->lineno, 3);
    XCTAssertEqual(((XLCTraceInfo *)buffer[1])->lineno, 4);
    XCTAssertEqual(((XLCTraceInfo *)buffer[2])->lineno, 5);
    XCTAssertEqual(((XLCTraceInfo *)buffer[3])->lineno, 6);
    
    [output processInfo:[self createInfo]];
    [output processInfo:[self createInfo]];
    buffer = output.buffer;
    
    XCTAssertEqual(((XLCTraceInfo *)buffer[0])->lineno, 5);
    XCTAssertEqual(((XLCTraceInfo *)buffer[1])->lineno, 6);
    XCTAssertEqual(((XLCTraceInfo *)buffer[2])->lineno, 7);
    XCTAssertEqual(((XLCTraceInfo *)buffer[3])->lineno, 8);
    
    [output didRemoveFromTrace];
}


@end
