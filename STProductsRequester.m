//
//  STProductsRequester.m
//  Star Twinkle
//
//  Created by Star on 2021/7/21.
//

#import "STProductsRequester.h"

@interface STProductsRequester () <SKProductsRequestDelegate> {}

@property (nonatomic, strong) STProductsRequestSuccess success;
@property (nonatomic, strong) STProductsRequestFailure failure;

@end

@implementation STProductsRequester

- (void)requestProductsWithIdentifiers:(NSSet *)identifiers success:(STProductsRequestSuccess)success failure:(STProductsRequestFailure)failure {
    _success = success;
    _failure = failure;
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:identifiers];
    productsRequest.delegate = self;
    [productsRequest start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.success) {
            self.success(response);
        }
    });
}

- (void)requestDidFinish:(SKRequest *)request {
    
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.failure) {
            self.failure(error);
        }
    });
}

@end
