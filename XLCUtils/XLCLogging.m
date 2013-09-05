//
//  XLCLogging.m
//  XLCUtils
//
//  Created by Xiliang Chen on 13-9-5.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XLCLogging.h"

static NSMutableDictionary *loggerDict;

@implementation XLCLogger

+ (void)initialize {
    if ([self class] == [XLCLogger class]) {
        loggerDict = [NSMutableDictionary dictionary];
    }
}

+ (void)addLogger:(void (^)(XLCLoggingLevel, NSString *))logger {
    @synchronized(loggerDict) {
        loggerDict[(id)logger] = logger;
    }
}

+ (void)setLogger:(void (^)(XLCLoggingLevel, NSString *))logger forKey:(id<NSCopying>)key {
    @synchronized(loggerDict) {
        loggerDict[key] = logger;
    }
}

+ (void)removeLoggerForKey:(id<NSCopying>)key {
    @synchronized(loggerDict) {
        [loggerDict removeObjectForKey:key];
    }
}

+ (void)logWithLevel:(XLCLoggingLevel)level function:(const char *)function line:(int)line message:(NSString *)format, ... {
    va_list ap;
    va_start(ap, format);
    
    NSString *message = [[NSString alloc] initWithFormat:format arguments:ap];
    
    va_end(ap);
    
    NSLog(@"%@", message);

    NSArray *allLoggers;
    @synchronized(loggerDict) {
        allLoggers = [[loggerDict allValues] copy];
    }
    
    for (void (^logger)(XLCLoggingLevel, NSString *)  in allLoggers) {
        logger(level, message);
    }
}

@end
