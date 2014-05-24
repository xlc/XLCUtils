//
//  UIKit+XLCXMLCreation.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14-5-24.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "XLCXMLCreation.h"

@interface UIColor (XLCXMLCreation) <XLCXMLCreation>

@end

@implementation UIColor (XLCXMLCreation)

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
        return [[UIColor alloc] initWithRed:r green:g blue:b alpha:a];
    }
    
    NSString *hue = [props consume:@"hue"];
    NSString *sat = [props consume:@"saturation"];
    NSString *bri = [props consume:@"brightness"];
    
    if (hue || sat || bri) {
        float h = [hue floatValue];
        float s = [sat floatValue];
        float b = [bri floatValue];
        return [[UIColor alloc] initWithHue:h saturation:s brightness:b alpha:a];
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
        return [[UIColor alloc] initWithWhite:w alpha:a];
    }
    
    NSString *name = [props consume:@"name"];
    SEL sel = NSSelectorFromString([name stringByAppendingString:@"Color"]);
    if ([UIColor respondsToSelector:sel]) {
        return [UIColor performSelector:sel];
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
        
        return [[UIColor alloc] initWithRed:r green:g blue:b alpha:a];
    }
    
    return [UIColor clearColor];
}

@end