//
//  MyConcurrentOperation.m
//  iOSConcurrentDemo
//
//  Created by uwei on 2021/9/24.
//  Copyright © 2021 TEG of Tencent. All rights reserved.
//

#import "MyConcurrentOperation.h"
@implementation MyConcurrentOperation

- (instancetype)init {
    if (self = [super init]) {
        executing = NO;
        finished = NO;
    }
    return self;
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return executing;
}

- (BOOL)isFinished {
    return finished;
}

- (void)start {
    if (self.cancelled) {
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    // main执行完毕之后，thread会是释放，当再次创建对象的时候，则同样会重新创建线程
//    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    // 通过 runloop 可以复用一个thread对象
    [self performSelector:@selector(main) onThread:[MyConcurrentOperation networkRequestThread] withObject:nil waitUntilDone:NO modes:@[NSRunLoopCommonModes,NSDefaultRunLoopMode]];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}


- (void)main {
    @try {
        @autoreleasepool {
            NSLog(@"do my concurrent job on thread %@", [NSThread currentThread]);
            [self completeOperation];
        }
        
    } @catch (NSException *exception) {
        //
    } @finally {
        //
    }
    
}

- (void)completeOperation {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    finished = YES;
    executing = NO;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    
}

+(void)networkRequestThreadEntryPoint:(id)__unusedobject{
    @autoreleasepool{
        [[NSThread currentThread] setName:@"MyBackroundThread"];
        NSRunLoop *runLoop=[NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port]forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+(NSThread*)networkRequestThread{
    static NSThread * _networkRequestThread=nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate,^{
        _networkRequestThread = [[NSThread alloc]initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:)object:nil];
        [_networkRequestThread start];
    });
    return _networkRequestThread;
}

@end

