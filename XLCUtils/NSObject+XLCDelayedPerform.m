//
//  NSObject+XLCDelayedPerform.m
//  XLCUtils
//
//  Created by Xiliang Chen on 13-9-5.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "NSObject+XLCDelayedPerform.h"

#import <objc/runtime.h>

@implementation NSObject (XLCDelayedPerform)

static const void *delayedPerformInfoKey = &delayedPerformInfoKey;

- (void)xlc_setNeedsPerformSelector:(SEL)selector withObject:(id)obj {
    [self xlc_setNeedsPerformSelector:selector withObject:obj withinInterval:0];
}

- (void)xlc_setNeedsPerformSelector:(SEL)selector withObject:(id)obj withinInterval:(NSTimeInterval)interval {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, delayedPerformInfoKey);
    if (!dict) {
        dict = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, delayedPerformInfoKey, dict, OBJC_ASSOCIATION_RETAIN);
    }
    NSString *strSel = NSStringFromSelector(selector);
    id key = obj ? @[strSel, obj] : @[strSel];
    NSTimer *timer = dict[key];
    if (!timer) {
        timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                 target:self
                                               selector:@selector(xlc_delayedPerformSelectorOnTimer:)
                                               userInfo:key
                                                repeats:NO];
        dict[key] = timer;
    }
}

- (void)xlc_performSelectorIfNeeded:(SEL)selector {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, delayedPerformInfoKey);
    NSString *strSel = NSStringFromSelector(selector);
    NSTimer *timer = dict[strSel];
    [timer fire];
}

#pragma mark - private

- (void)xlc_delayedPerformSelectorOnTimer:(NSTimer *)timer {
    NSArray *info = timer.userInfo;
    
    NSMutableDictionary *dict = objc_getAssociatedObject(self, delayedPerformInfoKey);
    [dict removeObjectForKey:info];
    
    id arg = info.count == 1 ? nil : info[1];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:NSSelectorFromString(info[0]) withObject:arg];
#pragma clang diagnostic pop
}

@end

