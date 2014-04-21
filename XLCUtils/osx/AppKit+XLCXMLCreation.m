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
            [view addSubview:subview];
        }
    }
    
    return view;
}

@end

@interface NSFont (XLCXMLCreation) <XLCXMLCreation>

@end

@implementation NSFont (XLCXMLCreation)

+ (id)xlc_createWithProperties:(XLCXMLObjectProperties *)props andContents:(NSArray *)contents {
    NSString *name = [props consume:@"name"] ?: [props consume:@"family"] ?: [[NSFont systemFontOfSize:12] familyName];
    CGFloat size = [[props consume:@"size"] floatValue] ?: [NSFont systemFontSize];
    NSUInteger weight = [[props consume:@"weight"] intValue] ?: 5;
    BOOL bold = [[props consume:@"bold"] boolValue];
    BOOL italic = [[props consume:@"italic"] boolValue];
    
    NSFontTraitMask mask = (bold ? NSBoldFontMask : NSUnboldFontMask) | (italic ? NSItalicFontMask : NSUnitalicFontMask);
    
    return [[NSFontManager sharedFontManager] fontWithFamily:name traits:mask weight:weight size:size];
}

@end