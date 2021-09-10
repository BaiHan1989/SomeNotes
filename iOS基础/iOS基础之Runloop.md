## 一、简介

`RunLoop` 是可以保证 `iOS` 的应用程序在线程中处理任何事件都不会退出的一种机制。因为 `RunLoop` 的存在，`iOS` 应用程序才有意义。是 `RunLoop` 保证 `iOS` 应用程序可以一直运行下去。谈到 `RunLoop` 就离不开线程。

当我们的应用程序一旦运行起来，在 `iOS` 中的 `main` 函数里，会执行 `UIApplicationMain(argc, argv, nil, appDelegateClassName)` 函数，在该函数的内部，会开启 `RunLoop` 保证程序不退出。

`RunLoop` 实际是一个对象。在 `iOS` 开发中有两套框架都可以获取到 `RunLoop` 对象，一套是 `Foundation` 框架下的 `NSRunLoop`，还有一套是 `CoreFoundation` 框架下的 `CFRunLoopRef`。`NSRunLoop` 是对 `CFRunLoopRef` 的面向对象的封装，但并不是线程安全的，而`CFRunLoopRef`就是一套 C 语言的 API，并且是线程安全的。

一个应用程序的运行可以参照下图：

![runloop](https://user-images.githubusercontent.com/17879178/132788249-3cde7aca-062a-4c48-a9c4-ba996691a9b6.png)

## 二、RunLoop 对象

我们可以通过下面的代码来获取一个 `RunLoop` 对象：

```objective-c
NSLog(@"%p - %p", CFRunLoopGetCurrent(), CFRunLoopGetMain());
NSLog(@"%p - %p", [NSRunLoop currentRunLoop], [NSRunLoop mainRunLoop]);

0x600003e3c000 - 0x600003e3c000
0x60000262e580 - 0x60000262e580
```

- 从打印结果可以看出，当程序运行起来，当前线程的 RunLoop 即主线程的 RunLoop。

因为` CoreFoundation` 是开源的，我们可以通过 `CoreFoundation` 源码来探究一下 `RunLoop` 对象是如何创建的。

```c
CFRunLoopRef CFRunLoopGetCurrent(void) {
    CHECK_FOR_FORK();
    CFRunLoopRef rl = (CFRunLoopRef)_CFGetTSD(__CFTSDKeyRunLoop);

    if (rl) return rl;
  	// 调用 _CFRunLoopGet0
    return _CFRunLoopGet0(pthread_self());
}

CF_EXPORT CFRunLoopRef _CFRunLoopGet0(pthread_t t) {
    ...
    // 根据线程，获取 RunLoop 对象
    CFRunLoopRef loop = (CFRunLoopRef)CFDictionaryGetValue(__CFRunLoops, pthreadPointer(t));

    __CFUnlock(&loopsLock);
    if (!loop) { // 如果没有获取到 RunLoop 对象
        // 创建新的 RunLoop 对象
        CFRunLoopRef newLoop = __CFRunLoopCreate(t);
        __CFLock(&loopsLock);
        loop = (CFRunLoopRef)CFDictionaryGetValue(__CFRunLoops, pthreadPointer(t));
        if (!loop) {
            CFDictionarySetValue(__CFRunLoops, pthreadPointer(t), newLoop);
            loop = newLoop;
        }
        // don't release run loops inside the loopsLock, because CFRunLoopDeallocate may end up taking it
        __CFUnlock(&loopsLock);
        CFRelease(newLoop);
    }
		...
    return loop;
}

```

- 每个 `RunLoop` 对象和线程之间是存在映射的关系的，通过字典来保存他们，字典的 `key` 就是线程，`value` 就是对应的 `RunLoop` 对象
- 如果通过线程没有找到对应的 `RunLoop` 对象，那么就会创建一个，并保存到字典中。

### 2.1 RunLoop 对象的结构

通过源码，我们发现 `CFRunLoopRef` 本质是 `__CFRunLoop` 结构体。

```c
typedef struct CF_BRIDGED_MUTABLE_TYPE(id) __CFRunLoop * CFRunLoopRef;

struct __CFRunLoop {
    CFRuntimeBase _base;
    pthread_mutex_t _lock;                      /* locked for accessing mode list */
    __CFPort _wakeUpPort;                       // used for CFRunLoopWakeUp
    Boolean _unused;
    volatile _per_run_data *_perRunData;        // reset for runs of the run loop
    pthread_t _pthread;
    uint32_t _winthread;
    CFMutableSetRef _commonModes;
    CFMutableSetRef _commonModeItems;
    CFRunLoopModeRef _currentMode;
    CFMutableSetRef _modes;
    struct _block_item *_blocks_head;
    struct _block_item *_blocks_tail;
    CFAbsoluteTime _runTime;
    CFAbsoluteTime _sleepTime;
    CFTypeRef _counterpart;
};
```

我们不需要关注结构体的所有成员，只需要关注几个经常用到的即可。

- `pthread_t _pthread` 说明了 `RunLoop` 对象一定和线程是相关的
- `CFMutableSetRef _modes` 说明 `RunLoop` 中可以存在多个 `mode` 的
- `CFRunLoopModeRef _currentMode` 说明在 `RunLoop` 中只能有一个 `mode` 在起作用

我们继续看 `CFRunLoopModeRef` 中都有什么：

```c
typedef struct __CFRunLoopMode *CFRunLoopModeRef;
struct __CFRunLoopMode {
		...
    CFMutableSetRef _sources0;
    CFMutableSetRef _sources1;
    CFMutableArrayRef _observers;
    CFMutableArrayRef _timers;
  	...
};
```

我们重点关注以上这四个成员。

通过以上的源码可以发现：一个 `RunLoop` 对象中包含多个 `mode`，每个 `mode` 中又包含 `source0`、`source1`、`observer` 和 `timer` 的。

我们值得研究的 `mode`，主要包含以下2个：

- `kCFRunLoopDefaultMode`：应用程序默认的 `mode`，通常主线程运行在这个模式里
- `UITrackingRunLoopMode`：界面滑动时的模式，例如 `ScrollView` 的滑动，目的是保证在滑动时不会被影响。

- `source0`: 非基于 port 的处理事件，一般是App内部事件。
- `source1`：可以监听系统端口和其他线程相互发送消息，能够主动唤醒 `RunLoop`，由操作系统内核进行管理。
- `timer`：专门处理 `NSTimer`。
- `observer`：监听器，可以监听 RunLoop 的各种状态。

### 2.2 监听 RunLoop 的状态

利用 `observer` 可以监听 `RunLoop` 的各种状态，可以帮助更好理解 `RunLoop`：

下面就是` RunLoop` 的各种状态：

```objective-c
typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
     kCFRunLoopEntry = (1UL << 0),							// 进入 RunLoop
     kCFRunLoopBeforeTimers = (1UL << 1),				// 即将处理 Timers
     kCFRunLoopBeforeSources = (1UL << 2),			// 即将处理 Sources
     kCFRunLoopBeforeWaiting = (1UL << 5),			// 即将休眠
     kCFRunLoopAfterWaiting = (1UL << 6),				// 结束休眠，被唤醒
     kCFRunLoopExit = (1UL << 7),								// 退出 RunLoop
     kCFRunLoopAllActivities = 0x0FFFFFFFU
 };
```

可以利用 `CoreFoundation` 框架下的 `RunLoop` 对象进行监听：

```objective-c
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, true, 0, callback, NULL);
    CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopCommonModes);
    CFRelease(observer);
}

void callback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    switch (activity) {
        case kCFRunLoopEntry: // 进入 RunLoop
            NSLog(@"kCFRunLoopEntry");
            break;
        case kCFRunLoopBeforeWaiting: // 即将休眠
            NSLog(@"kCFRunLoopBeforeWaiting");
            break;
        case kCFRunLoopBeforeTimers: // 即将处理 Timer
            NSLog(@"kCFRunLoopBeforeTimers");
            break;
        case kCFRunLoopBeforeSources: // 即将处理 sources
            NSLog(@"kCFRunLoopBeforeSources");
            break;
        case kCFRunLoopAfterWaiting: // 唤醒 RunLoop
            NSLog(@"kCFRunLoopAfterWaiting");
            break;
        case kCFRunLoopExit: // 退出 RunLoop
            NSLog(@"kCFRunLoopExit");
            break;
            
        default:
            break;
    }
}
```

### 2.4 源码分析 RunLoop 的执行流程

通过观察函数调用栈可知道 RunLoop 是从 CFRunLoopRunSpecific() 函数开始的，我们就从该函数开始进行探索。源码内容比较多，包含很多合理性判断和线程安全的代码，我们只研究核心代码即可。

```c
SInt32 CFRunLoopRunSpecific(CFRunLoopRef rl, CFStringRef modeName, CFTimeInterval seconds, Boolean returnAfterSourceHandled) {     /* DOES CALLOUT */
    
    // 获取当前 RunLoop 的 mode
    CFRunLoopModeRef currentMode = __CFRunLoopFindMode(rl, modeName, false);

    // 进入 RunLoop
    if (currentMode->_observerMask & kCFRunLoopEntry ) __CFRunLoopDoObservers(rl, currentMode, kCFRunLoopEntry);
    
    // RunLoop 处理不同 mode
    result = __CFRunLoopRun(rl, currentMode, seconds, returnAfterSourceHandled, previousMode);
    
    // 退出 RunLoop
    if (currentMode->_observerMask & kCFRunLoopExit ) __CFRunLoopDoObservers(rl, currentMode, kCFRunLoopExit);

    return result;
    
} /* CFRunLoopRunSpecific */
```

__CFRunLoopRun 函数就是 RunLoop 如何处理不同 mode 的逻辑。该函数内部有个 do-while 循环，这里就是 RunLoop 一直运行的核心，只要 retVal 返回值是0就继续循环。

```c
do {
	...
} while (0 == retVal);
```

```c
static int32_t __CFRunLoopRun(CFRunLoopRef rl, CFRunLoopModeRef rlm, CFTimeInterval seconds, Boolean stopAfterHandle, CFRunLoopModeRef previousMode) {
    
    // 设置 retVal 初始值为 0
    int32_t retVal = 0;
    do {
        // 处理 Timers
        if (rlm->_observerMask & kCFRunLoopBeforeTimers) __CFRunLoopDoObservers(rl, rlm, kCFRunLoopBeforeTimers);
        
        // 处理 Sources
        if (rlm->_observerMask & kCFRunLoopBeforeSources) __CFRunLoopDoObservers(rl, rlm, kCFRunLoopBeforeSources);

        // 处理 Blocks
        __CFRunLoopDoBlocks(rl, rlm);
        
        // 处理 Source0
        Boolean sourceHandledThisLoop = __CFRunLoopDoSources0(rl, rlm, stopAfterHandle);
    
        // 处理 Source0 完成，再处理一次 Blocks
        if (sourceHandledThisLoop) {
            __CFRunLoopDoBlocks(rl, rlm);
        }
        
        if (MACH_PORT_NULL != dispatchPort && !didDispatchPortLastTime) {
            msg = (mach_msg_header_t *)msg_buffer;
            // 处理 Source1
            if (__CFRunLoopServiceMachPort(dispatchPort, &msg, sizeof(msg_buffer), &livePort, 0, &voucherState, NULL)) {
                // 跳转到 handle_msg
                goto handle_msg;
            }
        }

        didDispatchPortLastTime = false;

        // 即将进入休眠
        if (!poll && (rlm->_observerMask & kCFRunLoopBeforeWaiting)) __CFRunLoopDoObservers(rl, rlm, kCFRunLoopBeforeWaiting);
        // 开始休眠
        __CFRunLoopSetSleeping(rl);


        CFAbsoluteTime sleepStart = poll ? 0.0 : CFAbsoluteTimeGetCurrent();

        do {
            if (kCFUseCollectableAllocator) {
                // objc_clear_stack(0);
                // <rdar://problem/16393959>
                memset(msg_buffer, 0, sizeof(msg_buffer));
            }
            msg = (mach_msg_header_t *)msg_buffer;

            __CFRunLoopServiceMachPort(waitSet, &msg, sizeof(msg_buffer), &livePort, poll ? 0 : TIMEOUT_INFINITY, &voucherState, &voucherCopy);

            if (modeQueuePort != MACH_PORT_NULL && livePort == modeQueuePort) {
                // Drain the internal queue. If one of the callout blocks sets the timerFired flag, break out and service the timer.
                while (_dispatch_runloop_root_queue_perform_4CF(rlm->_queue));
                if (rlm->_timerFired) {
                    // Leave livePort as the queue port, and service timers below
                    rlm->_timerFired = false;
                    break;
                } else {
                    if (msg && msg != (mach_msg_header_t *)msg_buffer) free(msg);
                }
            } else {
                // Go ahead and leave the inner loop.
                break;
            }
        } while (1);
        
        
        if (kCFUseCollectableAllocator) {
            // objc_clear_stack(0);
            // <rdar://problem/16393959>
            memset(msg_buffer, 0, sizeof(msg_buffer));
        }
        msg = (mach_msg_header_t *)msg_buffer;
        __CFRunLoopServiceMachPort(waitSet, &msg, sizeof(msg_buffer), &livePort, poll ? 0 : TIMEOUT_INFINITY, &voucherState, &voucherCopy);

        rl->_sleepTime += (poll ? 0.0 : (CFAbsoluteTimeGetCurrent() - sleepStart));

        __CFRunLoopSetIgnoreWakeUps(rl);

        // user callouts now OK again
        // 休眠结束 被唤醒
        __CFRunLoopUnsetSleeping(rl);
        if (!poll && (rlm->_observerMask & kCFRunLoopAfterWaiting)) __CFRunLoopDoObservers(rl, rlm, kCFRunLoopAfterWaiting);

 handle_msg:;
        __CFRunLoopSetIgnoreWakeUps(rl);

        // 被唤醒
        if (MACH_PORT_NULL == livePort) {
            CFRUNLOOP_WAKEUP_FOR_NOTHING();
            // handle nothing
        } else if (livePort == rl->_wakeUpPort) {
            CFRUNLOOP_WAKEUP_FOR_WAKEUP();
            // do nothing on Mac OS
        }
        else if (modeQueuePort != MACH_PORT_NULL && livePort == modeQueuePort) {
            CFRUNLOOP_WAKEUP_FOR_TIMER();
            if (!__CFRunLoopDoTimers(rl, rlm, mach_absolute_time())) {
                // Re-arm the next timer, because we apparently fired early
                __CFArmNextTimerInMode(rlm, rl);
            }
        }
        else if (rlm->_timerPort != MACH_PORT_NULL && livePort == rlm->_timerPort) {
            CFRUNLOOP_WAKEUP_FOR_TIMER();
            if (!__CFRunLoopDoTimers(rl, rlm, mach_absolute_time())) {
                // Re-arm the next timer
                __CFArmNextTimerInMode(rlm, rl);
            }
        }
        else if (livePort == dispatchPort) {
            CFRUNLOOP_WAKEUP_FOR_DISPATCH();
            __CFRunLoopModeUnlock(rlm);
            __CFRunLoopUnlock(rl);
            _CFSetTSD(__CFTSDKeyIsInGCDMainQ, (void *)6, NULL);
            __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__(msg);
            _CFSetTSD(__CFTSDKeyIsInGCDMainQ, (void *)0, NULL);
            __CFRunLoopLock(rl);
            __CFRunLoopModeLock(rlm);
            sourceHandledThisLoop = true;
            didDispatchPortLastTime = true;
        } else {
            CFRUNLOOP_WAKEUP_FOR_SOURCE();

            // If we received a voucher from this mach_msg, then put a copy of the new voucher into TSD. CFMachPortBoost will look in the TSD for the voucher. By using the value in the TSD we tie the CFMachPortBoost to this received mach_msg explicitly without a chance for anything in between the two pieces of code to set the voucher again.
            voucher_t previousVoucher = _CFSetTSD(__CFTSDKeyMachMessageHasVoucher, (void *)voucherCopy, os_release);

            // Despite the name, this works for windows handles as well
            CFRunLoopSourceRef rls = __CFRunLoopModeFindSourceForMachPort(rl, rlm, livePort);
            if (rls) {
                mach_msg_header_t *reply = NULL;
                sourceHandledThisLoop = __CFRunLoopDoSource1(rl, rlm, rls, msg, msg->msgh_size, &reply) || sourceHandledThisLoop;
                if (NULL != reply) {
                    (void)mach_msg(reply, MACH_SEND_MSG, reply->msgh_size, 0, MACH_PORT_NULL, 0, MACH_PORT_NULL);
                    CFAllocatorDeallocate(kCFAllocatorSystemDefault, reply);
                }
            }

            // Restore the previous voucher
            _CFSetTSD(__CFTSDKeyMachMessageHasVoucher, previousVoucher, os_release);

        }
        
        // 给 retVal 赋值，如果满足其中一项就结束循环，否则 retVal = 0，继续循环
        if (sourceHandledThisLoop && stopAfterHandle) {
            retVal = kCFRunLoopRunHandledSource;
        } else if (timeout_context->termTSR < mach_absolute_time()) {
            retVal = kCFRunLoopRunTimedOut;
        } else if (__CFRunLoopIsStopped(rl)) {
            __CFRunLoopUnsetStopped(rl);
            retVal = kCFRunLoopRunStopped;
        } else if (rlm->_stopped) {
            rlm->_stopped = false;
            retVal = kCFRunLoopRunStopped;
        } else if (__CFRunLoopModeIsEmpty(rl, rlm, previousMode)) {
            retVal = kCFRunLoopRunFinished;
        }

    } while (0 == retVal);

    return retVal;
}
```

