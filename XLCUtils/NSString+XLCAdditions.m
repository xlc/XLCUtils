//
//  NSString+XLCAdditions.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14-4-22.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import "NSString+XLCAdditions.h"

@implementation NSString (XLCAdditions)

- (BOOL)xlc_hasNonWhitespaceCharacter
{
    NSCharacterSet *charSet = [NSCharacterSet whitespaceCharacterSet];
    for (NSUInteger i = 0, len = [self length]; i < len; ++i) {
        unichar c = [self characterAtIndex:i];
        if (![charSet characterIsMember:c]) {
            return YES;
        }
    }
    return NO;
}

@end
