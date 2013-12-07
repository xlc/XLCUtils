//
//  NSObject+XLCUtilsMemoryDebug.h
//  XLCUtils
//
//  Created by Xiliang Chen on 13-9-12.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (XLCTestUtilsMemoryDebug)

/**
 * Perform isa-swizzle to override retain / release / autorelease.
 */
- (id)xlc_swizzleRetainRelease;

/**
 * Restore isa.
 */
- (void)xlc_restoreRetainRelease;

/**
 * Count of autorelease called.
 * This can be useful to calculate "real" retain count given no
 * autorelease pool was drain (which is the typical case when unit testing).
 */
- (NSUInteger)xlc_autoreleaseCount;

// stub methods
- (id)xlc_retain;
- (void)xlc_release;
- (id)xlc_autorelease;
- (Class)xlc_class;
- (void)xlc_dealloc;

// not swizzled, just call original retainCount
- (NSUInteger)xlc_retainCount;

@end