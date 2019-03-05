//
//  main.m
//  iOSConcurrentDemo
//
//  Created by uwei on 2019/3/5.
//  Copyright © 2019 TEG of Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <pthread.h>

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
        
        NSLog(@"isMultiThreaded :%d", [NSThread isMultiThreaded]);
        ThreadObject *to1 = [ThreadObject new];
        for (int i = 0; i < 5; ++i) {
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
        
    }
    while (1) {
        
    }
    return 0;
}
