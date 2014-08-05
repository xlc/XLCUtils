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

#include <unordered_set>

const int kPanicCount = 100;

@implementation XLCTrace {
@public
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

- (instancetype)initWithName:(NSString *)name;
{
    self = [super init];
    if (self) {
        _name = name;
        _queue = dispatch_queue_create([name UTF8String], DISPATCH_QUEUE_SERIAL);
        _outputs = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)sync
{
    dispatch_barrier_sync(_queue, ^{});
}

- (void)addOutput:(id<XLCTraceOutput>)output forKey:(id<NSCopying>)key
{
    dispatch_async(_queue, ^{
        _outputs[key] = output;
        if ([output respondsToSelector:@selector(didAddToTrace:)]) {
            [output didAddToTrace:self];
        }
    });
}

- (void)removeOutputForKey:(id<NSCopying>)key
{
    dispatch_async(_queue, ^{
        id<XLCTraceOutput> output = _outputs[key];
        [_outputs removeObjectForKey:key];
        if ([output respondsToSelector:@selector(didRemoveFromTrace)]) {
            [output didRemoveFromTrace];
        }
    });
}

+ (void)panic
{
    [XLCTraceGetDefault() panic];
}


- (void)panic
{
    dispatch_barrier_sync(_queue, ^{
        for (id<XLCTraceOutput> output in [_outputs allValues]) {
            if ([output respondsToSelector:@selector(panic)]) {
                [output panic];
            }
        }
    });
}

#pragma mark - private method

- (void)processInfo:(XLCTraceInfo *)info
{
    dispatch_async(_queue, ^{
        for (id<XLCTraceOutput> output in [_outputs allValues]) {
            [output processInfo:info];
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
    XLCTraceInfo *info = [[XLCTraceInfo alloc] init];
    info->filename = filename;
    info->function = func;
    info->lineno = lineno;
    info->time = mach_absolute_time();
    info->threadId = pthread_mach_thread_np(pthread_self());
    
    [trace processInfo:info];
}

@implementation XLCTraceInfo

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%llu - %s:[%llu]>", time, function, lineno];
}

- (NSData *)data {
    NSMutableData *data = [NSMutableData dataWithCapacity:XLCTraceInfoDataSize];
    uint64_t buff = reinterpret_cast<uint64_t>(filename);
    [data appendBytes:&buff length:sizeof(uint64_t)];
    buff = reinterpret_cast<uint64_t>(function);
    [data appendBytes:&buff length:sizeof(uint64_t)];
    buff = static_cast<uint64_t>(lineno);
    [data appendBytes:&buff length:sizeof(uint64_t)];
    buff = static_cast<uint64_t>(time);
    [data appendBytes:&buff length:sizeof(uint64_t)];
    buff = static_cast<uint64_t>(threadId);
    [data appendBytes:&buff length:sizeof(uint64_t)];
    return data;
}
@end

@implementation XLCTraceInMemoryBufferOutput {
    NSMutableArray *_buffer;
    NSUInteger _current;
    XLCTraceFileSystemOutput *_fsOutput;
    int _panicCount;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
#ifdef TARGET_OS_IPHONE
        self.capacity = 500;
#else
        self.capacity = 2000;
#endif
    }
    return self;
}

- (void)dumpToFileSystem
{
    NSArray *buffer = self.buffer;
    if ([buffer count] == 0) {
        return;
    }
    XLCTraceFileSystemOutput *output = [[XLCTraceFileSystemOutput alloc] init];
    [output didAddToTrace:_trace];
    for (XLCTraceInfo *info in buffer) {
        [output processInfo:info];
    }
    [output didRemoveFromTrace];
}

- (NSArray *)buffer
{
    __block NSMutableArray *buffer;
    __block NSUInteger current;
    dispatch_queue_t queue = self.trace.queue;
    if (!queue) {
        return nil;
    }
    dispatch_sync(queue, ^{
        buffer = [_buffer mutableCopy];
        current = _current;
    });
    
    if (current == 0) {
        return buffer;
    }
    
    NSRange frontRange = NSMakeRange(0, current);
    NSArray *front = [buffer subarrayWithRange:frontRange];
    [buffer removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:frontRange]];
    [buffer addObjectsFromArray:front];
    return buffer;
}

#pragma mark - XLCTraceOutput

- (void)processInfo:(XLCTraceInfo *)info
{
    NSUInteger count = _buffer.count;
    NSUInteger capacity = self.capacity;
    if (count == capacity) {
        _buffer[_current] = info;
        ++_current;
        _current %= capacity;
    } else if (count > capacity) {
        NSUInteger diff = count - capacity;
        [_buffer removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(_current, diff)]];
        [_buffer insertObject:info atIndex:_current];
    } else {
        [_buffer addObject:info];
    }
    if (--_panicCount >= 0) {
        [_fsOutput processInfo:info];
        [_fsOutput sync];
    } else {
        [_fsOutput didRemoveFromTrace];
        _fsOutput = nil;
    }
}

- (void)didAddToTrace:(XLCTrace *)trace
{
    self.trace = trace;
    _buffer = [NSMutableArray arrayWithCapacity:self.capacity];
}

- (void)didRemoveFromTrace
{
    _buffer = nil;
    self.trace = nil;
}

- (void)panic
{
    _panicCount = kPanicCount;
    if (!_fsOutput) {
        _fsOutput = [[XLCTraceFileSystemOutput alloc] init];
        [_fsOutput didAddToTrace:_trace];
        for (XLCTraceInfo *info in self.buffer) {
            [_fsOutput processInfo:info];
        }
        [_fsOutput sync];
    }
}

@end

@implementation XLCTraceFileSystemOutput {
    std::unordered_set<const char *> _storedFilenames;
    std::unordered_set<const char *> _storedFunctions;
    NSFileManager *_fileManager;
    NSString *_folderPath;
    NSFileHandle *_filenameFile;
    NSFileHandle *_functionFile;
    NSFileHandle *_traceOutputFile;
    int _panicCount;
}

+ (instancetype)outputWithLogDirectoryPath
{
    return [[self alloc] initWithPath:nil];
}

+ (instancetype)outputWithPath:(NSString *)path
{
    return [[self alloc] initWithPath:path];
}

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        if (!path) {
#if TARGET_OS_IPHONE
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *baseDir = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
            NSString *logsDirectory = [baseDir stringByAppendingPathComponent:@"Logs"];
            
#else
            NSString *appName = [[NSProcessInfo processInfo] processName];
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
            NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
            NSString *logsDirectory = [[basePath stringByAppendingPathComponent:@"Logs"] stringByAppendingPathComponent:appName];
#endif
            path = logsDirectory;
        }
        _path = path;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithPath:nil];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p;path=%@>", [self class], self, self.path];
}

- (NSFileHandle *)fileHandleForPath:(NSString *)filepath
{
    if (![_fileManager fileExistsAtPath:filepath]) {
        if (![_fileManager createFileAtPath:filepath contents:[NSData data] attributes:nil]) {
            XLCLogWarn(@"Unable to create file at %@", filepath);
            return nil;
        }
    }
    
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filepath];
    if (!handle) {
        XLCLogWarn(@"Unable to write to file at %@", filepath);
        return nil;
    }
    
    [handle seekToEndOfFile];
    
    return handle;
}

- (BOOL)createOutputFolderAndFiles
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    
    NSCharacterSet *allowedCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>:"] invertedSet];
    NSString *traceName = [_trace.name stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet] ?: @"";
    
    NSString *baseFolderPath = [_path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", dateString, traceName]];
    
    _folderPath = baseFolderPath;
    
    BOOL success = NO;
    
    for (int i = 0; i < 20; ++i) {
        
        if (i > 0) {
            _folderPath = [NSString stringWithFormat:@"%@_%d", baseFolderPath, i];
        }
        
        BOOL isDict = NO;
        NSError *error = nil;
        
        if ([_fileManager fileExistsAtPath:_folderPath isDirectory:&isDict]) {
            if (isDict) {
                success = YES;
            }
        } else {
            if ([_fileManager createDirectoryAtPath:_folderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
                success = YES;
            }
        }
        
        if (success) {
            break;
        } else {
            XLCLogInfo(@"%@: Unable to create folder at path: %@; error: %@", self, _folderPath, error);
        }
        
    }
    
    if (!success) {
        XLCLogWarn(@"%@: Failed to create log folder, will not working", self);
        return NO;
    }
    
    NSString *functionFilePath = [_folderPath stringByAppendingPathComponent:@"function.txt"];
    _functionFile = [self fileHandleForPath:functionFilePath];
    
    NSString *filenameFilePath = [_folderPath stringByAppendingPathComponent:@"filename.txt"];
    _filenameFile = [self fileHandleForPath:filenameFilePath];
    
    NSString *traceFilePath = [_folderPath stringByAppendingPathComponent:@"trace"];
    _traceOutputFile = [self fileHandleForPath:traceFilePath];
    
    if (functionFilePath && filenameFilePath && traceFilePath) {
        return YES;
    } else {
        XLCLogWarn(@"%@: Failed open files, will not working", self);
        return NO;
    }
}

#pragma mark - XLCTraceOutput

- (void)processInfo:(XLCTraceInfo *)info
{
    if (!_folderPath) {
        XLCLogDebug(@"%@: unable to process trace info: %@", self, info);
        return;
    }
    
    [_traceOutputFile writeData:[info data]];
    
    if (_storedFilenames.insert(info->filename).second) {
        NSString *str = [NSString stringWithFormat:@"%p:%s\n", info->filename, info->filename];
        [_filenameFile writeData:[str dataUsingEncoding:NSUTF8StringEncoding]];
        [_filenameFile synchronizeFile];
    }
    
    if (_storedFunctions.insert(info->function).second) {
        NSString *str = [NSString stringWithFormat:@"%p:%s\n", info->function, info->function];
        [_functionFile writeData:[str dataUsingEncoding:NSUTF8StringEncoding]];
        [_functionFile synchronizeFile];
    }
    
    if (--_panicCount >= 0) {
        [_traceOutputFile synchronizeFile];
    }
}

- (void)didAddToTrace:(XLCTrace *)trace
{
    self.trace = trace;
    _fileManager = [[NSFileManager alloc] init];
    
    if (![self createOutputFolderAndFiles]) {
        [self didRemoveFromTrace];
    }
    
}

- (void)didRemoveFromTrace
{
    self.trace = nil;
    _fileManager = nil;
    _folderPath = nil;
    [_functionFile closeFile];
    _functionFile = nil;
    [_filenameFile closeFile];
    _filenameFile = nil;
    [_traceOutputFile closeFile];
    _traceOutputFile = nil;
}

- (void)sync
{
    [_traceOutputFile synchronizeFile];
}

- (void)panic
{
    _panicCount = kPanicCount;
    [self sync];
}

@end