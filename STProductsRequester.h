//
//  STProductsRequester.h
//  Star Twinkle
//
//  Created by Star on 2021/7/21.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^STProductsRequestSuccess)(SKProductsResponse *response);
typedef void (^STProductsRequestFailure)(NSError *error);

@interface STProductsRequester : NSObject

- (void)requestProductsWithIdentifiers:(NSSet *)identifiers success:(STProductsRequestSuccess)success failure:(STProductsRequestFailure)failure;

@end

NS_ASSUME_NONNULL_END
