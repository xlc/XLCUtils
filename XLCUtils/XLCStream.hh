//
//  XLCStream.hh
//  XLCUtils
//
//  Created by Xiliang Chen on 14-4-27.
//  Copyright (c) 2014年 Xiliang Chen. All rights reserved.
//

#ifndef XLCUtils_XLCStream_hh
#define XLCUtils_XLCStream_hh

#if __cplusplus <= 201103L
#error "C++1y is required to compile this code"
#endif

#include <functional>
#include <type_traits>
#include <utility>
#include <iterator>
#include <memory>
#include <vector>
#include <deque>
#include <set>
#include <list>
#include <map>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <exception>
#include <tuple>

#include "XLCObjCppHelpers.hh"

#define XLC_FORWARD_CAPTURE(var) var(std::forward<decltype(var)>(var))
#define XLC_MOVE_CAPTURE(var) var(std::move(var))
#define XLC_MOVE_CAPTURE_THIS(var) var(std::move(*this))

#define XLC_COMPILER_ERROR_HACK template <class = void> // without this line: "Debug information for auto is not yet supported"

namespace xlc {
    
    namespace detail {
        
        template <class TElement, class TIterateFunc>
        class Stream;
        
        template <class TElement, class TIterateFunc>
        auto make_stream(TIterateFunc && func)
        {
            return Stream<TElement, TIterateFunc>(std::move(func));
        }
        
#pragma mark - from
        
        template <
        class TContainer,
        class = std::enable_if_t<xlc::is_for_loopable<TContainer>::value>
        >
        auto from(TContainer && container)
        {
            using std::begin;
            using TElement = typename std::iterator_traits<decltype(begin(std::declval<TContainer>()))>::value_type;
            
            return make_stream<TElement>([XLC_FORWARD_CAPTURE(container)]
                                         (auto && outfunc)
                                         {
                                             for(auto const & item : container) {
                                                 if (!outfunc(item)) return false;
                                             }
                                             return true;
                                         });
        }
        
#ifdef __OBJC__
        XLC_COMPILER_ERROR_HACK
        auto from(id<NSFastEnumeration> container)
        {
            return make_stream<id>([container]
                                   (auto && outfunc)
                                   {
                                       for(id item in container) {
                                           if (!outfunc(item)) return false;
                                       }
                                       return true;
                                   });
        }
        
        XLC_COMPILER_ERROR_HACK
        auto from(NSDictionary * container)
        {
            return make_stream<std::pair<id, id>>
            ([container]
             (auto && outfunc)
             {
                 __block BOOL continue_ = true;
                 [container enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
                  continue_ = outfunc(std::make_pair(key, value));
                  *stop = !continue_;
                  }];
                 return continue_;
             });
        }
#endif
        
        template <class TElement, std::size_t N>
        auto from(TElement (&array)[N])
        {
            return make_stream<TElement>([&array]
                                         (auto && outfunc)
                                         {
                                             for(auto const & item : array) {
                                                 if (!outfunc(item)) return false;
                                             }
                                             return true;
                                         });
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
            
            return make_stream<TElement>([first, last]
                                         (auto && outfunc) mutable
                                         {
                                             for(; first != last; ++first) {
                                                 if (!outfunc(*first)) return false;
                                             }
                                             return true;
                                         });
        }
        
        template <class T, class U>
        auto from(Stream<T, U> && r)
        {
            return std::move(r);
        }
        
#pragma mark - range
        
        template <class T>
        auto range(T first, T last)
        {
            return make_stream<T>([first, last]
                                  (auto && outfunc) mutable
                                  {
                                      for(; first < last; ++first) {
                                          if (!outfunc(first)) return false;
                                      }
                                      return true;
                                  });
        }
        
        template <class T>
        auto range(T to)
        {
            return range(T{}, to);
        }
        
        template <class T>
        auto range(T first, T last, T step)
        {
            return make_stream<T>([first, last, step]
                                  (auto && outfunc) mutable
                                  {
                                      for(; first < last; first += step) {
                                          if (!outfunc(first)) return false;
                                      }
                                      return true;
                                  });
        }
        
        template <class T, class TFunc>
        auto range(T first, T last, TFunc && stepFunc)
        {
            return make_stream<T>([first, last, XLC_FORWARD_CAPTURE(stepFunc)]
                                  (auto && outfunc) mutable
                                  {
                                      for(; first < last; first = stepFunc(first)) {
                                          if (!outfunc(first)) return false;
                                      }
                                      return true;
                                  });
        }
        
        template <class T, class TFunc>
        auto range(T first, TFunc && stepFunc)
        {
            return make_stream<T>([first, XLC_FORWARD_CAPTURE(stepFunc)]
                                  (auto && outfunc) mutable
                                  {
                                      for(;; first = stepFunc(first)) {
                                          if (!outfunc(first)) return false;
                                      }
                                      return true;
                                  });
        }
        
#pragma mark - StreamEvaluator
        
        template <class TStream>
        class StreamEvaluator
        {
        private:
            using TElement = typename TStream::value_type;
            
        private:
            TStream _stream;
            bool _started = false;
            std::mutex _mutex {};
            std::condition_variable _condition {};
            std::thread _thread {};
            TElement const *_element = nullptr;
            bool _next = false;
            bool _done = false;
            bool _stop = false;
            std::exception_ptr _exception;
            
            auto start() -> TElement const *
            {
                if (_started) return nullptr;
                
                {
                    std::lock_guard<std::mutex> lk(_mutex);
                    if (_stop) return nullptr;
                }
                
                _thread = std::thread([this](){
                    try {
                        _stream.each([this](auto const &e){
                            {
                                std::lock_guard<std::mutex> lk(_mutex);
                                _element = &e;
                                _done = true;
                                _next = false;
                            }
                            // notify done
                            _condition.notify_one();
                            
                            // wait for next request
                            {
                                std::unique_lock<std::mutex> lk(_mutex);
                                _condition.wait(lk, [this]{return _stop || _next;});
                                
                                return !_stop;
                            }
                        });
                    } catch (...) {
                        std::lock_guard<std::mutex> lk(_mutex);
                        _exception = std::current_exception();
                    }
                    
                    // notify no more
                    {
                        std::lock_guard<std::mutex> lk(_mutex);
                        _element = nullptr;
                        _done = true;
                        _stop = true;
                    }
                    _condition.notify_one();
                });
                
                _started = true;
                
                // wait for done
                {
                    std::unique_lock<std::mutex> lk(_mutex);
                    _condition.wait(lk, [this]{return _done;});
                    
                    if (_exception) // oops
                    {
                        std::rethrow_exception(_exception);
                    }
                    
                    return _element;
                }
            }
            
            auto next() -> TElement const *
            {
                {
                    std::lock_guard<std::mutex> lk(_mutex);
                    if (_stop) return nullptr;
                }
                
                start();
                
                {
                    std::lock_guard<std::mutex> lk(_mutex);
                    _next = true;
                    _done = false;
                }
                _condition.notify_one();
                
                {
                    std::unique_lock<std::mutex> lk(_mutex);
                    _condition.wait(lk, [this]{return _done;});
                    
                    if (_exception) // oops
                    {
                        std::rethrow_exception(_exception);
                    }
                    
                    return _element;
                }
            }
            
        public:
            class StreamIterator : public std::iterator<std::input_iterator_tag, typename TStream::value_type>
            {
            private:
                StreamEvaluator *_evaluator;
                TElement const *_current = nullptr;
                
            public:
                explicit StreamIterator(StreamEvaluator *evaluator) : _evaluator(evaluator)
                {}
                
                auto operator* () -> TElement const &
                {
                    if (!_current) _current = _evaluator->start();
                    return *_current;
                }
                
                auto operator++() -> StreamIterator &
                {
                    _current = _evaluator->next();
                    return *this;
                }
                
                auto operator==(StreamIterator const &other) -> bool
                {
                    if (!_current) _current = _evaluator->start();
                    return _current == other._current;
                }
                
                auto operator!=(StreamIterator const &other) -> bool
                {
                    return !operator==(other);
                }
                
                auto operator->() -> TElement const *
                {
                    if (!_current) _current = _evaluator->start();
                    return _current;
                }
                
            };
            
        public:
            StreamEvaluator() = delete;
            StreamEvaluator(StreamEvaluator const &) = delete;
            
            StreamEvaluator(StreamEvaluator && evaluator)
            : _stream(std::move(evaluator._stream))
            {};
            
            StreamEvaluator & operator=(StreamEvaluator const &) = delete;
            StreamEvaluator & operator=(StreamEvaluator &&) = delete;
            
            explicit StreamEvaluator(TStream && stream)
            : _stream(std::move(stream))
            {}
            
            ~StreamEvaluator()
            {
                {
                    std::lock_guard<std::mutex> lk(_mutex);
                    _stop = true;
                    _condition.notify_all();
                }
                
                if (_thread.joinable()) {
                    _thread.join();
                }
            }
            
            auto begin() & -> StreamIterator
            {
                return StreamIterator{this};
            }
            
            auto end() & -> StreamIterator
            {
                return StreamIterator{nullptr};
            }
        };
        
#pragma mark - Stream
        
        template <class TElement, class TIterateFunc>
        class Stream
        {
        public:
            using value_type = TElement;
            
        private:
            TIterateFunc _iterateFunc;
            
        public:
            
            Stream() = delete; // no default constructor
            
            Stream(Stream const &) = delete; // no copy constructor
            Stream(Stream &&) = default; // default move constructor
            
            Stream & operator=(Stream const &) = delete; // no copy assign
            Stream & operator=(Stream &&) = delete; // no move assign
            
            template <class T>
            explicit Stream(T && func)
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
                return make_stream<TNewElement>
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
                return make_stream<TElement>
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
            
            XLC_COMPILER_ERROR_HACK
            auto flatten()
            {
                using TNewElement = typename decltype(from(std::declval<TElement>()))::value_type;
                return make_stream<TNewElement>
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
                using TNewElement = typename decltype(from(std::declval<TMapResult>()))::value_type;
                return make_stream<TNewElement>
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
                return make_stream<TElement>
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
                return concat<std::initializer_list<T>>(std::forward<std::initializer_list<T>>(container));
            }
            
            template <class T, std::size_t N>
            auto concat(T (&container)[N])
            {
                return make_stream<TElement>
                ([XLC_MOVE_CAPTURE_THIS(me),
                  &container]
                 (auto && outputFunc) mutable
                 {
                     return me.each(outputFunc) &&
                     from(container).each(outputFunc);
                 });
            }
            
            XLC_COMPILER_ERROR_HACK
            auto skip(std::size_t count)
            {
                return make_stream<TElement>
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
                return make_stream<TElement>
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
            
            XLC_COMPILER_ERROR_HACK
            auto take(std::size_t count)
            {
                return make_stream<TElement>
                ([XLC_MOVE_CAPTURE_THIS(me),
                  count]
                 (auto && outputFunc) mutable
                 {
                     if (count == 0) {
                         return true;
                     }
                     
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
                                     return continue_ && countCopy;
                                 }
                                 return false;
                             });
                     return continue_;
                 });
            }
            
            template <class TFunc>
            auto take_while(TFunc && func)
            {
                return make_stream<TElement>
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
                return filter([XLC_FORWARD_CAPTURE(func)](auto const &e){ return !func(e); }).empty();
            }
            
            auto max() -> std::unique_ptr<TElement>
            {
                auto func = static_cast<TElement const & (*)(TElement const &, TElement const &)>(std::max<TElement>);
                return fold(func);
            }
            
            template <class TFunc>
            auto max(TFunc && func) -> std::unique_ptr<TElement>
            {
                return fold([XLC_FORWARD_CAPTURE(func)](auto const &sum, auto const &e){
                    return std::max(sum, e, func);
                });
            }
            
            auto min() -> std::unique_ptr<TElement>
            {
                auto func = static_cast<TElement const & (*)(TElement const &, TElement const &)>(std::min<TElement>);
                return fold(func);
            }
            
            template <class TFunc>
            auto min(TFunc && func) -> std::unique_ptr<TElement>
            {
                return fold([XLC_FORWARD_CAPTURE(func)](auto const &sum, auto const &e){
                    return std::min(sum, e, func);
                });
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
            
            auto count() -> std::size_t
            {
                std::size_t count = 0;
                each([&count](auto const &){ ++count; });
                return count;
            }
            
            template <class TFunc>
            auto count(TFunc && func) -> std::size_t
            {
                return filter(std::forward<TFunc>(func)).count();
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
            
            template <class TOutContainer>
            auto to() -> TOutContainer
            {
                TOutContainer container;
                using std::end;
                copy_to(std::inserter(container, end(container)));
                return container;
            }
            
            auto to_vector() -> std::vector<TElement>
            {
                return to<std::vector<TElement>>();
            }
            
            auto to_deque() -> std::deque<TElement>
            {
                return to<std::deque<TElement>>();
            }
            
            auto to_set() -> std::set<TElement>
            {
                return to<std::set<TElement>>();
            }
            
            auto to_list() -> std::list<TElement>
            {
                return to<std::list<TElement>>();
            }
            
            template <
            class U = TElement,
            class = std::enable_if_t<is_pair<U>::value>
            >
            auto to_map() -> std::map<typename U::first_type, typename U::second_type>
            {
                return to<std::map<typename U::first_type, typename U::second_type>>();
            }
            
#ifdef __OBJC__
            auto to_NSArray() -> NSArray *
            {
                NSMutableArray *array = [NSMutableArray array];
                each([=](id item) {
                    [array addObject:item ?: [NSNull null]];
                });
                return array;
            }
            
            auto to_NSDictionary() -> NSDictionary *
            {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                each([=](std::pair<id, id> const & item) {
                    if (item.second)
                    {
                        dict[item.first ?: [NSNull null]] = item.second;
                    }
                });
                return dict;
            }
#endif
            
            XLC_COMPILER_ERROR_HACK
            auto repeat(std::size_t count)
            {
                return make_stream<TElement>
                ([XLC_MOVE_CAPTURE_THIS(me),
                  count]
                 (auto && outputFunc) mutable
                 {
                     switch (count) {
                         case 0:
                             return true;
                             
                         case 1:
                             return me.each(std::forward<decltype(outputFunc)>(outputFunc));
                             
                         default:
                         {
                             std::list<TElement> buff;
                             bool result = me.each([&outputFunc,
                                                    &buff]
                                                   (auto const &e) {
                                                       buff.emplace_back(e);
                                                       return outputFunc(e);
                                                   });
                             if (!result) return false;
                             for (std::size_t i = 1; i < count; ++i)
                             {
                                 result = from(buff.begin(), buff.end()) // so it doesn't move/copy buff
                                 .each(std::forward<decltype(outputFunc)>(outputFunc));
                                 if (!result) return false;
                             }
                             break;
                         }
                     }
                     return true;
                 });
            }
            
            XLC_COMPILER_ERROR_HACK
            auto repeat()
            {
                return make_stream<TElement>
                ([XLC_MOVE_CAPTURE_THIS(me)]
                 (auto && outputFunc) mutable
                 {
                     std::list<TElement> buff;
                     bool result = me.each([&outputFunc,
                                            &buff]
                                           (auto const &e) {
                                               buff.emplace_back(e);
                                               return outputFunc(e);
                                           });
                     if (!result) return false;
                     while (result)
                     {
                         result = from(buff.begin(), buff.end()) // so it doesn't move/copy buff
                         .each(std::forward<decltype(outputFunc)>(outputFunc));
                     }
                     return false;
                 });
            }
            
            template <class TContainer>
            auto merge(TContainer && container)
            {
                using TContainerElement = typename decltype(from(std::forward<TContainer>(container)))::value_type;
                using TNewElement = std::tuple<TElement, TContainerElement>;
                
                return make_stream<TNewElement>
                ([XLC_MOVE_CAPTURE_THIS(me),
                  XLC_FORWARD_CAPTURE(container)]
                 (auto && outputFunc) mutable
                 {
                     auto evaluator = from(std::forward<decltype(container)>(container)).evaluate();
                     auto it = evaluator.begin();
                     auto end = evaluator.end();
                     return me.each([XLC_FORWARD_CAPTURE(outputFunc),
                                     it, end]
                                    (auto const &e) mutable
                                    {
                                        if (it == end) {
                                            return false;
                                        }
                                        decltype(auto) other = *it;
                                        ++it;
                                        return outputFunc(TNewElement{e, other}) && it != end;
                                    });
                 });
            }
            
            template <class T>
            auto merge(std::initializer_list<T> && container)
            {
                return merge<std::initializer_list<T>>(std::forward<std::initializer_list<T>>(container));
            }
            
            // evaluate in background thread
            auto evaluate() && -> StreamEvaluator<Stream>
            {
                return StreamEvaluator<Stream>{std::move(*this)};
            }
        };
    }
    
    using detail::make_stream;
    using detail::from;
    using detail::range;
}


#endif
