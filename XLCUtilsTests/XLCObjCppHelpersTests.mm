//
//  XLCObjCppTests.m
//  XLCUtils
//
//  Created by Xiliang Chen on 14-4-26.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <vector>
#include <deque>
#include <sstream>

#include "XLCObjCppHelpers.hh"

@interface XLCObjCppTests : XCTestCase

@end

@implementation XLCObjCppTests

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

- (void)testStreamOperator
{
    std::stringstream stream;
    stream << @"test" << "cstr" << @1 << 2;
    XCTAssertEqualObjects(@(stream.str().c_str()), @"testcstr12");
}
    
- (void)testTypeDescription
{
    XCTAssertEqualObjects(@(xlc::type_description<int>().c_str()), @"int");
    XCTAssertEqualObjects(@(xlc::type_description<int&>().c_str()), @"int&");
    XCTAssertEqualObjects(@(xlc::type_description<int&&>().c_str()), @"int&&");
    XCTAssertEqualObjects(@(xlc::type_description<int const>().c_str()), @"int const");
    XCTAssertEqualObjects(@(xlc::type_description<int const&>().c_str()), @"int const&");
    XCTAssertEqualObjects(@(xlc::type_description<int const*>().c_str()), @"int const*");
    XCTAssertEqualObjects(@(xlc::type_description<int const*&>().c_str()), @"int const*&");
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunneeded-internal-declaration"

namespace test_callable_traits
{
    
    namespace lambda
    {
        auto f = [](){};
        using traits = typename xlc::callable_traits<decltype(f)>;
        static_assert(std::is_same<traits::return_type, void>::value, "");
        static_assert(std::is_same<traits::argument_type, std::tuple<>>::value, "");
    }
    
    namespace lambda2
    {
        auto f = [](double, int){return true;};
        using traits = typename xlc::callable_traits<decltype(f)>;
        static_assert(std::is_same<traits::return_type, bool>::value, "");
        static_assert(std::is_same<traits::argument_type, std::tuple<double, int>>::value, "");
        static_assert(std::is_same<traits::arg<0>, double>::value, "");
        static_assert(std::is_same<traits::arg<1>, int>::value, "");
    }
    
    namespace function
    {
        void f(void) {  }
        using traits = typename xlc::callable_traits<decltype(f)>;
        static_assert(std::is_same<traits::return_type, void>::value, "");
        static_assert(std::is_same<traits::argument_type, std::tuple<>>::value, "");
    }
    
    namespace function2
    {
        bool f(int) { return true; }
        using traits = typename xlc::callable_traits<decltype(f)>;
        static_assert(std::is_same<traits::return_type, bool>::value, "");
        static_assert(std::is_same<traits::argument_type, std::tuple<int>>::value, "");
        static_assert(std::is_same<traits::arg<0>, int>::value, "");
    }
    
    namespace function_pointer
    {
        void f(void) {  }
        using traits = typename xlc::callable_traits<decltype(&f)>;
        static_assert(std::is_same<traits::return_type, void>::value, "");
        static_assert(std::is_same<traits::argument_type, std::tuple<>>::value, "");
    }
    
    namespace function_pointer2
    {
        bool f(int) { return true; }
        using traits = typename xlc::callable_traits<decltype(&f)>;
        static_assert(std::is_same<traits::return_type, bool>::value, "");
        static_assert(std::is_same<traits::argument_type, std::tuple<int>>::value, "");
        static_assert(std::is_same<traits::arg<0>, int>::value, "");
    }
    
    namespace block
    {
        void (^f)(void);
        using traits = typename xlc::callable_traits<decltype(f)>;
        static_assert(std::is_same<traits::return_type, void>::value, "");
        static_assert(std::is_same<traits::argument_type, std::tuple<>>::value, "");
    }
    
    namespace block2
    {
        bool (^f)(double, int);
        using traits = typename xlc::callable_traits<decltype(f)>;
        static_assert(std::is_same<traits::return_type, bool>::value, "");
        static_assert(std::is_same<traits::argument_type, std::tuple<double, int>>::value, "");
        static_assert(std::is_same<traits::arg<0>, double>::value, "");
        static_assert(std::is_same<traits::arg<1>, int>::value, "");
    }
    
}

namespace test_is_for_loopable
{
    static_assert(xlc::is_for_loopable<std::vector<int>>::value, "");
    static_assert(xlc::is_for_loopable<std::deque<int>>::value, "");
    static_assert(!xlc::is_for_loopable<int>::value, "");
    static_assert(!xlc::is_for_loopable<void>::value, "");
    static_assert(!xlc::is_for_loopable<int*>::value, "");

    static_assert(xlc::is_for_loopable<int(&)[4]>::value, "array reference is loopable");
    static_assert(xlc::is_for_loopable<int[4]>::value, "array is loopable");
    
    struct Foo {};
    int *begin(Foo foo);
    int *end(Foo foo);
    
    static_assert(xlc::is_for_loopable<Foo>::value, "should use ADL to find begin/end");
}

namespace test_is_objc_class
{
    static_assert(xlc::is_objc_class<id>::value, "");
    static_assert(xlc::is_objc_class<NSObject *>::value, "");
    static_assert(xlc::is_objc_class<NSString *>::value, "");
    static_assert(xlc::is_objc_class<NSProxy *>::value, "");
    static_assert(!xlc::is_objc_class<std::vector<int>>::value, "");
    static_assert(!xlc::is_objc_class<std::deque<int>>::value, "");
    static_assert(!xlc::is_objc_class<int>::value, "");
    static_assert(!xlc::is_objc_class<void>::value, "");
}

namespace test_is_pair
{
    static_assert(xlc::is_pair<std::pair<int, bool>>::value, "");
    static_assert(xlc::is_pair<std::pair<std::string, double>>::value, "");
    static_assert(!xlc::is_pair<int>::value, "");
    static_assert(!xlc::is_pair<void>::value, "");
}

#pragma clang diagnostic pop

