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
    XLCLoggingLevelWarning,
    XLCLoggingLevelError,
    XLCLoggingLevelCount
};

#define XLCLOG(level, format...) [XLCLogger logWithLevel:level function:__PRETTY_FUNCTION__ line:__LINE__ message:@"" format]

#ifdef DEBUG
// debug log
#define XLCDLOG(format...) XLCLOG(XLCLoggingLevelDebug, format)
#else
// which removed completely in release build
#define XLCDLOG(format...) ((void)0)
#endif

// info log
#define XLCILOG(format...) XLCLOG(XLCLoggingLevelInfo, format)

// warn log
#define XLCWLOG(format...) XLCLOG(XLCLoggingLevelWarning, format)

// error log
#define XLCELOG(format...) XLCLOG(XLCLoggingLevelError, format)

// condition log
#define XLCCLOG(condition, format...) do { if (condition) XLCILOG(format); } while (0)

// save some typing
#define XDLOG(format...) XLCDLOG(format)
#define XILOG(format...) XLCILOG(format)
#define XWLOG(format...) XLCWLOG(format)
#define XELOG(format...) XLCELOG(format)
#define XCLOG(condition, format...) XLCCLOG(condition, format)

extern const char * const XLCLogLevelNames[];

typedef void (^XLCLoggerBlock) (XLCLoggingLevel level, const char *function, int lineno, NSString *message);

@interface XLCLogger : NSObject

+ (void)addLogger:(XLCLoggerBlock)logger;
+ (void)setLogger:(XLCLoggerBlock)logger forKey:(id<NSCopying>)key;
+ (void)removeLoggerForKey:(id<NSCopying>)key;

+ (void)logWithLevel:(XLCLoggingLevel)level function:(const char *)function line:(int)line message:(NSString *)format, ... NS_FORMAT_FUNCTION(4,5);

@end
