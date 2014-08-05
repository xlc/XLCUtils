//
//  XLCTrace.h
//  XLCUtils
//
//  Created by Xiliang Chen on 14/7/15.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/DDLog.h>

static const NSUInteger XLCTraceInfoDataSize = sizeof(uint64_t) * 5;

@interface XLCTraceInfo : NSObject {
@public
    const char * filename;
    const char * function;
    uint64_t lineno;
    uint64_t time;
    mach_port_t threadId;
}

- (NSData *)data;

@end

@class XLCTrace;

@protocol XLCTraceOutput <NSObject>

- (void)processInfo:(XLCTraceInfo *)info;

@optional

- (void)didAddToTrace:(XLCTrace *)trace;
- (void)didRemoveFromTrace;

- (void)panic;

@end

@interface XLCTrace : NSObject

@property (readonly) NSString *name;
@property (readonly) dispatch_queue_t queue;

+ (instancetype)defaultTrace;

+ (instancetype)traceWithName:(NSString *)name;
- (instancetype)initWithName:(NSString *)name;

- (void)sync; // block until all messages are processed

- (void)addOutput:(id<XLCTraceOutput>)output forKey:(id<NSCopying>)key;
- (void)removeOutputForKey:(id<NSCopying>)key;

+ (void)panic; // [[XLCTrace defaultTrace] panic]
- (void)panic;

@end

@interface XLCTraceInMemoryBufferOutput : NSObject <XLCTraceOutput>

@property XLCTrace *trace;
@property NSUInteger capacity; // default ios 500, osx 2000

- (void)dumpToFileSystem;
- (NSArray *)buffer;

@end

@interface XLCTraceFileSystemOutput : NSObject <XLCTraceOutput>

@property XLCTrace *trace;
@property (readonly) NSString *path;

// On Mac, this is in ~/Library/Logs/<Application Name>.
// On iPhone, this is in ~/Library/Caches/Logs.
+ (instancetype)outputWithLogDirectoryPath;

+ (instancetype)outputWithPath:(NSString *)path;
- (instancetype)initWithPath:(NSString *)path;

- (void)sync;

@end

__BEGIN_DECLS

XLCTrace *XLCTraceGetDefault();

void _XLCTrace(XLCTrace *trace, const char *filename, const char *func, unsigned lineno);

__END_DECLS

#define _XLC_TRACE_0() _XLCTrace(XLCTraceGetDefault(), __FILE__, __PRETTY_FUNCTION__, __LINE__)
#define _XLC_TRACE_1(t) _XLCTrace(t, __FILE__, __PRETTY_FUNCTION__, __LINE__)

#define _XLC_TRACE_CHOOSE(_0, _1, NAME, ...) NAME
#define _XLC_TRACE(...) _XLC_TRACE_CHOOSE(_0, ##__VA_ARGS__, _XLC_TRACE_1, _XLC_TRACE_0)(__VA_ARGS__)

/// usage:
///     XLCTRACE();
/// or:
///     XLCTRACE *dbgTrace = [XLCTrace traceWithName:@"DEBUG"]; // global variable
///     XLCTRACE(dbgTrace);
#define XLCTRACE(...) _XLC_TRACE(__VA_ARGS__)
