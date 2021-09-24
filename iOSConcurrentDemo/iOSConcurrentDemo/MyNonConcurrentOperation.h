//
//  MyNonConcurrentOperation.h
//  iOSConcurrentDemo
//
//  Created by uwei on 2021/9/24.
//  Copyright © 2021 TEG of Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MyNonConcurrentOperation : NSOperation {
    id myData;
}

- (instancetype)initWithData:(id)data;

@end

NS_ASSUME_NONNULL_END
