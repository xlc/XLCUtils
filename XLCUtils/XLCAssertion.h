//
//  XLCAssertion.h
//  XLCUtils
//
//  Created by Xiliang Chen on 13-9-5.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XLCLogging.h"

#define XLCAssertCritical(e, format...)             _XLCAssertCritical(e, format)
#define XLCAssert(e, format...)                     _XLCAssert(e, format)

#define XLCFailCritical(format...)                  _XLCFailCritical(format)
#define XLCFail(format...)                          _XLCFail(format)

#define XLCAssertNotNullCritical(ptr, format...)    _XLCAssertNotNullCritical(ptr, format)
#define XLCAssertNotNull(ptr, format...)            _XLCAssertNotNull(ptr, format)

#define XLCAssertKernCritical(e, format...)         _XLCAssertKernCritical(e, format)
#define XLCAssertKern(e, format...)                 _XLCAssertKern(e, format)

#define XLCObjectCast(obj, cls)                     _XLCObjectCast(obj, cls)

#ifdef DEBUG

#define XLCAssertDebug(e, format...)                _XLCAssertDebug(e, format)
#define XLCAssertNotNullDebug(ptr, format...)       _XLCAssertNotNullDebug(ptr, format)
#define XLCAssertKernDebug(e, format...)            _XLCAssertKernDebug(e, format)

#else

#define XLCAssertDebug(e, format...)                (void)0
#define XLCAssertNotNullDebug(ptr, format...)       (void)0
#define XLCAssertKernDebug(e, format...)            (void)0

#endif

// implementation details below

__BEGIN_DECLS

void _XLCAssertionFailedCritical(NSString *format, ...);

#if DEBUG
void _XLCBreakIfInDebugger(void);
#else
static inline void _XLCBreakIfInDebugger(void) {}
#endif

__END_DECLS

#define _XLCFailCritical(format...) \
do { \
    XLCLogError(format); \
    _XLCBreakIfInDebugger(); \
    _XLCAssertionFailedCritical(@"" format); \
} while (0)

#define _XLCFail(format...) \
do { \
    XLCLogWarn(format); \
    _XLCBreakIfInDebugger(); \
} while (0)

#define _XLCFailDebug(format...) \
do { \
    XLCLogDebug(format); \
    _XLCBreakIfInDebugger(); \
} while (0)

#define _XLCAssertCritical(expr, format...) \
do { \
    if (!(expr)) { \
        _XLCFailCritical("Assertion failure: '%s' %@", #expr, [NSString stringWithFormat:@"" format]); \
    } \
} while (0)

#define _XLCAssert(expr, format...) \
do { \
    if (!(expr)) { \
        _XLCFail("Assertion failure: '%s' %@", #expr, [NSString stringWithFormat:@"" format]); \
    } \
} while (0)

#define _XLCAssertDebug(expr, format...) \
do { \
    if (!(expr)) { \
        _XLCFailDebug("Assertion failure: '%s' %@", #expr, [NSString stringWithFormat:@"" format]); \
    } \
} while (0)

#define _XLCAssertNotNullCritical(ptr, format...) \
do { \
    if (!(ptr)) { \
        _XLCFailCritical("Assertion failure: '%s != NULL' %@", #ptr, [NSString stringWithFormat:@"" format]); \
    } \
} while (0)

#define _XLCAssertNotNull(ptr, format...) \
do { \
    if (!(ptr)) { \
        _XLCFail("Assertion failure: '%s != NULL' %@", #ptr, [NSString stringWithFormat:@"" format]); \
    } \
} while (0)

#define _XLCAssertNotNullDebug(ptr, format...) \
do { \
    if (!(ptr)) { \
        _XLCFailDebug("Assertion failure: '%s != NULL' %@", #ptr, [NSString stringWithFormat:@"" format]); \
    } \
} while (0)

#define _XLCAssertKernCritical(expr, format...) \
do { \
    kern_return_t __kr = (expr); \
    if (__kr != KERN_SUCCESS) { \
        _XLCFailCritical("Assertion failure: '%s == KERN_SUCCESS' %s %@", #expr, mach_error_string(__kr), [NSString stringWithFormat:@"" format]); \
    } \
} while (0)

#define _XLCAssertKern(expr, format...) \
do { \
    kern_return_t __kr = (expr); \
    if (__kr != KERN_SUCCESS) { \
        _XLCFail("Assertion failure: '%s == KERN_SUCCESS' %s %@", #expr, mach_error_string(__kr), [NSString stringWithFormat:@"" format]); \
    } \
} while (0)

#define _XLCAssertKernDebug(expr, format...) \
do { \
    kern_return_t __kr = (expr); \
    if (__kr != KERN_SUCCESS) { \
        _XLCFailDebug("Assertion failure: '%s == KERN_SUCCESS' %s %@", #expr, mach_error_string(__kr), [NSString stringWithFormat:@"" format]); \
    } \
} while (0)

static inline id __XLCObjectCast(id obj, Class cls, const char *objexpr, const char *clsexpr)
{
    if (obj && ![obj isKindOfClass:cls])
    {
        _XLCFail("Assertion failure: '[%s isKindOfClass:[%s class]]', expected class: %@, actual class: %@, object: %@", objexpr, clsexpr, cls, [obj class], obj);
        return nil;
    }
    return obj;
}

#define _XLCObjectCast(obj, cls) __XLCObjectCast((obj), ([cls class]), #obj, #cls)




