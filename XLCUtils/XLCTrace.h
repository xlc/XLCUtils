//
//  XLCTrace.h
//  XLCUtils
//
//  Created by Xiliang Chen on 14/7/15.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

__BEGIN_DECLS

typedef struct XLCTraceInfo {
    const char * filename;
    const char * func;
    unsigned lineno;
    uint64_t time;
} XLCTraceInfo;

@interface XLCTraceInfoArray : NSObject

@property (nonatomic, readonly) XLCTraceInfo *data;
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) pthread_t threadId;

@end

@protocol XLCTraceOutput <NSObject>

- (void)processInfos:(XLCTraceInfoArray *)infos;

- (void)startSession;
- (void)flush;

@end

@interface XLCTrace : NSObject

@property (readonly) NSString *name;
@property NSUInteger batchSize; // (1 ... 1000000)

+ (instancetype)defaultTrace;

+ (instancetype)traceWithName:(NSString *)name;
- (instancetype)initWithName:(NSString *)name;

- (void)startSession;
- (void)flush;

- (void)addOutput:(id<XLCTraceOutput>)output forKey:(id<NSCopying>)key;
- (void)removeOutputForKey:(id<NSCopying>)key;

@end

XLCTrace *XLCTraceGetDefault();

void _XLCTrace(XLCTrace *trace, const char *filename, const char *func, unsigned lineno);

#define XLCTRACE() _XLCTrace(XLCTraceGetDefault(), __FILE__, __PRETTY_FUNCTION__, __LINE__)

__END_DECLS