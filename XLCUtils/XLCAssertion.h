//
//  XLCAssertion.h
//  XLCUtils
//
//  Created by Xiliang Chen on 13-9-5.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XLCLogging.h"

__BEGIN_DECLS
void _XLCBreakIfInDebugger();
__END_DECLS

#define XLCASSERT(e, ...) \
do { \
    if (!(e)) { \
    XLCELOG(@"failed assertion: '%s', %@", #e, [NSString stringWithFormat:__VA_ARGS__]); \
        _XLCBreakIfInDebugger(); \
    }   \
} while (0)

#define XLCFAIL(...) \
do { \
    XLCELOG(__VA_ARGS__); \
    _XLCBreakIfInDebugger(); \
} while (0)

#define XLCASSERT_SOFT(e)\
do { \
    if (!(e)) { \
        XLCWLOG(@"failed soft assertion: '%s'", #e); \
    } \
} while (0)

#define XLCASSERT_KERN(e)\
do { \
    kern_return_t __kr = (e);\
    if (__kr != KERN_SUCCESS) { \
        XLCFAIL(@"kernal function: '%s' returned with error: %s", #e, mach_error_string(__kr)); \
    } \
} while (0)

#define XLCASSERT_CLASS(obj, cls) \
do { \
    id __obj = (obj); \
    Class __cls = (cls); \
    if (!([__obj isKindOfClass:[__cls class]])) { \
        XLCELOG(@"failed assertion: '[%s isKindOfClass:[%s class]]', expected class: %@, actual class: %@, object: %@",\
            #obj, #cls, __cls, [__obj class], __obj); \
        _XLCBreakIfInDebugger(); \
    }   \
} while (0)

#define XLCASSERT_NOTNIL(obj) \
do { \
    id __obj = (obj); \
    if (!__obj) { \
        XLCELOG(@"failed assertion: '%s != nil'", #obj); \
        _XLCBreakIfInDebugger(); \
    }   \
} while (0) \


// save some typing
#define XASSERT XLCASSERT
#define XFAIL XLCFAIL
#define XASSERT_SOFT XLCASSERT_SOFT
#define XASSERT_KERN XLCASSERT_KERN
#define XASSERT_CLASS XLCASSERT_CLASS
#define XASSERT_NOTNIL XLCASSERT_NOTNIL