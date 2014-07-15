//
//  XLCObjCppHelpers.hh
//  XLCUtils
//
//  Created by Xiliang Chen on 14-4-27.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#ifndef XLCUtils_XLCObjCppHelpers_hh
#define XLCUtils_XLCObjCppHelpers_hh

#include <type_traits>
#include <ostream>
#include <utility>
#include <string>
#include <typeinfo>
#include <memory>

#include <cxxabi.h>

#ifndef __has_builtin           // Optional of course.
#define __has_builtin(x) 0      // Compatibility with non-clang compilers.
#endif
#ifndef __has_feature           // Optional of course.
#define __has_feature(x) 0      // Compatibility with non-clang compilers.
#endif
#ifndef __has_extension
#define __has_extension __has_feature // Compatibility with pre-3.0 compilers.
#endif

namespace xlc {
    
    template <bool T, class U = void>
    using enable_if_t = typename std::enable_if<T, U>::type;
    
    // callable_traits
    
    namespace detail {
        template <class ReturnType, class... Args>
        struct callable_traits_base
        {
            using return_type = ReturnType;
            using argument_type = std::tuple<Args...>;
            
            template<std::size_t I>
            using arg = typename std::tuple_element<I, argument_type>::type;
        };
    }
    
    template <class T>
    struct callable_traits : callable_traits<decltype(&T::operator())>
    {};
    
    // lambda / functor
    template <class ClassType, class ReturnType, class... Args>
    struct callable_traits<ReturnType(ClassType::*)(Args...) const>
    : detail::callable_traits_base<ReturnType, Args...>
    {};
    
    // function pointer
    template <class ReturnType, class... Args>
    struct callable_traits<ReturnType(Args...)>
    : detail::callable_traits_base<ReturnType, Args...>
    {};
    
    template <class ReturnType, class... Args>
    struct callable_traits<ReturnType(*)(Args...)>
    : detail::callable_traits_base<ReturnType, Args...>
    {};
    
#if __has_extension(blocks)
    // block
    template <class ReturnType, class... Args>
    struct callable_traits<ReturnType(^)(Args...)>
    : detail::callable_traits_base<ReturnType, Args...>
    {};
#endif
    
    // is_pair
    
    template <class T>
    struct is_pair : std::false_type {};
    
    template <class T1, class T2>
    struct is_pair<std::pair<T1, T2>> : std::true_type {};
    
    // is_for_loopable
    
    namespace detail {
        namespace is_for_loopable {
            using std::begin;   // enable ADL
            
            template<class T, class V = void>
            struct is_for_loopable : std::false_type { };
            
            template<class T>
            struct is_for_loopable<T,
            typename xlc::enable_if_t<!std::is_void<decltype(begin(std::declval<T>()))>::value>
            > : std::true_type { };
            
            template<class T, std::size_t N>
            struct is_for_loopable<T[N]> : std::true_type { };
        }
    }
    
    using detail::is_for_loopable::is_for_loopable;
    
    // is_objc_class
    
    template<class T, class V = void>
    struct is_objc_class : std::false_type { };
    
#ifdef __OBJC__
    template<class T>
    struct is_objc_class<T,
    typename std::enable_if<std::is_convertible<T, id>::value>::type
    > : std::true_type { };
#endif
    
    // type_description
    
    template <class T>
    std::string type_description() {
        bool is_lvalue_reference = std::is_lvalue_reference<T>::value;
        bool is_rvalue_reference = std::is_rvalue_reference<T>::value;
        bool is_const = std::is_const<typename std::remove_reference<T>::type>::value;
        
        std::unique_ptr<char, void(*)(void*)>
        name {abi::__cxa_demangle(typeid(T).name(), nullptr, nullptr, nullptr), std::free};
        
        auto str = std::string(name.get());
        if (is_const) {
            str += " const";
        }
        if (is_lvalue_reference) {
            str += "&";
        }
        if (is_rvalue_reference) {
            str += "&&";
        }
        
        return str;
    }
}

#ifdef __OBJC__
template <
class T,
class = typename xlc::enable_if_t<xlc::is_objc_class<T>::value>
>
std::ostream& operator<< (std::ostream& stream, T const & t) {
    stream << [[t description] UTF8String];
    return stream;
}
#endif

#endif
