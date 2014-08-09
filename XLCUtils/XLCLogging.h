//
//  XLCLogging.h
//  XLCUtils
//
//  Created by Xiliang Chen on 13-9-5.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CocoaLumberjack/DDLog.h>

extern int XLCLogLevel;

#define XLCLog(sync, logger, lvl, fmt...) \
        [DDLog log:sync \
             level:XLCLogLevel \
              flag:lvl \
           context:0 \
              file:__FILE__ \
          function:__PRETTY_FUNCTION__ \
              line:__LINE__ \
               tag:logger \
            format:@"" fmt]

#define XLCConditionalLog(logger, lvl, format...) \
do { \
    if (lvl & XLCLogLevel) { \
        XLCLog(lvl == LOG_FLAG_ERROR, logger, lvl, format); \
    } \
} while (0)

#define XLCLogError2(logger, format...) XLCConditionalLog(logger, LOG_FLAG_ERROR, format)
#define XLCLogWarn2(logger, format...) XLCConditionalLog(logger, LOG_FLAG_WARN, format)
#define XLCLogInfo2(logger, format...) XLCConditionalLog(logger, LOG_FLAG_INFO, format)

#ifdef DEBUG
#define XLCLogDebug2(logger, format...) XLCConditionalLog(logger, LOG_FLAG_DEBUG, format)
#else
#define XLCLogDebug2(logger, format...) do {} while(0)
#endif

#define XLCGetLogger() [XLCLogger loggerForObject:self]

#define XLCLogError(format...) XLCLogError2(XLCGetLogger(), format)
#define XLCLogWarn(format...)  XLCLogWarn2(XLCGetLogger(), format)
#define XLCLogInfo(format...)  XLCLogInfo2(XLCGetLogger(), format)
#define XLCLogDebug(format...) XLCLogDebug2(XLCGetLogger(), format)

#define XLCLogCError(format...) XLCLogError2(nil, format)
#define XLCLogCWarn(format...)  XLCLogWarn2(nil, format)
#define XLCLogCInfo(format...)  XLCLogInfo2(nil, format)
#define XLCLogCDebug(format...) XLCLogDebug2(nil, format)

@interface XLCLogger : NSObject

@property NSString *name;
@property int level; //default: LOG_LEVEL_ALL

+ (instancetype)logger;
+ (instancetype)loggerWithName:(NSString *)name;

+ (XLCLogger *)loggerForObject:(id)object;
+ (XLCLogger *)loggerForClass:(Class)cls;
+ (void)setLogger:(XLCLogger *)logger forObject:(id)object;
+ (void)setLogger:(XLCLogger *)logger forClass:(Class)cls;

@end

@interface XLCDefaultLogFormatter : NSObject <DDLogFormatter>

@end
