//
//  XLCTrace.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14/7/15.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import "XLCTrace.h"

#import <mach/mach_time.h>
#import <pthread.h>

@interface XLCTraceInfoArray ()

@property (nonatomic, readonly) NSUInteger capacity;

- (instancetype)initWithCapacity:(NSUInteger)capacity;

@property (nonatomic) XLCTraceInfo *data;
@property (nonatomic) NSUInteger count;

@end

@implementation XLCTraceInfoArray

- (instancetype)initWithCapacity:(NSUInteger)capacity
{
    self = [super init];
    if (self) {
        _capacity = capacity;
        _data = new XLCTraceInfo[capacity];
        _count = 0;
        _threadId = pthread_self();
    }
    return self;
}

- (void)dealloc
{
    delete _data;
}

@end

@implementation XLCTrace {
@public
    // immutable
    dispatch_queue_t _queue;
    pthread_key_t _bufferKey;
    
    // mutable
    NSMutableDictionary *_outputs;
}

+ (instancetype)defaultTrace
{
    return XLCTraceGetDefault();
}

+ (XLCTrace *)traceWithName:(NSString *)name
{
    return [[self alloc] initWithName:name];
}

void bufferFree(void *ptr) {
    CFBridgingRelease(ptr);
}

- (instancetype)initWithName:(NSString *)name;
{
    self = [super init];
    if (self) {
        _name = name;
        _queue = dispatch_queue_create([name UTF8String], DISPATCH_QUEUE_SERIAL);
        _outputs = [NSMutableDictionary dictionary];
        _batchSize = 50;
        
        pthread_key_create(&_bufferKey, bufferFree);
    }
    return self;
}

- (void)dealloc
{
    pthread_key_delete(_bufferKey);
}

- (void)startSession
{
    dispatch_async(_queue, ^{
        for (id<XLCTraceOutput> output in [_outputs allValues]) {
            [output startSession];
        }
    });
}

- (void)flush
{
    dispatch_async(_queue, ^{
        for (id<XLCTraceOutput> output in [_outputs allValues]) {
            [output flush];
        }
    });
}

- (void)addOutput:(id<XLCTraceOutput>)output forKey:(id<NSCopying>)key
{
    dispatch_async(_queue, ^{
        _outputs[key] = output;
    });
}

- (void)removeOutputForKey:(id<NSCopying>)key
{
    dispatch_async(_queue, ^{
        [_outputs removeObjectForKey:key];
    });
}

#pragma mark - private method

- (void)processInfos:(XLCTraceInfoArray *)infos
{
    dispatch_async(_queue, ^{
        for (id<XLCTraceOutput> output in [_outputs allValues]) {
            [output processInfos:infos];
        }
    });
}

@end

XLCTrace *XLCTraceGetDefault()
{
    static XLCTrace *defaultTrace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultTrace = [XLCTrace traceWithName:@"default"];
    });
    return defaultTrace;
}

void _XLCTrace(XLCTrace *trace, const char *filename, const char *func, unsigned lineno)
{
    uint64_t time = mach_absolute_time();
    
    NSUInteger batchSize = MIN(MAX(trace.batchSize, 1), 1000000);
    
    XLCTraceInfoArray *buff = (__bridge XLCTraceInfoArray *)pthread_getspecific(trace->_bufferKey);
    if (!buff) {
        buff = [[XLCTraceInfoArray alloc] initWithCapacity:batchSize];
        pthread_setspecific(trace->_bufferKey, CFBridgingRetain(buff));
    }
    
    XLCTraceInfo *info = &buff.data[buff.count++];
    info->filename = filename;
    info->func = func;
    info->lineno = lineno;
    info->time = time;
    
    if (buff.count >= buff.capacity) {
        [trace processInfos:buff];
        CFBridgingRelease((__bridge CFTypeRef)buff);
        buff = [[XLCTraceInfoArray alloc] initWithCapacity:batchSize];
        pthread_setspecific(trace->_bufferKey, CFBridgingRetain(buff));
    }
}
