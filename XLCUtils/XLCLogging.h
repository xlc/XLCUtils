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
#define XLCDLOG(...) XLCLOG(XLCLoggingLevelDebug, __VA_ARGS__)
#else
// which removed completely in release build
#define XLCDLOG(...) ((void)0)
#endif

// info log
#define XLCILOG(...) XLCLOG(XLCLoggingLevelInfo, __VA_ARGS__)

// warn log
#define XLCWLOG(...) XLCLOG(XLCLoggingLevelWarnning, __VA_ARGS__)

// error log
#define XLCELOG(...) XLCLOG(XLCLoggingLevelError, __VA_ARGS__)

// condition log
#define XLCCLOG(condition, msg, ...) if (condition) { XLCILOG(msg, ##__VA_ARGS__) }

// save some typing
#define XILOG XLCILOG
#define XWLOG XLCWLOG
#define XELOG XLCELOG
#define XCLOG XLCCLOG

typedef void (^XLCLoggerBlock) (XLCLoggingLevel, const char *, int, NSString *);

@interface XLCLogger : NSObject

+ (void)addLogger:(XLCLoggerBlock)logger;
+ (void)setLogger:(XLCLoggerBlock)logger forKey:(id<NSCopying>)key;
+ (void)removeLoggerForKey:(id<NSCopying>)key;

+ (void)logWithLevel:(XLCLoggingLevel)level function:(const char *)function line:(int)line message:(NSString *)format, ... NS_FORMAT_FUNCTION(4,5);

@end