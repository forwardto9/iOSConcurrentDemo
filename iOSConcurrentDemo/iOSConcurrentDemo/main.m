//
//  main.m
//  iOSConcurrentDemo
//
//  Created by uwei on 2019/3/5.
//  Copyright © 2019 TEG of Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <pthread.h>

#define kCondition 1
#define kOperation 0

@interface MyNonConcurrentOperation : NSOperation {
    id myData;
}

- (instancetype)initWithData:(id)data;

@end

@implementation MyNonConcurrentOperation

- (instancetype)initWithData:(id)data {
    if (self = [super init]) {
        myData = data;
    }
    
    return self;
}

- (void)main {
    @try {
        @autoreleasepool {
            BOOL isDone = NO;
            while (!self.cancelled && !isDone) {
                NSLog(@"do my non-current operation job!");
                isDone = YES;
            }
        }
        
    } @catch (NSException *exception) {
        //
    } @finally {
        //
    }
}

- (BOOL)isFinished {
    return myData != nil;
}

@end

@interface MyConcurrentOperation : NSOperation {
    BOOL executing;
    BOOL finished;
}

- (void)completeOperation;

@end

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
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}


- (void)main {
    @try {
        @autoreleasepool {
            NSLog(@"do my concurrent job!");
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


@end




@interface MyCustomClass : NSObject
- (NSOperation *)taskWithData:(id)data;
- (NSOperation *)taskWithBlock:(id)data;
@end
@implementation MyCustomClass

- (NSOperation *)taskWithData:(id)data {
    NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(taskMethod:) object:data];
    return op;
}

- (NSOperation *)taskWithBlock:(id)data {
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"do block1 task!");
    }];
    [op addExecutionBlock:^{
        NSLog(@"do block2 task!");
    }];
    [op addExecutionBlock:^{
        NSLog(@"do block3 task!");
    }];
    return op;
}


- (void)taskMethod:(id)data {
    NSLog(@"do invocation task!");
}

@end




@interface ThreadObject : NSObject

@property (copy, nonatomic) NSString *resource;

- (void)task1:(NSString *)p;
- (void)task2;

@end

@implementation ThreadObject

int gX = 0;

- (void)task1:(NSString *)p {
    @synchronized (@(gX)) {
        NSLog(@"%@ %d", self.resource, gX);
    }
    
    if ([p isEqualToString:@"!"]) {
        // the priority is determined by the kernel, there is no guarantee what this value actually will be
        NSLog(@"%@", [NSThread setThreadPriority:0.2] ? @"YES" : @"NO");
    }
    mach_port_t machTID = pthread_mach_thread_np(pthread_self());
    NSLog(@"%s[%@], current thread: %x[%@] priority(%f), process id:%d", __FUNCTION__, p, machTID, [NSThread currentThread], [[NSThread currentThread] threadPriority], NSProcessInfo.processInfo.processIdentifier);
}

- (void)task2 {
    self.resource = @"set";
    @synchronized (@(gX)) {
         gX++;
    }
   
}

@end




int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"Hello, World!");
#pragma mark - Operation
        for (int i = 0; i < 2; ++i) {
//        [[[[MyCustomClass alloc] init] taskWithData:nil] start];
        NSOperationQueue* q = [[NSOperationQueue alloc] init];
            [q setMaxConcurrentOperationCount:3];
//        NSOperationQueue *q = [NSOperationQueue currentQueue];
        [q addOperation:[[MyCustomClass new] taskWithData:nil]];
        [q addOperation: [[MyCustomClass new] taskWithBlock:nil]];
        [q addOperation:[[MyNonConcurrentOperation alloc] initWithData:nil]];
        [q addOperation:[[MyConcurrentOperation alloc] init]];
//        [[[MyNonConcurrentOperation alloc] initWithData:nil] start];
        }
#pragma mark - GCD
        // 并发队列
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        // 串行队列
        dispatch_queue_create("com.demo.queue", NULL);
        
        dispatch_get_current_queue();
        
#if 0
        NSLog(@"isMultiThreaded :%d", [NSThread isMultiThreaded]);
        ThreadObject *to1 = [ThreadObject new];
        for (int i = 0; i < 2; ++i) {
            NSThread *thread1 = [[NSThread alloc] initWithTarget:to1 selector:@selector(task1:) object:@"hello"];
            [thread1 start];
            NSLog(@"isMultiThreaded :%d", [NSThread isMultiThreaded]);
            [NSThread detachNewThreadSelector:@selector(task1:) toTarget:to1 withObject:@"world"];
            NSLog(@"isMultiThreaded :%d", [NSThread isMultiThreaded]);
            
            NSThread *thread2 = [[NSThread alloc] initWithTarget:to1 selector:@selector(task1:) object:@"!"];
            // the priority is determined by the kernel, there is no guarantee what this value actually will be
            [thread2 setThreadPriority:0.1];
            [thread2 start];
            
            [NSThread detachNewThreadSelector:@selector(task2) toTarget:to1 withObject:nil];
        }
#endif
        OSQueueHead q = OS_ATOMIC_QUEUE_INIT;
        NSMutableArray *shareArray = [NSMutableArray new];
        //        __block volatile int index = 0;
        __block int index = 0;
        //        OSAtomicEnqueue( &q, &index, sizeof(int));
        //        OSAtomicEnqueue( &q, &index, sizeof(int));
        #if kCondition
                NSCondition *lock = [[NSCondition alloc] init];
                //        NSCondition *lock = nil;
                while (1) {
                    [NSThread detachNewThreadWithBlock:^{
                        [lock lock];
                        while (index >= 5) {
                            [lock wait];
                            NSLog(@"wait....");
                        }
                        for (int i = 0; i < 5; ++i) {
                            [shareArray insertObject:@(i) atIndex:index++];
                            NSLog(@"producer :%d", index);
                        }
                        [lock unlock];
                    }];
                    
                    [NSThread detachNewThreadWithBlock:^{
                        [lock lock];
                        for (int i = 0; i < 5; ++i) {
                            
                            if (index >= 1) {
                                [shareArray removeObjectAtIndex:--index];
                                NSLog(@"consumer :%d", index);
                            }
                            
                        }
                        [lock signal];
                        
                        [lock unlock];
                    }];
                }
        #elif kOperation
                
                NSOperationQueue *oq = [NSOperationQueue new];
                //        oq.maxConcurrentOperationCount = 1;
                while (1) {
                    //            NONCurrentOperation *CCO = [[NONCurrentOperation alloc] initWithData:@[@"name1 ", @"name2"]];
                    //            [oq addOperation:CCO];
                    
                    NSBlockOperation *po = [NSBlockOperation blockOperationWithBlock:^{
                        for (int i = 0; i < 5; ++i) {
                            [shareArray insertObject:@(i) atIndex:index++];
                            NSLog(@"NSOperationQueue producer :%d", index);
                        }
                    }];
                    
                    NSBlockOperation *co = [NSBlockOperation blockOperationWithBlock:^{
                        for (int i = 0; i < 5; ++i) {
                            if (index >= 1) {
                                [shareArray removeObjectAtIndex:--index];
                                NSLog(@"NSOperationQueue consumer :%d", index);
                            }
                        }
                    }];
                    [co addDependency:po];
                    [oq addOperation:co];
                    [oq addOperation:po];
                    [oq waitUntilAllOperationsAreFinished];
                }
                
        #else
                
                dispatch_queue_t sq = dispatch_queue_create("sq.demo", DISPATCH_QUEUE_SERIAL);
                while (1) { // 线性队列，保证了异步提交、同步执行
                    dispatch_async(sq, ^{
                        for (int i = 0; i < 5; ++i) {
                            [shareArray insertObject:@(i) atIndex:index++];
                            NSLog(@"GCD producer :%d", index);
                        }
                    });
                    dispatch_async(sq, ^{
                        for (int i = 0; i < 5; ++i) {
                            if (index >= 1) {
                                [shareArray removeObjectAtIndex:--index];
                                NSLog(@"GCD consumer :%d", index);
                            }
                        }
                    });
                }
                
        #endif
        
    }
    return 0;
}
