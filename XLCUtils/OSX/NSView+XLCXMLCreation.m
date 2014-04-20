//
//  NSView+XLCXMLCreation.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14-4-20.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "XLCXMLCreation.h"

@interface NSView (XLCXMLCreation) <XLCXMLCreation>

@end

@implementation NSView (XLCXMLCreation)

+ (id)xlc_createWithProperties:(XLCXMLObjectProperties *)props andContents:(NSArray *)contents {
    NSView *view = [[self alloc] init];
    
    for (NSView *subview in contents) {
        if ([subview isKindOfClass:[NSView class]]) {
            [view addSubview:view];
        }
    }
    
    return view;
}

@end
