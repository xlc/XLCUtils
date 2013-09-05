//
//  XLCLogging.m
//  XLCUtils
//
//  Created by Xiliang Chen on 13-9-5.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XLCLogging.h"

static const char * const XLCLogLevelNames[] = {
    "Debug",
    "Info",
    "Warn",
    "Error",
};

static NSMutableDictionary *loggerDict;

@implementation XLCLogger

+ (void)initialize {
    if (self == [XLCLogger class]) {
        loggerDict = [NSMutableDictionary dictionary];
    }
}

+ (void)addLogger:(XLCLoggerBlock)logger {
    logger = [logger copy];
    @synchronized(loggerDict) {
        loggerDict[(id)logger] = logger;
    }
}

+ (void)setLogger:(XLCLoggerBlock)logger forKey:(id<NSCopying>)key {
    logger = [logger copy];
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
    
    NSLog(@" %s\t %s:%d\t- %@", XLCLogLevelNames[level], function, line, message);

    NSArray *allLoggers;
    @synchronized(loggerDict) {
        allLoggers = [[loggerDict allValues] copy];
    }
    
    for (XLCLoggerBlock logger in allLoggers) {
        logger(level, function, line, message);
    }
}

@end
