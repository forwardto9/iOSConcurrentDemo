//
//  MyNonConcurrentOperation.m
//  iOSConcurrentDemo
//
//  Created by uwei on 2021/9/24.
//  Copyright © 2021 TEG of Tencent. All rights reserved.
//

#import "MyNonConcurrentOperation.h"

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
                NSLog(@"do my non-current operation job on thread %@!", [NSThread currentThread]);
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
