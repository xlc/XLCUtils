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

@interface NSColor (XLCXMLCreation) <XLCXMLCreation>

@end

@implementation NSColor (XLCXMLCreation)

+ (id)xlc_createWithProperties:(XLCXMLObjectProperties *)props andContents:(NSArray *)contents {
    
    NSString *red = [props consume:@"red"];
    NSString *green = [props consume:@"green"];
    NSString *blue = [props consume:@"blue"];
    NSString *alpha = [props consume:@"alpha"];
    
    float a = alpha ? [alpha floatValue] : 1;
    
    if (red || green || blue) {
        float r = [red floatValue];
        float g = [green floatValue];
        float b = [blue floatValue];
        return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
    }
    
    NSString *hue = [props consume:@"hue"];
    NSString *sat = [props consume:@"saturation"];
    NSString *bri = [props consume:@"brightness"];
    
    if (hue || sat || bri) {
        float h = [hue floatValue];
        float s = [sat floatValue];
        float b = [bri floatValue];
        return [NSColor colorWithCalibratedHue:h saturation:s brightness:b alpha:a];
    }
    
    NSString *white = [props consume:@"white"];
    if (white) {
        float w = [white floatValue];
        if (w > 1) {
            w /= 255;
        }
        if (!alpha) {
            a = 1;
        }
        return [NSColor colorWithCalibratedWhite:w alpha:a];
    }
    
    NSString *name = [props consume:@"name"];
    SEL sel = NSSelectorFromString([name stringByAppendingString:@"Color"]);
    if ([NSColor respondsToSelector:sel]) {
        return [NSColor performSelector:sel];
    }
    
    NSString *value = [props consume:@"value"];
    if ([value hasPrefix:@"#"]) {
        value = [value substringFromIndex:1];
    }
    if ([value length]) {
        unsigned colorCode;

        NSScanner* scanner = [NSScanner scannerWithString:value];
        [scanner scanHexInt:&colorCode];

        CGFloat r = ((colorCode >> 16) & 0xFF) / (CGFloat)0xFF;
        CGFloat g = ((colorCode >> 8) & 0xFF) / (CGFloat)0xFF;
        CGFloat b = (colorCode & 0xFF) / (CGFloat)0xFF;
        
        return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
    }
    
    return [NSColor clearColor];
}

@end

