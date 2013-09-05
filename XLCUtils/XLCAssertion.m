//
//  XLCAssertion.m
//  XLCUtils
//
//  Created by Xiliang Chen on 13-9-5.
//  Copyright (c) 2013年 Xiliang Chen. All rights reserved.
//

#import "XLCAssertion.h"

#ifdef DEBUG

#import <unistd.h>
#import <sys/sysctl.h>
#import <signal.h>

// From: http://developer.apple.com/mac/library/qa/qa2004/qa1361.html
static int _XLCIsInDebugger(void) {
    static int result = -1;
    if (result != -1)
        return result;
    
    int                 mib[4];
    struct kinfo_proc   info;
    size_t              size;
    
    // Initialize the flags so that, if sysctl fails for some bizarre
    // reason, we get a predictable result.
    
    info.kp_proc.p_flag = 0;
    
    // Initialize mib, which tells sysctl the info we want, in this case
    // we're looking for information about a specific process ID.
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    
    // Call sysctl.
    
    size = sizeof(info);
    sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
    
    // We're being debugged if the P_TRACED flag is set.
    result = (info.kp_proc.p_flag & P_TRACED) != 0;
    
    return result;
}

void _XLCBreakIfInDebugger() {
    if (_XLCIsInDebugger()) {
        raise(SIGTRAP);
    }
}

#else

void _XLCBreakIfInDebugger() {
    // do nothing
}

#endif
