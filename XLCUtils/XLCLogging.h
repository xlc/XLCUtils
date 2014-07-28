//
//  XLCLogging.h
//  XLCUtils
//
//  Created by Xiliang Chen on 13-9-5.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CocoaLumberjack/DDLog.h>

#undef LOG_OBJC_MAYBE
#define LOG_OBJC_MAYBE(async, lvl, flg, ctx, format...) \
        LOG_MAYBE(async, lvl, flg, ctx, __PRETTY_FUNCTION__, @"" format)

#undef LOG_C_MAYBE
#define LOG_C_MAYBE LOG_OBJC_MAYBE

#define XLCLogError(format...) DDLogError(format)
#define XLCLogWarn(format...) DDLogWarn(format)
#define XLCLogInfo(format...) DDLogInfo(format)

#ifdef DEBUG

#define XLCLogDebug(format...) DDLogDebug(format)
#define XLCLogVerbose(format...) DDLogVerbose(format)

#else

#define XLCLogDebug(format...) (void)0
#define XLCLogVerbose(format...) (void)0

#endif

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF XLCLogLevel

extern int XLCLogLevel;

@interface XLCDefaultLogFormatter : NSObject <DDLogFormatter>

@end
