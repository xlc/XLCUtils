//
//  XLCLogging.m
//  XLCUtils
//
//  Created by Xiliang Chen on 13-9-5.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XLCLogging.h"

#import "XLCAssertion.h"

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
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    const char *level;
    switch (logMessage->logFlag) {
        case LOG_FLAG_ERROR:    level = "Error";    break;
        case LOG_FLAG_WARN:     level = "Warn";     break;
        case LOG_FLAG_INFO:     level = "Info";     break;
        case LOG_FLAG_DEBUG:    level = "Debug";    break;
        case LOG_FLAG_VERBOSE:  level = "Verbose";  break;
        default:                level = "????";     break;
    }
    NSString *time = [_dateFormatter stringFromDate:logMessage->timestamp];
    return [NSString stringWithFormat:@"%@ [%x]  %s\t %s:%d\t- %@", time, logMessage->machThreadID, level, logMessage->function, logMessage->lineNumber, logMessage->logMsg];
}

@end