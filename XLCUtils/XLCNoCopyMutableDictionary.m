//
//  XLCNoCopyMutableDictionary.m
//  XLCUtils
//
//  Created by Xiliang Chen on 13-9-5.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XLCNoCopyMutableDictionary.h"

@implementation XLCNoCopyMutableDictionary {
    CFMutableDictionaryRef _dict;
}

- (id)initWithCapacity:(NSUInteger)numItems {
    self = [super init];
    if (self) {
        _dict = CFDictionaryCreateMutable(kCFAllocatorDefault, numItems, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    }
    return self;
}

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    CFDictionarySetValue(_dict, (__bridge const void *)(aKey), (__bridge const void *)(anObject));
}

- (void)removeObjectForKey:(id)aKey {
    CFDictionaryRemoveValue(_dict, (__bridge const void *)(aKey));
}

- (id)objectForKey:(id)aKey {
    return CFDictionaryGetValue(_dict, (__bridge const void *)(aKey));
}

- (NSUInteger)count {
    return CFDictionaryGetCount(_dict);
}

- (NSEnumerator *)keyEnumerator {
    return [(__bridge NSMutableDictionary *)_dict keyEnumerator];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    return [(__bridge NSMutableDictionary *)_dict countByEnumeratingWithState:state objects:buffer count:len];
}

@end
