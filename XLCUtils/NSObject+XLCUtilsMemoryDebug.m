//
//  NSObject+XLCUtilsMemoryDebug.m
//  XLCUtils
//
//  Created by Xiliang Chen on 13-9-12.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "NSObject+XLCUtilsMemoryDebug.h"

#import <objc/runtime.h>
#import <objc/message.h>

@implementation NSObject (XLCTestUtilsMemoryDebug)

static void *autoreleaseCountKey = &autoreleaseCountKey;
static void *originalClassKey = &originalClassKey;  // [self class]
static void *originalIsaKey = &originalIsaKey;  // self->isa

static NSString * const classSuffix = @"_XLCTestUtilsMemoryDebug";

- (id)xlc_swizzleRetainRelease {
    
    Class oldcls = object_getClass(self);
    
    if ([[oldcls description] hasSuffix:classSuffix]) { // already swizzled
        return self;
    }
    
    objc_setAssociatedObject(self, originalIsaKey, oldcls, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, originalClassKey, [self class], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    NSString *newClassName = [[oldcls description] stringByAppendingString:@"_XLCTestUtilsMemoryDebug"];
    
    Class newcls = NSClassFromString(newClassName);
    if (!newcls) {
        newcls = objc_allocateClassPair(oldcls, [newClassName UTF8String], 0);
        
        class_addMethod(newcls,
                        @selector(retain),
                        [NSObject instanceMethodForSelector:@selector(xlc_retain)],
                        "@@:");
        
        class_addMethod(newcls,
                        @selector(release),
                        [NSObject instanceMethodForSelector:@selector(xlc_release)],
                        "v@:");
        
        class_addMethod(newcls,
                        @selector(autorelease),
                        [NSObject instanceMethodForSelector:@selector(xlc_autorelease)],
                        "@@:");
        
        class_addMethod(newcls,
                        @selector(class),
                        [NSObject instanceMethodForSelector:@selector(xlc_class)],
                        "@@:");
        
        class_addMethod(newcls,
                        @selector(dealloc),
                        [NSObject instanceMethodForSelector:@selector(xlc_dealloc)],
                        "v@:");
        
        objc_registerClassPair(newcls);
    }
    
    object_setClass(self, newcls);
    return self;
}

- (void)xlc_restoreRetainRelease {
    Class oldcls = objc_getAssociatedObject(self, originalIsaKey);
    if (!oldcls) {  // not swizzled
        return;
    }
    
    object_setClass(self, oldcls);
}

- (NSUInteger)xlc_autoreleaseCount {
    return [objc_getAssociatedObject(self, autoreleaseCountKey) unsignedIntegerValue];
}

- (id)xlc_retain
{
    struct objc_super superstruct = { self, objc_getAssociatedObject(self, originalIsaKey) };
    return ((id (*)(struct objc_super *super, SEL op))objc_msgSendSuper)(&superstruct, @selector(retain));
}

- (void)xlc_release
{
    struct objc_super superstruct = { self, objc_getAssociatedObject(self, originalIsaKey) };
    ((id (*)(struct objc_super *super, SEL op))objc_msgSendSuper)(&superstruct, @selector(release));
}

- (id)xlc_autorelease
{
    @synchronized(self) {
        NSUInteger count = [objc_getAssociatedObject(self, autoreleaseCountKey) unsignedIntegerValue] + 1;
        objc_setAssociatedObject(self, autoreleaseCountKey, @(count), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    struct objc_super superstruct = { self, [NSObject class] };
    return ((id (*)(struct objc_super *super, SEL op))objc_msgSendSuper)(&superstruct, @selector(autorelease));
}

- (Class)xlc_class
{
    return objc_getAssociatedObject(self, originalClassKey);
}

- (void)xlc_dealloc
{
    struct objc_super superstruct = { self, objc_getAssociatedObject(self, originalIsaKey) };
    ((id (*)(struct objc_super *super, SEL op))objc_msgSendSuper)(&superstruct, @selector(release));
}

- (NSUInteger)xlc_retainCount
{
    return [self retainCount];
}

@end
