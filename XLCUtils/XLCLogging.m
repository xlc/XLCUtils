//
//  XLCLogging.m
//  XLCUtils
//
//  Created by Xiliang Chen on 13-9-5.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XLCLogging.h"

#import "XLCUtilsLogPrivate.h"

#import <objc/runtime.h>

#ifdef DEBUG

int XLCLogLevel = LOG_LEVEL_ALL;

#else

int XLCLogLevel = LOG_LEVEL_WARN;

#endif

@implementation XLCDefaultLogFormatter {
    NSDateFormatter *_dateFormatter;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"MM-dd HH:mm:ss.SSS"];
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    const char *level;
    switch (logMessage->logFlag) {
        case LOG_FLAG_ERROR:    level = "Error  "; break;
        case LOG_FLAG_WARN:     level = "Warn   "; break;
        case LOG_FLAG_INFO:     level = "Info   "; break;
        case LOG_FLAG_DEBUG:    level = "Debug  "; break;
        case LOG_FLAG_VERBOSE:  level = "Verbose"; break;
        default:                level = "????   "; break;
    }
    NSString *time = [_dateFormatter stringFromDate:logMessage->timestamp];
    NSString *loggerName = @"";
    if ([logMessage->tag isKindOfClass:[XLCLogger class]]) {
        XLCLogger *logger = logMessage->tag;
        if ((logMessage->logFlag & logger.level) == 0) {
            return nil;
        }
        loggerName = logger.name;
    }
    if ([loggerName length]) {
        loggerName = [loggerName stringByAppendingString:@": "];
    }
    // 01-23 12:34:56[4x] Error  -[MyClass method]:54: XLCUtils: log message
    return [NSString stringWithFormat:@"%@[%x] %s %s:%d\t: %@%@", time, logMessage->machThreadID, level, logMessage->function, logMessage->lineNumber, loggerName, logMessage->logMsg];
}

@end

@implementation XLCLogger : NSObject

+ (instancetype)logger
{
    return [self loggerWithName:nil];
}

+ (instancetype)loggerWithName:(NSString *)name
{
    XLCLogger *logger = [[self alloc] init];
    logger.name = name;
    return logger;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.level = LOG_LEVEL_ALL;
    }
    return self;
}

static void * XLCLoggerKey = &XLCLoggerKey;

+ (instancetype)loggerForObject:(id)object
{
    return objc_getAssociatedObject(object, XLCLoggerKey)
        ?: objc_getAssociatedObject([object class], XLCLoggerKey);
}

+ (instancetype)loggerForClass:(Class)cls
{
    return [self loggerForObject:cls];
}

+ (void)setLogger:(XLCLogger *)logger forObject:(id)object
{
    objc_setAssociatedObject(object, XLCLoggerKey, logger, OBJC_ASSOCIATION_RETAIN);
}

+ (void)setLogger:(XLCLogger *)logger forClass:(Class)cls
{
    [self setLogger:logger forObject:cls];
}

@end

XLCLogger *XLCUtilsGetLogger()
{
    static XLCLogger *logger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [XLCLogger loggerWithName:@"XLCUtils"];
    });
    return logger;
}