//
//  XLCRandom.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14/8/5.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import "XLCRandom.h"

#include <random>

@implementation XLCRandom {
    std::mt19937_64 _engine;
}

+ (instancetype)random
{
    return [[self alloc] init];
}

+ (instancetype)randomWithSeed:(uint64_t)seed
{
    return [[self alloc] initWithSeed:seed];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _engine.seed(arc4random());
    }
    return self;
}

- (instancetype)initWithSeed:(uint64_t)seed
{
    self = [super init];
    if (self) {
        _engine.seed(seed);
    }
    return self;
}

- (uint64_t)nextInt
{
    return std::uniform_int_distribution<uint64_t>()(_engine);
}

- (BOOL)nextBoolean
{
    return std::bernoulli_distribution(0.5)(_engine);
}

- (double)nextDouble
{
    return std::uniform_real_distribution<double>(0, 1)(_engine);
}

- (double)nextGaussian
{
    return std::normal_distribution<double>(0, 1)(_engine);
}

- (double)nextGaussianWithMean:(double)mean sd:(double)sd
{
    return std::normal_distribution<double>(mean, sd)(_engine);
}

- (int64_t)nextIntFrom:(int64_t)from to:(int64_t)to
{
    return std::uniform_int_distribution<int64_t>(from, to-1)(_engine);
}

- (uint64_t)nextIntWithUpperBound:(uint64_t)upper
{
    return std::uniform_int_distribution<uint64_t>(0, upper-1)(_engine);
}

- (double)nextDoubleFrom:(double)from to:(double)to
{
    return std::uniform_real_distribution<double>(from, to)(_engine);
}

- (double)nextDoubleWithUpperBound:(double)upper
{
    return std::uniform_real_distribution<double>(0, upper)(_engine);
}

- (void)nextBytes:(void *)buff withLength:(NSUInteger)length
{
    std::uniform_int_distribution<unsigned char> dist;
    std::generate_n(reinterpret_cast<char *>(buff), length, std::bind(dist, std::ref(_engine)));
}

- (id)choice:(NSArray *)array
{
    if ([array count] == 0) {
        return nil;
    }
    return array[(NSUInteger)[self nextIntWithUpperBound:[array count]]];
}

- (NSArray *)shuffle:(NSArray *)array
{
    if ([array count] == 0) {
        return array;
    }
    
    std::uniform_int_distribution<NSUInteger> dist;
    using param_t = std::uniform_int_distribution<NSUInteger>::param_type;
    
    NSMutableArray *mutableArr = [array mutableCopy];
    
    for (NSUInteger i = [array count]-1; i > 0; --i) {
        [mutableArr exchangeObjectAtIndex:i withObjectAtIndex:dist(_engine, param_t(0, i))];
    }
    
    return mutableArr;
}

- (instancetype)nextRandom
{
    return [[[self class] alloc] initWithSeed:[self nextInt]];
}

@end
