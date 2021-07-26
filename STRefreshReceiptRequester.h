//
//  STRefreshReceiptRequester.h
//  Star Twinkle
//
//  Created by Star on 2021/7/21.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^STReceiptRefreshSuccess)(NSURL *receiptURL);
typedef void (^STReceiptRefreshFailure)(NSError *error);

@interface STRefreshReceiptRequester : NSObject

- (void)refreshReceiptOnSuccess:(STReceiptRefreshSuccess)success failure:(STReceiptRefreshFailure)failure;

@end

NS_ASSUME_NONNULL_END
