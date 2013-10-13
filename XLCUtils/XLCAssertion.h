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

#ifdef DEBUG
void _XLCBreakIfInDebugger(void);
#else
static inline void _XLCBreakIfInDebugger(void) {}
#endif

__END_DECLS

#define XLCFAIL(format...) \
do { \
    XLCELOG(format); \
    _XLCBreakIfInDebugger(); \
} while (0)

#define XLCASSERT(e, format...) \
do { \
    if (!(e)) { \
        XLCFAIL(@"failed assertion: '%s', %@", #e, [NSString stringWithFormat:@"" format]); \
    }   \
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
        XLCFAIL(@"failed assertion: '[%s isKindOfClass:[%s class]]', expected class: %@, actual class: %@, object: %@",\
            #obj, #cls, __cls, [__obj class], __obj); \
    }   \
} while (0)

#define XLCASSERT_NOTNIL(obj) \
do { \
    id __obj = (obj); \
    if (!__obj) { \
        XLCFAIL(@"failed assertion: '%s != nil'", #obj); \
    }   \
} while (0) \

#define XLCASSERT_NOTNULL(ptr) \
do { \
    void *__ptr = (ptr); \
    if (!__ptr) { \
        XLCFAIL(@"failed assertion: '%s != NULL'", #ptr); \
    }   \
} while (0) \


// save some typing
#define XASSERT(e, format...)   XLCASSERT(e, format)
#define XFAIL(format...)        XLCFAIL(format)
#define XASSERT_SOFT(e)         XLCASSERT_SOFT(e)
#define XASSERT_KERN(e)         XLCASSERT_KERN(e)
#define XASSERT_CLASS(obj, cls) XLCASSERT_CLASS(obj, cls)
#define XASSERT_NOTNIL(obj)     XLCASSERT_NOTNIL(obj)
#define XASSERT_NOTNULL(ptr)    XLCASSERT_NOTNULL(ptr)