//
//  STStore.h
//  Star Twinkle
//
//  Created by Star on 2021/7/21.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import <ReactiveObjC/ReactiveObjC.h>

NS_ASSUME_NONNULL_BEGIN

@interface STStore : NSObject

/// The last products response of -[STStore requestProducts]
@property (nonatomic, strong, readonly) NSArray<SKProduct *> *products;

/// singleton instance of STStore
+ (instancetype)defaultStore;

/// Requester products
/// @param identifiers product identifiers
/// @return a signal of SKProductsResponse
- (RACSignal<SKProductsResponse *> *)requestProducts:(NSSet *)identifiers;

/// AddPayment
/// @param product product from -[STStore requestProducts]
/// @return a signal of SKPaymentTransaction
- (RACSignal<SKPaymentTransaction *> *)addPayment:(SKProduct *)product;

/// Restore
/// @return a signal of SKPaymentTransaction array
- (RACSignal<NSArray<SKPaymentTransaction *> *> *)restoreTransactions;

/// Refresh receipt
/// @return a signal of URL, from NSBundle.mainBundle.appStoreReceiptURL
- (RACSignal<NSURL *> *)refreshReceipt;

@end

NS_ASSUME_NONNULL_END
