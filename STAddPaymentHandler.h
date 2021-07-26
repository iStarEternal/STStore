//
//  STAddPaymentHandler.h
//  Star Twinkle
//
//  Created by Star on 2021/7/26.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^STAddPaymentHandleSuccess)(SKPaymentTransaction *transaction);
typedef void (^STAddPaymentHandleFailure)(NSError *error);
 
@interface STAddPaymentHandler : NSObject

@property (nonatomic, strong) STAddPaymentHandleSuccess success;
@property (nonatomic, strong) STAddPaymentHandleFailure failure;

@end

NS_ASSUME_NONNULL_END
