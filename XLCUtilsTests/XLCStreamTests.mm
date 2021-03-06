//
//  XLCStreamTests.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14-4-27.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <iostream>
#include <deque>
#include <vector>
#include <set>

#import "XLCStream.hh"

namespace {
    struct Foo
    {
        int value;
        int copyCount;
        int moveCount;
        bool valid = true;
        
        Foo() = delete;
        
        ~Foo()
        {
            valid = false;
            value = copyCount = moveCount = -1;
        }
        
        Foo(int val)
        : value(val), copyCount(0), moveCount(0)
        {}
        
        Foo(Foo && foo)
        : value(foo.value), copyCount(foo.copyCount), moveCount(foo.moveCount+1)
        {
            foo.valid = false;
        }
        
        Foo(const Foo & foo)
        : value(foo.value), copyCount(foo.copyCount+1), moveCount(foo.moveCount)
        {}
        
        Foo & operator=(Foo &&) = delete;
        Foo & operator=(Foo const&) = delete;
        
        void assertValue(id self, int val) const
        {
            assertValid(self);
            XCTAssertEqual(value, val);
        }
        
        void assertMoveCount(id self, int count) const
        {
            assertValid(self);
            XCTAssert(moveCount <= count, "moveCount actual: %d, expected: %d", moveCount, count);
        }
        
        void assertCopyCount(id self, int count) const
        {
            assertValid(self);
            XCTAssert(copyCount <= count, "copyCount actual: %d, expected: %d", copyCount, count);
        }
        
        void assertValid(id self) const
        {
            XCTAssertTrue(valid);
            XCTAssert(copyCount >= 0);
            XCTAssert(moveCount >= 0);
        }
    };
}

@interface XLCStreamTests : XCTestCase

@end

@implementation XLCStreamTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFromDeque
{
    int count = 4;
    std::deque<Foo> vec;
    vec.emplace_back(4);
    vec.emplace_back(3);
    vec.emplace_back(2);
    vec.emplace_back(1);
    
    xlc::from(vec)
    .each([&](auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        e.assertValue(self, count--);
        e.assertCopyCount(self, 1);
        e.assertMoveCount(self, 0);
    });
}

- (void)testFromDequeMove
{
    int count = 4;
    std::deque<Foo> vec;
    vec.emplace_back(4);
    vec.emplace_back(3);
    vec.emplace_back(2);
    vec.emplace_back(1);
    
    xlc::from(std::move(vec))
    .each([&](auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        e.assertValue(self, count--);
        e.assertCopyCount(self, 0);
        e.assertMoveCount(self, 0);
    });
}

- (void)testFromArray
{
    int count = 4;
    Foo vec[4] = { 4,3,2,1 };
    
    xlc::from(vec)
    .each([&](auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        e.assertValue(self, count--);
        e.assertCopyCount(self, 0);
        e.assertMoveCount(self, 0);
    });
}

- (void)testFromIterator
{
    int count = 4;
    std::deque<Foo> vec;
    vec.emplace_back(4);
    vec.emplace_back(3);
    vec.emplace_back(2);
    vec.emplace_back(1);
    
    xlc::from(vec.begin(), vec.end())
    .each([&](auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        e.assertValue(self, count--);
        e.assertCopyCount(self, 0);
        e.assertMoveCount(self, 0);
    });
}

- (void)testFromInitializerList
{
    int count = 4;
    
    xlc::from(std::initializer_list<Foo>{4,3,2,1})
    .each([&](auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        e.assertValue(self, count--);
        e.assertCopyCount(self, 0);
        e.assertMoveCount(self, 0);
    });
}

- (void)testFromRange
{
    int count = 4;
    
    std::deque<Foo> vec;
    vec.emplace_back(4);
    vec.emplace_back(3);
    vec.emplace_back(2);
    vec.emplace_back(1);
    
    auto range = xlc::from(std::move(vec));
    
    xlc::from(std::move(range))
    .each([&](auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        e.assertValue(self, count--);
        e.assertCopyCount(self, 0);
        e.assertMoveCount(self, 0);
    });
}

- (void)testFromNSArray
{
    XCTAssertEqualObjects(xlc::from(@[@1, @2, @"test3"]).to_NSArray(), (@[@1, @2, @"test3"]));
}

- (void)testFromNSDictionary
{
    XCTAssertEqualObjects(xlc::from(@{@1:@"a", @"b":@2}).to_NSDictionary(), (@{@1:@"a", @"b":@2}));
}

- (void)testFromNSDictionary2
{
    NSDictionary *dict = xlc::from(@{@1:@"a", @"b":@2}).take(1).concat({std::make_pair(@3, @"d")}).to_NSDictionary();
    XCTAssertEqual(dict.count, 2);
    XCTAssertEqual(dict[@3], @"d");
    XCTAssert([dict[@1] isEqual:@"a"] ^ [dict[@"b"] isEqual:@2], @"only one of them is true");
}

- (void)testEachStopFirst
{
    Foo vec[] = { 2, 3, 4, 5, 6 };
    int count = 0;
    Foo f {0};
    
    xlc::from(vec)
    .each([&, f](auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        count++;
        e.assertValue(self, 2);
        e.assertCopyCount(self, 0);
        e.assertMoveCount(self, 0);
        
        f.assertCopyCount(self, 1); // lambda is not copid
        return false;
    });
    
    XCTAssertEqual(count, 1);
}

- (void)testEachNoStop
{
    Foo vec[] = { 2, 3, 4, 5, 6 };
    int count = 0;
    Foo f {0};
    
    xlc::from(vec)
    .each([&, f](auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        count++;
        e.assertValue(self, count+1);
        e.assertCopyCount(self, 0);
        e.assertMoveCount(self, 0);
        
        f.assertCopyCount(self, 1); // lambda is not copid
    });
    
    XCTAssertEqual(count, 5);
}

- (void)testEachStopMiddle
{
    Foo vec[] = { 2, 3, 4, 5, 6 };
    int count = 0;
    Foo f {0};
    
    xlc::from(vec)
    .each([&, f](auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        count++;
        e.assertValue(self, count+1);
        e.assertCopyCount(self, 0);
        e.assertMoveCount(self, 0);
        
        f.assertCopyCount(self, 1); // lambda is not copid
        return count <= 2;
    });
    
    XCTAssertEqual(count, 3);
}

- (void)testMap
{
    int count = 0, count2 = 0;
    Foo f{0}, f2{0};
    
    xlc::from({3,4,5})
    .map([&, f](auto const &e) {
        static_assert(std::is_same<decltype(e), int const &>::value, "type is int");
        count++;
        XCTAssertEqual(e, count + 2);
        
        f.assertCopyCount(self, 1); // lambda is not copid
        return Foo{e};
    })
    .each([&, f2](auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        count2++;
        e.assertValue(self, count2+2);
        e.assertCopyCount(self, 0);
        e.assertMoveCount(self, 0);
        
        f2.assertCopyCount(self, 1); // lambda is not copid
    })
    ;
    
    XCTAssertEqual(count, 3);
    XCTAssertEqual(count2, 3);
}

- (void)testFilter
{
    int count = 4, count2 = 0;
    Foo f{0}, f2{0};
    
    std::deque<Foo> vec;
    vec.emplace_back(4);
    vec.emplace_back(3);
    vec.emplace_back(2);
    vec.emplace_back(1);
    
    xlc::from(std::move(vec))
    .filter([&, f](auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        e.assertValue(self, count--);
        
        f.assertCopyCount(self, 1); // lambda is not copid
        return e.value % 2;
    })
    .each([&, f2](auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        count2++;
        e.assertValue(self, count2 == 1 ? 3 : 1);
        e.assertCopyCount(self, 0);
        e.assertMoveCount(self, 0);
        
        f2.assertCopyCount(self, 1); // lambda is not copid
    })
    ;
    
    XCTAssertEqual(count, 0);
    XCTAssertEqual(count2, 2);
}

- (void)testFlatten
{
    int count = 0;
    Foo f{0};
    
    std::deque<std::deque<Foo>> vec;
    vec.emplace_back();
    vec[0].emplace_back(1);
    vec[0].emplace_back(2);
    vec[0].emplace_back(3);
    vec.emplace_back();
    vec[1].emplace_back(4);
    vec.emplace_back();
    vec.emplace_back();
    vec[3].emplace_back(5);
    vec[3].emplace_back(6);
    vec.emplace_back();
    
    xlc::from(std::move(vec))
    .flatten()
    .each([&, f](Foo const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        count++;
        e.assertValue(self, count);
        e.assertCopyCount(self, 1); // flatten have one copy
        e.assertMoveCount(self, 0);
        
        f.assertCopyCount(self, 1);
    });
    
    XCTAssertEqual(count, 6);
}

- (void)testFlatten2
{
    int count = 0;
    Foo f{0};
    
    xlc::from({0,1,2})
    .map([](auto const &e) {
        return std::deque<Foo>(e, e);
    })
    .flatten()
    .each([&, f](Foo const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        count++;
        e.assertValue(self, count == 1 ? 1 : 2);
        e.assertCopyCount(self, 2); // flatten have one copy, deque have one
        e.assertMoveCount(self, 0);
        
        f.assertCopyCount(self, 1);
    });
    
    XCTAssertEqual(count, 3);
}

- (void)testFlattenMap
{
    int count = 0;
    Foo f{0};
    
    xlc::from({0,1,2})
    .flatten_map([](auto const &e) {
        return std::deque<Foo>(e, e);
    })
    .each([&, f](Foo const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        count++;
        e.assertValue(self, count == 1 ? 1 : 2);
        e.assertCopyCount(self, 1); // only one from deque
        e.assertMoveCount(self, 0);
        
        f.assertCopyCount(self, 1);
    });
    
    XCTAssertEqual(count, 3);
}

- (void)testConcat
{
    Foo vec[] = { 1,2,3 };
    Foo vec2[] = { 4,5,6 };
    std::deque<Foo> vec3;
    vec3.emplace_back(9);
    int count = 0;
    Foo f {0};
    
    xlc::from(vec)
    .concat(std::deque<Foo>{}) // empty
    .concat(vec2)
    .concat({Foo{7}, Foo{8}})
    .concat(std::move(vec3))
    .concat(xlc::from({Foo{10}}))
    .each([&, f](auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        count++;
        e.assertValue(self, count);
        e.assertCopyCount(self, 0);
        e.assertMoveCount(self, 0);
        
        f.assertCopyCount(self, 1); // lambda is not copid
    });
    
    XCTAssertEqual(count, 10);
}

- (void)testFold
{
    int count = 0;
    Foo f{0};
    auto result =
    xlc::from(std::deque<Foo>{1,2,3,4})
    .fold(5, [&, f](auto const &sum, auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        count++;
        e.assertValue(self, count);
        e.assertCopyCount(self, 1);
        e.assertMoveCount(self, 0);
        
        f.assertCopyCount(self, 1); // lambda is not copid
        return sum + e.value;
    });
    
    XCTAssertEqual(result, 15);
}

- (void)testFold2
{
    int count = 1; // first one skipped
    Foo f{0};
    auto result =
    xlc::from(std::deque<Foo>{1,2,3,4})
    .fold([&, f](auto const &sum, auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        count++;
        e.assertValue(self, count);
        e.assertCopyCount(self, 1);
        e.assertMoveCount(self, 0);
        
        f.assertCopyCount(self, 1); // lambda is not copid
        return Foo{sum.value + e.value};
    });
    
    XCTAssertEqual(result->value, 10);
}

- (void)testFold3
{
    auto result =
    xlc::from(std::deque<Foo>{})
    .fold([&](auto const &sum, auto const &e) {
        XCTFail("should not be called");
        return sum;
    });
    
    XCTAssertFalse(result, "no result");
}

- (void)testEmpty
{
    XCTAssertTrue(xlc::from(std::deque<int>{}).empty());
    XCTAssertFalse(xlc::from({1}).empty());
    XCTAssertTrue(xlc::from({1}).filter([](auto const &e){return false;}).empty());
    XCTAssertFalse(xlc::from(std::deque<int>{}).concat({0}).empty());
    XCTAssertTrue(xlc::from(std::deque<int>{}).concat(std::deque<int>{}).empty());
}

- (void)testAny
{
    XCTAssertFalse(xlc::from(std::deque<int>{}).any());
    XCTAssertTrue(xlc::from({1}).any());
    XCTAssertFalse(xlc::from({1}).filter([](auto const &e){return false;}).any());
    XCTAssertTrue(xlc::from(std::deque<int>{}).concat({0}).any());
    XCTAssertFalse(xlc::from(std::deque<int>{}).concat(std::deque<int>{}).any());
}

- (void)testAnyFalse
{
    Foo f{0};
    int count = 0;
    bool result =
    xlc::from(std::deque<Foo>{1,2,3})
    .any([&, f](auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        count++;
        e.assertValue(self, count);
        e.assertCopyCount(self, 1);
        e.assertMoveCount(self, 0);
        
        f.assertCopyCount(self, 1); // lambda is not copid
        return false;
    });
    
    XCTAssertFalse(result);
    XCTAssertEqual(count, 3);
}

- (void)testAnyTrue
{
    Foo f{0};
    int count = 0;
    bool result =
    xlc::from(std::deque<Foo>{1,2,3})
    .any([&, f](auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        count++;
        e.assertValue(self, 1);
        e.assertCopyCount(self, 1);
        e.assertMoveCount(self, 0);
        
        f.assertCopyCount(self, 1); // lambda is not copid
        return true;
    });
    
    XCTAssertTrue(result);
    XCTAssertEqual(count, 1);
}

- (void)testAllFalse
{
    Foo f{0};
    int count = 0;
    bool result =
    xlc::from(std::deque<Foo>{1,2,3})
    .all([&, f](auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        count++;
        e.assertValue(self, count);
        e.assertCopyCount(self, 1);
        e.assertMoveCount(self, 0);
        
        f.assertCopyCount(self, 1); // lambda is not copid
        return true;
    });
    
    XCTAssertTrue(result);
    XCTAssertEqual(count, 3);
}

- (void)testAllTrue
{
    Foo f{0};
    int count = 0;
    bool result =
    xlc::from(std::deque<Foo>{1,2,3})
    .all([&, f](auto const &e) {
        static_assert(std::is_same<decltype(e), Foo const &>::value, "type is Foo");
        count++;
        e.assertValue(self, 1);
        e.assertCopyCount(self, 1);
        e.assertMoveCount(self, 0);
        
        f.assertCopyCount(self, 1); // lambda is not copid
        return false;
    });
    
    XCTAssertFalse(result);
    XCTAssertEqual(count, 1);
}

- (void)testFirst
{
    auto result = xlc::from({1,2,3}).first();
    XCTAssertEqual(*result, 1);
}

- (void)testFirstEmpty
{
    auto result = xlc::from(std::deque<int>{}).first();
    XCTAssertFalse(result);
}

- (void)testFirstEmpty2
{
    auto result = xlc::from({1,2,3}).filter([](auto const &e){return false;}).first();
    XCTAssertFalse(result);
}

- (void)testFirstOr
{
    auto result = xlc::from({1,2,3}).first_or(42);
    XCTAssertEqual(result, 1);
}

- (void)testFirstOrEmpty
{
    auto result = xlc::from({1,2,3}).filter([](auto const &e){return false;}).first_or(42);
    XCTAssertEqual(result, 42);
}

- (void)testSkip
{
    int count = 0;
    xlc::from({0,1,2,3})
    .skip(1)
    .each([&](auto const &e) {
        count++;
        XCTAssertEqual(count, e);
    });
    
    XCTAssertEqual(count, 3);
}

- (void)testSkipEmpty
{
    xlc::from(std::deque<int>{})
    .skip(1)
    .each([&](auto const &e) {
        XCTFail("should not be called");
    });
}

- (void)testSkipEmpty2
{
    xlc::from({1,2})
    .skip(3)
    .each([&](auto const &e) {
        XCTFail("should not be called");
    });
}

- (void)testSkipWithFilter
{
    int count = 0;
    xlc::from({1,2,3,4,5,6})
    .filter([](auto const &e) {
        return e % 2 == 0;
    })
    .skip(2)
    .each([&](auto const &e) {
        XCTAssertEqual(e, 6);
        count++;
    });
    XCTAssertEqual(count, 1);
}

- (void)testSkipWithFilter2
{
    int count = 0;
    xlc::from({1,2,3,4,5,6})
    .skip(2)
    .filter([](auto const &e) {
        return e % 2 == 0;
    })
    .each([&](auto const &e) {
        XCTAssertEqual(e, count == 0 ? 4 : 6);
        count++;
    });
    XCTAssertEqual(count, 2);
}

- (void)testSkipWithConcat
{
    int count = 0;
    xlc::from({1,2,3})
    .concat({4,5})
    .skip(2)
    .each([&](auto const &e) {
        XCTAssertEqual(e, count+3);
        count++;
    });
    XCTAssertEqual(count, 3);
}

- (void)testSkipWithConcat2
{
    int count = 0;
    xlc::from({1,2,3})
    .skip(2)
    .concat({4,5})
    .each([&](auto const &e) {
        XCTAssertEqual(e, count+3);
        count++;
    });
    XCTAssertEqual(count, 3);
}

- (void)testSkipWithConcat3
{
    int count = 0;
    xlc::from({1,2,3})  // {1,2,3}
    .skip(4)            // {}
    .concat({4,5})      // {4,5}
    .skip(1)            // {5}
    .each([&](auto const &e) {
        XCTAssertEqual(e, 5);
        count++;
    });
    XCTAssertEqual(count, 1);
}

- (void)testSkipWithFlattenConcat
{
    int count = 0;
    xlc::from(std::deque<std::deque<int>> { { 1, 2 }, { 3, 4} })
    .flatten()
    .skip(1)
    .concat({5,6})
    .skip(1)
    .each([&](auto const &e){
        XCTAssertEqual(e, count+3);
        count++;
    });
    
    XCTAssertEqual(count, 4);
}

- (void)testTakeEmpty
{
    xlc::from(std::deque<int>{})
    .take(1)
    .each([&](auto const &e) {
        XCTFail("should not be called");
    });
}

- (void)testTakeTooMuch
{
    int count = 0;
    xlc::from({1,2})
    .take(3)
    .each([&](auto const &e) {
        count++;
        XCTAssertEqual(e, count);
    });
    XCTAssertEqual(count, 2);
}

- (void)testTakeWithFilter
{
    int count = 0;
    xlc::from({1,2,3,4,5,6})
    .filter([](auto const &e) {
        return e % 2 == 0;
    })
    .take(2)
    .each([&](auto const &e) {
        XCTAssertEqual(e, count == 0 ? 2 : 4);
        count++;
    });
    XCTAssertEqual(count, 2);
}

- (void)testTakeWithFilter2
{
    int count = 0;
    xlc::from({1,2,3,4,5,6})
    .take(3)
    .filter([](auto const &e) {
        return e % 2 == 0;
    })
    .each([&](auto const &e) {
        XCTAssertEqual(e, 2);
        count++;
    });
    XCTAssertEqual(count, 1);
}

- (void)testTakeWithConcat
{
    int count = 0;
    xlc::from({1,2,3})
    .concat({4,5})
    .take(2)
    .each([&](auto const &e) {
        count++;
        XCTAssertEqual(e, count);
    });
    XCTAssertEqual(count, 2);
}

- (void)testTakeWithConcat2
{
    int count = 0;
    xlc::from({1,2,5,6})
    .take(2)
    .concat({3,4})
    .each([&](auto const &e) {
        count++;
        XCTAssertEqual(e, count);
    });
    XCTAssertEqual(count, 4);
}

- (void)testTakeWithConcat3
{
    int count = 0;
    xlc::from({1,2,4})  // {1,2,4}
    .take(2)            // {1,2}
    .concat({3,5})      // {1,2,3,5}
    .take(3)            // {1,2,3}
    .each([&](auto const &e) {
        count++;
        XCTAssertEqual(e, count);
    });
    XCTAssertEqual(count, 3);
}

- (void)testTakeWithFlattenConcat
{
    int count = 0;
    xlc::from(std::deque<std::deque<int>> { { 1, 2 }, { 3, 8} })
    .flatten()
    .take(3)
    .concat({4,5})
    .take(4)
    .each([&](auto const &e){
        count++;
        XCTAssertEqual(e, count);
    });
    XCTAssertEqual(count, 4);
}

- (void)testTake0
{
    xlc::make_stream<int>([&](auto &&){ XCTFail("should not be called"); return true; })
    .take(0)
    .each([&](auto const &){ XCTFail("should not be called"); });
}

- (void)testTake1
{
    bool called = false;
    xlc::make_stream<int>([&](auto && outputFunc){ XCTAssertFalse(outputFunc(1), "should stop"); return false; })
    .take(1)
    .each([&](auto const &){ XCTAssertFalse(called, "should called only once"); called = true; });
    XCTAssert(called);
}

- (void)testSkipTake
{
    xlc::from({1,2,3,4,5,6,7,8})
    .take(6)
    .skip(2)
    .take(2)
    .skip(1)
    .each([&](auto const &e){
        XCTAssertEqual(e, 4);
    });
}

- (void)testSkipWhile
{
    int count = 0, count2 = 0;
    xlc::from({1,2,3,4,5})
    .skip_while([&](auto const &e) {
        count++;
        XCTAssertEqual(e, count);
        return e < 3;
    })
    .each([&](auto const &e){
        XCTAssertEqual(e, count2 + 3);
        count2++;
    });
    XCTAssertEqual(count, 3);
    XCTAssertEqual(count2, 3);
}

- (void)testSkipWhileTrue
{
    int count = 0;
    xlc::from({1,2,3,4,5})
    .skip_while([&](auto const &e) {
        count++;
        XCTAssertEqual(e, count);
        return true;
    })
    .each([&](auto const &e){
        XCTFail("should not be called");
    });
    XCTAssertEqual(count, 5);
}

- (void)testSkipWhileFalse
{
    int count = 0;
    xlc::from({1,2,3,4,5})
    .skip_while([&](auto const &e) {
        XCTAssertEqual(e, 1);
        return false;
    })
    .each([&](auto const &e){
        count++;
        XCTAssertEqual(e, count);
    });
    XCTAssertEqual(count, 5);
}

- (void)testTakeWhile
{
    int count = 0, count2 = 0;
    xlc::from({1,2,3,4,5})
    .take_while([&](auto const &e) {
        count++;
        XCTAssertEqual(e, count);
        return e < 3;
    })
    .each([&](auto const &e){
        count2++;
        XCTAssertEqual(e, count2);
    });
    XCTAssertEqual(count, 3);
    XCTAssertEqual(count2, 2);
}

- (void)testTakeWhileTrue
{
    int count = 0, count2 = 0;
    xlc::from({1,2,3,4,5})
    .take_while([&](auto const &e) {
        count++;
        XCTAssertEqual(e, count);
        return true;
    })
    .each([&](auto const &e){
        count2++;
        XCTAssertEqual(e, count);
    });
    XCTAssertEqual(count, 5);
    XCTAssertEqual(count2, 5);
}

- (void)testTakeWhileFalse
{
    int count = 0;
    xlc::from({1,2,3,4,5})
    .take_while([&](auto const &e) {
        count++;
        XCTAssertEqual(e, 1);
        return false;
    })
    .each([&](auto const &e){
        XCTFail("should not be called");
    });
    XCTAssertEqual(count, 1);
}

- (void)testTakeWhileWithFlattenConcat
{
    int count = 0;
    xlc::from(std::deque<std::deque<int>> { { 1, 2 }, { 3, 8} })
    .flatten()
    .take_while([](auto const &e) {
        return e <= 3;
    })
    .concat({4,5})
    .take_while([](auto const &e) {
        return e <= 4;
    })
    .each([&](auto const &e){
        count++;
        XCTAssertEqual(e, count);
    });
    XCTAssertEqual(count, 4);
}

- (void)testCopyToVector
{
    std::vector<int> vec;
    xlc::from({1,2,3,4}).copy_to(std::back_inserter(vec));
    
    XCTAssertEqual(vec, (std::vector<int>{1,2,3,4}));
}

- (void)testCopyToSet
{
    std::set<int> set;
    xlc::from({1,2,2,3,4,4}).copy_to(std::inserter(set, set.end()));
    
    XCTAssertEqual(set, (std::set<int>{1,2,3,4}));
}

- (void)testCopyWithCount
{
    int arr[3] = {0,0,0};
    xlc::from({1,2,3,4}).copy_to(arr, 2);
    XCTAssertEqual(arr[0], 1);
    XCTAssertEqual(arr[1], 2);
    XCTAssertEqual(arr[2], 0, "no overflow");
}

- (void)testToVector
{
    auto vec = xlc::from({1,2,3,4}).to_vector();
    XCTAssertEqual(vec, (std::vector<int>{1,2,3,4}));
}

- (void)testToDeque
{
    auto vec = xlc::from({1,2,3,4}).to_deque();
    XCTAssertEqual(vec, (std::deque<int>{1,2,3,4}));
}

- (void)testToSet
{
    auto vec = xlc::from({1,1,2,3,4}).to_set();
    XCTAssertEqual(vec, (std::set<int>{1,2,3,4}));
}

- (void)testToList
{
    auto vec = xlc::from(std::deque<Foo>{1,2,3,4}).to_list();
    int count = 1;
    for (auto &e : vec)
    {
        e.assertValue(self, count++);
        e.assertCopyCount(self, 2);
        e.assertMoveCount(self, 0);
    }
}

- (void)testToMap
{
    auto map = xlc::from(std::initializer_list<std::pair<int, std::string>>{{1,"a"},{3,"b"}}).to_map();
    XCTAssertEqual(map, (std::map<int, std::string>{{1,"a"},{3,"b"}}));
}

- (void)testToNSArray
{
    id vec[] = {nil, @1, nil, @2, nil};
    XCTAssertEqualObjects(xlc::from(vec).to_NSArray(),
                          (@[[NSNull null], @1, [NSNull null], @2, [NSNull null]]));
}

- (void)testToNSDictionary
{
    XCTAssertEqualObjects(xlc::from(std::deque<std::pair<id, id>>{{nil, @1}, {@2, nil}, {nil, nil}}).to_NSDictionary(),
                          (@{[NSNull null] : @1}));
}

- (void)testCount
{
    XCTAssertEqual(xlc::from(std::deque<int>{}).count(), 0);
    XCTAssertEqual(xlc::from({1}).count(), 1);
    XCTAssertEqual(xlc::from({1,1}).count(), 2);
    XCTAssertEqual(xlc::from({1,1,2}).count(), 3);
}

- (void)testCount2
{
    auto result = xlc::from({1,2,3,4,5,6,7,0,5,0})
    .count([](auto const &e) {
        return e < 4;
    });
    XCTAssertEqual(result, 5);
}

- (void)testMax
{
    auto result = xlc::from({1,2,0,6,2,3}).max();
    XCTAssertEqual(*result, 6);
}

- (void)testMax2
{
    Foo vec[] = {1,2,0,6,2,3};
    auto result = xlc::from(vec).max([](auto const &a, auto const &b){ return a.value < b.value; });
    XCTAssertEqual(result->value, 6);
}

- (void)testMin
{
    auto result = xlc::from({1,2,0,6,2,3}).min();
    XCTAssertEqual(*result, 0);
}

- (void)testMin2
{
    Foo vec[] = {1,2,0,6,2,3};
    auto result = xlc::from(vec).min([](auto const &a, auto const &b){ return a.value < b.value; });
    XCTAssertEqual(result->value, 0);
}

- (void)testRepeat0
{
    XCTAssertEqual(xlc::from({1,2}).repeat(0).count(), 0);
}

- (void)testRepeat1
{
    Foo vec[] = {1,2,3};
    int count = 0;
    xlc::from(vec)
    .repeat(1)
    .each([&](auto const &e){
        e.assertValue(self, ++count);
        e.assertCopyCount(self, 0);
        e.assertMoveCount(self, 0);
    });
    
    XCTAssertEqual(count, 3);
}

- (void)testRepeat3
{
    Foo vec[] = {1,2,3};
    int count = 0;
    xlc::from(vec)
    .repeat(3)
    .each([&](auto const &e){
        e.assertValue(self, count++ % 3 + 1);
        e.assertCopyCount(self, 1);
        e.assertMoveCount(self, 0);
    });
    
    XCTAssertEqual(count, 9);
}

- (void)testRepeatInfnite
{
    Foo vec[] = {1,2,3};
    int count = 0;
    xlc::from(vec)
    .repeat()
    .take(10)
    .each([&](auto const &e){
        e.assertValue(self, count++ % 3 + 1);
        e.assertCopyCount(self, 1);
        e.assertMoveCount(self, 0);
    });
    
    XCTAssertEqual(count, 10);
}

- (void)testRepeatWithTake
{
    bool called = false;
    xlc::make_stream<int>([&](auto && outputFunc){
        XCTAssertFalse(outputFunc(1), "should stop");
        return true;
    })
    .repeat(3)
    .take(1)
    .each([&](auto const &e){
        XCTAssertFalse(called, "called only once");
        called = true;
    });
    
    XCTAssertTrue(called);
}

- (void)testRepeatInfniteWithTake
{
    bool called = false;
    xlc::make_stream<int>([&](auto && outputFunc){
        XCTAssertFalse(outputFunc(1), "should stop");
        return true;
    })
    .repeat()
    .take(1)
    .each([&](auto const &e){
        XCTAssertFalse(called, "called only once");
        called = true;
    });
    
    XCTAssertTrue(called);
}

- (void)testRepeatTakeSkipConcat
{
    auto result = xlc::from({1,2})
    .repeat()   // {1,2,....
    .take(3)    // {1,2,1}
    .repeat(2)  // {1,2,1,1,2,1}
    .take(4)    // {1,2,1,1}
    .concat({3,4}) // {1,2,1,1,3,4}
    .skip(1)    // {2,1,1,3,4}
    .repeat(2)  // {2,1,1,3,4,2,1,1,3,4}
    .skip(2)    // {1,3,4,2,1,1,3,4}
    .take(3)    // {1,3,4}
    .repeat()   // {1,3,4.....
    .take(8)    // {1,3,4,1,3,4,1,3}
    .to_deque();
    
    XCTAssertEqual(result, (std::deque<int>{1,3,4,1,3,4,1,3}));
}

- (void)testRange
{
    XCTAssertEqual(xlc::range(0).to_deque(), (std::deque<int>{}));
    XCTAssertEqual(xlc::range(5).to_deque(), (std::deque<int>{0,1,2,3,4}));
    XCTAssertEqual(xlc::range(3.3).to_deque(), (std::deque<double>{0,1,2,3}));
    XCTAssertEqual(xlc::range(-3,3).to_deque(), (std::deque<int>{-3,-2,-1,0,1,2}));
    XCTAssertEqual(xlc::range(5,20,5).to_deque(), (std::deque<int>{5,10,15}));
    XCTAssertEqual(xlc::range(0.0,1.0,0.4).to_deque(), (std::deque<double>{0,0.4,0.8}));
    auto result = xlc::range(1,50,[](int i){return i * 2; }).to_deque();
    XCTAssertEqual(result, (std::deque<int>{1,2,4,8,16,32}));
}

- (void)testRange2
{
    auto result = xlc::range(1, [](int i){return i*2;}).take(5).to_deque();
    XCTAssertEqual(result, (std::deque<int>{1,2,4,8,16}));
}

- (void)testEvaluate
{
    int i = 0;
    auto stream = xlc::make_stream<Foo>([&](auto && outputFunc) {
        for (i = 0; i < 5; ++i)
        {
            if (!outputFunc(Foo{i})) return false;
        }
        return true;
    });
    auto evaluator = std::move(stream).evaluate();
    
    for (auto it = evaluator.begin(), end = evaluator.end(); it != end; ++it) {
        it->assertValue(self, i);
        it->assertCopyCount(self, 0);
        it->assertMoveCount(self, 0);
    }
}

- (void)testEvaluate2
{
    std::vector<int> vec;
    auto evaluator = xlc::from({0,1,2,3,4,5,6}).skip(2).take(2).evaluate();
    
    std::copy(evaluator.begin(), evaluator.end(), std::back_inserter(vec));
    
    XCTAssertEqual(vec, (std::vector<int>{2,3}));
}

- (void)testEvaluate3
{
    int count = 1;
    for (auto i : xlc::from({0,1,2,3,4,5,6}).skip(2).take(3).evaluate())
    {
        XCTAssertEqual(i, ++count);
    }
    XCTAssertEqual(count, 4);
}

- (void)testEvaluateRethrowException
{
    auto stream = xlc::make_stream<int>([&](auto && outputFunc) {
        if (!outputFunc(1)) return false;
        if (!outputFunc(2)) return false;
        throw std::runtime_error("test exception");
    });
    
    auto evaluator = std::move(stream).evaluate();
    
    auto it = evaluator.begin();
    
    XCTAssertEqual(*it, 1);
    ++it;
    XCTAssertEqual(*it, 2);
    
    try {
        ++it;
        XCTFail("should throw exception");
    } catch (std::runtime_error &e) {
        XCTAssertEqualObjects(@(e.what()), @"test exception");
    }
}

- (void)testMergeInfiniteStream
{
    auto result =
    xlc::from({1,2})
    .repeat()
    .merge(xlc::from({1.0, 2.0, 3.0}).repeat())
    .take(6)
    .to_deque();
    
    XCTAssertEqual(result, (std::deque<std::tuple<int, double>>{{1,1.0},{2,2.0},{1,3.0},{2,1.0},{1,2.0},{2,3.0}}));
}

- (void)testMergeFiniteStream
{
    auto result =
    xlc::from({1,2,3})
    .merge({'a','b'})
    .to_deque();
    
    XCTAssertEqual(result, (std::deque<std::tuple<int, char>>{{1,'a'},{2,'b'}}));
}

- (void)testMergeFiniteStream2
{
    auto result =
    xlc::from({1,2})
    .merge({'a','b','c'})
    .to_deque();
    
    XCTAssertEqual(result, (std::deque<std::tuple<int, char>>{{1,'a'},{2,'b'}}));
}

- (void)testMergeEmptyStream
{
    auto result =
    xlc::from(std::deque<int>{})
    .merge({'a','b'})
    .to_deque();
    
    XCTAssertEqual(result, (std::deque<std::tuple<int, char>>{}));
}

- (void)testMergeEmptyStream2
{
    auto result =
    xlc::from({1,2})
    .merge(std::deque<char>{})
    .to_deque();
    
    XCTAssertEqual(result, (std::deque<std::tuple<int, char>>{}));
}

@end

