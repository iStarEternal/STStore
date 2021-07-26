//
//  STRefreshReceiptRequester.m
//  Star Twinkle
//
//  Created by Star on 2021/7/21.
//

#import "STRefreshReceiptRequester.h"

@interface STRefreshReceiptRequester () <SKRequestDelegate> {}

@property (nonatomic, strong) SKReceiptRefreshRequest *refreshReceiptRequest;

@property (nonatomic, strong) STReceiptRefreshSuccess success;
@property (nonatomic, strong) STReceiptRefreshFailure failure;

@end

@implementation STRefreshReceiptRequester

- (void)refreshReceiptOnSuccess:(STReceiptRefreshSuccess)success failure:(STReceiptRefreshFailure)failure {
    _success = success;
    _failure = failure;
    _refreshReceiptRequest = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:@{}];
    _refreshReceiptRequest.delegate = self;
    [_refreshReceiptRequest start];
}

- (void)requestDidFinish:(SKRequest *)request {
    _refreshReceiptRequest = nil;
    if (self.success) {
        self.success(NSBundle.mainBundle.appStoreReceiptURL);
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    _refreshReceiptRequest = nil;
    if (self.failure) {
        self.failure(error);
    }
}

@end
