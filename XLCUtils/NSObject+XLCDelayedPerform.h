//
//  NSObject+XLCDelayedPerform.h
//  XLCUtils
//
//  Created by Xiliang Chen on 13-9-5.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (XLCDelayedPerform)

- (void)xlc_setNeedsPerformSelector:(SEL)selector withObject:(id)obj;
- (void)xlc_setNeedsPerformSelector:(SEL)selector withObject:(id)obj withinInterval:(NSTimeInterval)interval;
- (void)xlc_performSelectorIfNeeded:(SEL)selector;

@end
