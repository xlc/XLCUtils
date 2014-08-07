//
//  XLCRandom.h
//  XLCUtils
//
//  Created by Xiliang Chen on 14/8/5.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XLCRandom : NSObject

+ (instancetype)random;
+ (instancetype)randomWithSeed:(uint64_t)seed;

- (instancetype)init;
- (instancetype)initWithSeed:(uint64_t)seed;

- (uint64_t)nextInt;    // [0, UINT64_MAX]
- (BOOL)nextBoolean;    // [false, true]
- (double)nextDouble;   // [0, 1)
- (double)nextGaussian; // mean = 0, sd = 1
- (double)nextGaussianWithMean:(double)mean sd:(double)sd;

- (int64_t)nextIntFrom:(int64_t)from to:(int64_t)to;  // [from, to)
- (uint64_t)nextIntWithUpperBound:(uint64_t)upper;      // [0, upper)

- (double)nextDoubleFrom:(double)from to:(double)to;    // [from, to)
- (double)nextDoubleWithUpperBound:(double)upper;           // [0, upper)

- (void)nextBytes:(void *)buff withLength:(NSUInteger)length;

- (id)choice:(NSArray *)array;
- (NSArray *)shuffle:(NSArray *)array;

- (instancetype)nextRandom;

@end
