//
//  XLCLogging.h
//  XLCUtils
//
//  Created by Xiliang Chen on 13-9-5.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, XLCLoggingLevel) {
    XLCLoggingLevelDebug = 0,
    XLCLoggingLevelInfo,
    XLCLoggingLevelWarnning,
    XLCLoggingLevelError,
    XLCLoggingLevelCount
};

#define XLCLOG(level, ...) [XLCLogger logWithLevel:level function:__PRETTY_FUNCTION__ line:line message:__VA_ARGS__]

#ifdef DEBUG
// debug log
#define XDLOG(...) XLCLOG(XLCLoggingLevelDebug, __VA_ARGS__)
#else
// which removed completely in release build
#define XDLOG(...) ((void)0)
#endif

// info log
#define XILOG(...) XLCLOG(XLCLoggingLevelInfo, __VA_ARGS__)

// warn log
#define XWLOG(...) XLCLOG(XLCLoggingLevelWarnning, __VA_ARGS__)

// error log
#define XELOG(...) XLCLOG(XLCLoggingLevelError, __VA_ARGS__)

// condition log
#define XCLOG(condition, msg, ...) if (condition) { XILOG(msg, ##__VA_ARGS__) }

@interface XLCLogger : NSObject

+ (void)addLogger:(void (^)(XLCLoggingLevel, NSString *))logger;
+ (void)setLogger:(void (^)(XLCLoggingLevel, NSString *))logger forKey:(id<NSCopying>)key;
+ (void)removeLoggerForKey:(id<NSCopying>)key;

+ (void)logWithLevel:(XLCLoggingLevel)level function:(const char *)function line:(int)line message:(NSString *)format, ... NS_FORMAT_FUNCTION(4,5);

@end