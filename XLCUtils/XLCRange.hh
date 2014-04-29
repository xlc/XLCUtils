//
//  XLCRange.hh
//  XLCUtils
//
//  Created by Xiliang Chen on 14-4-27.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#ifndef XLCUtils_XLCRange_hh
#define XLCUtils_XLCRange_hh

#if __cplusplus <= 201103L
#error "C++1y is required to compile this code"
#endif

#include <functional>
#include <type_traits>
#include <utility>
#include <iterator>
#include <memory>

#include "XLCObjCppHelpers.hh"

#define XLC_FORWARD_CAPTURE(var) var(std::forward<decltype(var)>(var))
#define XLC_MOVE_CAPTURE(var) var(std::move(var))
#define XLC_MOVE_CAPTURE_THIS(var) var(std::move(*this))

namespace xlc {
    
    namespace detail {
        
        template <class TElement, class TIterateFunc>
        class Range;
        
        template <class TElement, class TIterateFunc>
        auto make_range(TIterateFunc && func)
        {
            return Range<TElement, TIterateFunc>(std::move(func));
        }
        
        // from
        
        template <
        class TContainer,
        class = std::enable_if_t<xlc::is_for_loopable<TContainer>::value>
        >
        auto from(TContainer && container)
        {
            using std::begin;
            using TElement = typename std::iterator_traits<decltype(begin(std::declval<TContainer>()))>::value_type;
            
            auto func =
            [XLC_FORWARD_CAPTURE(container)]
            (auto && outfunc)
            {
                for(auto const & item : container) {
                    if (!outfunc(item)) return false;
                }
                return true;
            };
            return make_range<TElement>(std::move(func));
        }
        
        template <class TElement, std::size_t N>
        auto from(TElement (&array)[N])
        {
            auto func =
            [&array]
            (auto && outfunc)
            {
                for(auto const & item : array) {
                    if (!outfunc(item)) return false;
                }
                return true;
            };
            return make_range<TElement>(std::move(func));
        }
        
        template <class TElement>
        auto from(std::initializer_list<TElement> && container)
        {
            return from<std::initializer_list<TElement>>(std::forward<std::initializer_list<TElement>>(container));
        }
        
        template <class TIterator>
        auto from(TIterator first, TIterator last)
        {
            using TElement = typename std::iterator_traits<TIterator>::value_type;
            
            auto func =
            [first, last]
            (auto && outfunc) mutable
            {
                for(; first != last; ++first) {
                    if (!outfunc(*first)) return false;
                }
                return true;
            };
            return make_range<TElement>(std::move(func));
        }
        
        template <class T, class U>
        auto from(Range<T, U> && r)
        {
            return std::move(r);
        }
        
        // is_rangable
        
        template<typename T, typename V = void>
        struct is_rangable : std::false_type { };
        
        template<typename T>
        struct is_rangable<T,
        typename std::enable_if_t<!std::is_void<decltype(from(std::declval<T>()))>::value>
        > : std::true_type { };
        
        // range
        
        template <class TElement, class TIterateFunc>
        class Range
        {
        public:
            using value_type = TElement;
            
        private:
            TIterateFunc _iterateFunc;
            
        public:
            
            Range() = delete; // no default constructor
            
            Range(Range const &) = delete; // no copy constructor
            Range(Range &&) = default; // default move constructor
            
            Range & operator=(Range const &) = delete; // no copy assign
            Range & operator=(Range &&) = delete; // no move assign
            
            template <class T>
            explicit Range(T && func)
            : _iterateFunc(std::forward<T>(func))
            {}
            
            template <class TFunc>
            typename std::enable_if_t<
                std::is_void<decltype(std::declval<TFunc>()(std::declval<TElement>()))>::value, // TFunc return void
                bool // method return type
            >
            each(TFunc && func)
            {
                return each([XLC_FORWARD_CAPTURE(func)](auto const &elem) mutable {
                    func(elem);
                    return true;
                });
            }
            
            template <class TFunc>
            typename std::enable_if_t<
                std::is_same<decltype(std::declval<TFunc>()(std::declval<TElement>())), bool>::value, // TFunc return bool
                bool // method return type
            >
            each(TFunc && func)
            {
                return _iterateFunc(std::forward<TFunc>(func));
            }
            
            template <class TFunc>
            auto map(TFunc && func)
            {
                using TNewElement = decltype(func(std::declval<TElement>()));
                return make_range<TNewElement>
                ([XLC_FORWARD_CAPTURE(func),
                  XLC_MOVE_CAPTURE_THIS(me)]
                 (auto && outputFunc) mutable
                 {
                     return me.each([XLC_FORWARD_CAPTURE(outputFunc),
                                     XLC_FORWARD_CAPTURE(func)]
                                    (auto const & elem) mutable
                                    {
                                        return outputFunc(func(elem));
                                    });
                 });
            }
            
            template <class TFunc>
            auto filter(TFunc && func)
            {
                return make_range<TElement>
                ([XLC_FORWARD_CAPTURE(func),
                  XLC_MOVE_CAPTURE_THIS(me)]
                 (auto && outputFunc) mutable
                 {
                     return me.each([XLC_FORWARD_CAPTURE(outputFunc),
                                     XLC_FORWARD_CAPTURE(func)]
                                    (auto const & elem) mutable
                                    {
                                        if (func(elem)) {
                                            return outputFunc(elem);
                                        }
                                        return true;
                                    });
                 });
            }
            
            template <
            class U = TElement,
            class = typename std::enable_if<std::is_same<U, TElement>::value>::type,
            class = typename std::enable_if<is_rangable<U>::value>::type
            >
            auto flatten()
            {
                using TNewElement = typename decltype(from(std::declval<TElement>()))::value_type;
                return make_range<TNewElement>
                ([XLC_MOVE_CAPTURE_THIS(me)]
                 (auto && outputFunc) mutable
                 {
                     return me.each([XLC_FORWARD_CAPTURE(outputFunc)]
                                    (auto const & elem) mutable
                                    {
                                        return from(elem).each(outputFunc);
                                    });
                 });
            }
            
            template <class TFunc>
            auto flatten_map(TFunc && func)
            {
                using TMapResult = decltype(func(std::declval<TElement>()));
                static_assert(is_rangable<TMapResult>::value, "map result is not rangable");
                using TNewElement = typename decltype(from(std::declval<TMapResult>()))::value_type;
                return make_range<TNewElement>
                ([XLC_FORWARD_CAPTURE(func),
                  XLC_MOVE_CAPTURE_THIS(me)]
                 (auto && outputFunc) mutable
                 {
                     return me.each([XLC_FORWARD_CAPTURE(outputFunc),
                                     XLC_FORWARD_CAPTURE(func)]
                                    (auto const & elem) mutable
                                    {
                                        return from(func(elem)).each(outputFunc);
                                    });
                 });
            }
            
            template <class TContainer>
            auto concat(TContainer && container)
            {
                return make_range<TElement>
                ([XLC_MOVE_CAPTURE_THIS(me),
                  XLC_FORWARD_CAPTURE(container)]
                 (auto && outputFunc) mutable
                 {
                     return me.each(outputFunc) &&
                     from(std::forward<decltype(container)>(container)).each(outputFunc);
                 });
            }
            
            template <class T>
            auto concat(std::initializer_list<T> && container)
            {
                return concat<std::initializer_list<T>>(std::move(container));
            }
            
            template <class T, std::size_t N>
            auto concat(T (&container)[N])
            {
                return make_range<TElement>
                ([XLC_MOVE_CAPTURE_THIS(me),
                  &container]
                 (auto && outputFunc) mutable
                 {
                     return me.each(outputFunc) &&
                     from(container).each(outputFunc);
                 });
            }
            
            template <class = TElement> // without this line: "Debug information for auto is not yet supported"
            auto skip(std::size_t count)
            {
                return make_range<TElement>
                ([XLC_MOVE_CAPTURE_THIS(me),
                  count]
                 (auto && outputFunc) mutable
                 {
                     auto countCopy = count;
                     return me.each([XLC_FORWARD_CAPTURE(outputFunc),
                                     &countCopy]
                                    (auto const & elem) mutable
                                    {
                                        if (countCopy) {
                                            countCopy--;
                                            return true;
                                        }
                                        return outputFunc(elem);
                                    });
                 });
            }
            
            template <class TFunc>
            auto skip_while(TFunc && func)
            {
                return make_range<TElement>
                ([XLC_FORWARD_CAPTURE(func),
                  XLC_MOVE_CAPTURE_THIS(me)]
                 (auto && outputFunc) mutable
                {
                    bool shouldSkip = true;
                    return me.each([XLC_FORWARD_CAPTURE(outputFunc),
                                    XLC_FORWARD_CAPTURE(func),
                                    &shouldSkip]
                                   (auto const & elem) mutable
                                   {
                                       shouldSkip = shouldSkip && func(elem);
                                       if (shouldSkip) {
                                           return true;
                                       }
                                       return outputFunc(elem);
                                   });
                });
            }
            
            template <class = TElement> // without this line: "Debug information for auto is not yet supported"
            auto take(std::size_t count)
            {
                return make_range<TElement>
                ([XLC_MOVE_CAPTURE_THIS(me),
                  count]
                 (auto && outputFunc) mutable
                 {
                     auto continue_ = true;
                     auto countCopy = count;
                     me.each([XLC_FORWARD_CAPTURE(outputFunc),
                              &countCopy,
                              &continue_]
                             (auto const & elem) mutable
                             {
                                 if (countCopy) {
                                     countCopy--;
                                     continue_ = outputFunc(elem);
                                     return continue_;
                                 }
                                 return false;
                             });
                     return continue_;
                 });
            }
            
            template <class TFunc>
            auto take_while(TFunc && func)
            {
                return make_range<TElement>
                ([XLC_FORWARD_CAPTURE(func),
                  XLC_MOVE_CAPTURE_THIS(me)]
                 (auto && outputFunc) mutable
                 {
                     auto continue_ = true;
                     me.each([XLC_FORWARD_CAPTURE(outputFunc),
                                     XLC_FORWARD_CAPTURE(func),
                                     &continue_]
                                    (auto const & elem) mutable
                                    {
                                        if (func(elem)) {
                                            continue_ = outputFunc(elem);
                                            return continue_;
                                        }
                                        return false;
                                    });
                     return continue_;
                 });
            }
            
            template <class TFunc, class TResult>
            auto fold(TResult first, TFunc && func) -> TResult
            {
                each([&first, &func](auto const &elem){
                    first = func(first, elem);
                });
                return first;
            }
            
            template <class TFunc>
            auto fold(TFunc && func) -> std::unique_ptr<TElement> // std::optional<TElement>
            {
                std::unique_ptr<TElement> value;
                each([&value, &func](auto const &elem){
                    if (value) {
                        value = std::make_unique<TElement>(func(*value, elem));
                    } else {
                        value = std::make_unique<TElement>(elem);
                    }
                });
                return value;
            }
            
            auto empty() -> bool
            {
                bool ret = true;
                each([&ret](auto const &e){ ret = false; return false; });
                return ret;
            }
            
            auto any() -> bool
            {
                return !empty();
            }
            
            template <class TFunc>
            auto any(TFunc && func) -> bool
            {
                return filter(std::forward<TFunc>(func)).any();
            }
            
            template <class TFunc>
            auto all(TFunc && func) -> bool
            {
                return !filter([XLC_FORWARD_CAPTURE(func)](auto const &e){ return !func(e); }).any();
            }
            
            auto first() -> std::unique_ptr<TElement>
            {
                std::unique_ptr<TElement> value;
                each([&value](auto const &e){ value = std::make_unique<TElement>(e); return false; });
                return value;
            }
            
            auto first_or(TElement const &defaultValue) -> TElement
            {
                std::unique_ptr<TElement> value;
                each([&value](auto const &e){ value = std::make_unique<TElement>(e); return false; });
                if (value) return *value;
                return defaultValue;
            }
            
            template <class TOutputIterator>
            void copy_to(TOutputIterator iter)
            {
                each([&iter](auto const &e){ *iter++ = e; });
            }
            
            template <class TOutputIterator>
            void copy_to(TOutputIterator iter, std::size_t count)
            {
                take(count).each([&iter](auto const &e){ *iter++ = e; });
            }
        };
    }
    
    using detail::make_range;
    using detail::from;
}


#endif
