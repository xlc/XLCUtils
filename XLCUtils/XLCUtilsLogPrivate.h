//
//  XLCUtilsLog.h
//  XLCUtils
//
//  Created by Xiliang Chen on 14/7/29.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import "XLCLogging.h"

__BEGIN_DECLS

XLCLogger *XLCUtilsGetLogger();

#define XLCUtilsLogError(format...) XLCLogError2(XLCUtilsGetLogger(), format)
#define XLCUtilsLogWarn(format...)  XLCLogWarn2(XLCUtilsGetLogger(), format)
#define XLCUtilsLogInfo(format...)  XLCLogInfo2(XLCUtilsGetLogger(), format)
#define XLCUtilsLogDebug(format...) XLCLogDebug2(XLCUtilsGetLogger(), format)

__END_DECLS