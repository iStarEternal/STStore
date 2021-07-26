//
//  STStore.m
//  Star Twinkle
//
//  Created by Star on 2021/7/21.
//

#import "STStore.h"
#import "STProductsRequester.h"
#import "STRefreshReceiptRequester.h"
#import "STAddPaymentHandler.h"

typedef void (^STRestoreTransactionsSuccess)(NSArray *transactions);
typedef void (^STRestoreTransactionsFailure)(NSError *error);

#ifdef STStoreLogger
#define NSLog(...) NSLog(__VA_ARGS__)
#else
#define NSLog(...) while (0) {}
#endif

@interface STStore () <SKPaymentTransactionObserver> {}

// Products
@property (nonatomic, strong) NSMutableArray<STProductsRequester *> *productsRequesters;
@property (nonatomic, strong, readwrite) NSArray<SKProduct *> *products;

// AddPayment
@property (nonatomic, strong) NSMutableDictionary<NSString *, STAddPaymentHandler *> *addPaymentHandlers;

// Restore
@property (nonatomic, copy) STRestoreTransactionsSuccess restoreTransactionsSuccess;
@property (nonatomic, copy) STRestoreTransactionsFailure restoreTransactionsFailure;
@property (nonatomic, strong) NSMutableArray<SKPaymentTransaction *> *restoredTransactions;

// Receipt
@property (nonatomic, strong) STRefreshReceiptRequester *refreshReceiptRequester;

@end

@implementation STStore

+ (instancetype)defaultStore {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _productsRequesters = [NSMutableArray array];
        _addPaymentHandlers = [NSMutableDictionary dictionary];
        _refreshReceiptRequester = [[STRefreshReceiptRequester alloc] init];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

// MARK: - RequestProducts

- (RACSignal<SKProductsResponse *> *)requestProducts:(NSSet *)identifiers {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        [self requestProducts:identifiers success:^(SKProductsResponse * _Nonnull response) {
            [subscriber sendNext:response];
            [subscriber sendCompleted];
        } failure:^(NSError * _Nonnull error) {
            [subscriber sendError:error];
        }];
        return [RACDisposable disposableWithBlock:^{ }];
    }];
}

- (void)requestProducts:(NSSet *)identifiers success:(STProductsRequestSuccess)success failure:(STProductsRequestFailure)failure {
    STProductsRequester *requester = [[STProductsRequester alloc] init];
    [self.productsRequesters addObject:requester];
    __weak typeof(requester) weak_requester = requester;
    [requester requestProductsWithIdentifiers:identifiers success:^(SKProductsResponse * _Nonnull response) {
        [self.productsRequesters removeObject:weak_requester];
        self.products = response.products;
        if (success) success(response);
    } failure:^(NSError * _Nonnull error) {
        [self.productsRequesters removeObject:weak_requester];
        if (failure) failure(error);
    }];
}

// MARK: - AddPayment

- (RACSignal<SKPaymentTransaction *> *)addPayment:(SKProduct *)product {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        [self addPayment:product user:nil success:^(SKPaymentTransaction *transaction) {
            [subscriber sendNext:transaction];
            [subscriber sendCompleted];
        } failure:^(NSError * _Nonnull error) {
            [subscriber sendError:error];
        }];
        return [RACDisposable disposableWithBlock:^{ }];
    }];
}

- (void)addPayment:(SKProduct *)product user:(NSString *)applicationUsername success:(STAddPaymentHandleSuccess)success failure:(STAddPaymentHandleFailure)failure {
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    payment.applicationUsername = applicationUsername;
    
    STAddPaymentHandler *handler = [[STAddPaymentHandler alloc] init];
    handler.success = success;
    handler.failure = failure;
    self.addPaymentHandlers[product.productIdentifier] = handler;
    
    [SKPaymentQueue.defaultQueue addPayment:payment];
}

// MARK: - Restore

- (RACSignal<NSArray<SKPaymentTransaction *> *> *)restoreTransactions {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        [self restoreTransactionsOnSuccess:^(NSArray *transactions) {
            [subscriber sendNext:transactions];
            [subscriber sendCompleted];
        } failure:^(NSError *error) {
            [subscriber sendError:error];
        }];
        return [RACDisposable disposableWithBlock:^{ }];
    }];
}

- (void)restoreTransactionsOnSuccess:(STRestoreTransactionsSuccess)successBlock failure:(STRestoreTransactionsFailure)failureBlock {
    self.restoredTransactions = [NSMutableArray array];
    self.restoreTransactionsSuccess = successBlock;
    self.restoreTransactionsFailure = failureBlock;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

// MARK: - Receipt

- (NSURL *)receiptURL {
    return NSBundle.mainBundle.appStoreReceiptURL;
}

- (RACSignal<NSURL *> *)refreshReceipt {
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        [self.refreshReceiptRequester refreshReceiptOnSuccess:^(NSURL * _Nonnull receiptURL) {
            [subscriber sendNext:receiptURL];
            [subscriber sendCompleted];
        } failure:^(NSError * _Nonnull error) {
            [subscriber sendError:error];
        }];
        return [RACDisposable disposableWithBlock:^{ }];
    }];
}

// MARK: - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"updatedTransactions: SKPaymentTransactionStatePurchasing -> %@", transaction.payment.productIdentifier);
                break;
            case SKPaymentTransactionStatePurchased:
                NSLog(@"updatedTransactions: SKPaymentTransactionStatePurchased -> %@", transaction.payment.productIdentifier);
                [self purchasedWithPaymentQueue:queue transaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"updatedTransactions: SKPaymentTransactionStateRestored -> %@", transaction.payment.productIdentifier);
                [self restoredWithPaymentQueue:queue transaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"updatedTransactions: SKPaymentTransactionStateFailed -> %@", transaction.payment.productIdentifier);
                [self failedWithPaymentQueue:queue transaction:transaction];
                break;
            case SKPaymentTransactionStateDeferred:
                NSLog(@"updatedTransactions: SKPaymentTransactionStateDeferred -> %@", transaction.payment.productIdentifier);
                break;
        }
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    NSLog(@"paymentQueueRestoreCompletedTransactionsFinished:");
    if (self.restoreTransactionsSuccess) {
        self.restoreTransactionsSuccess(self.restoredTransactions);
        self.restoreTransactionsSuccess = nil;
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    NSLog(@"paymentQueue:restoreCompletedTransactionsFailedWithError: -> %@", error);
    if (self.restoreTransactionsFailure) {
        self.restoreTransactionsFailure(error);
        self.restoreTransactionsFailure = nil;
    }
}

// MARK: - updatedTransactions:

- (void)purchasedWithPaymentQueue:(SKPaymentQueue *)queue transaction:(SKPaymentTransaction *)transaction  {
    [queue finishTransaction:transaction];
    STAddPaymentHandler *handler = [self popAddPaymentHandlerForIdentifier:transaction.payment.productIdentifier];
    if (handler.success) {
        handler.success(transaction);
    }
}

- (void)failedWithPaymentQueue:(SKPaymentQueue*)queue transaction:(SKPaymentTransaction *)transaction {
    [queue finishTransaction:transaction];
    STAddPaymentHandler *handler = [self popAddPaymentHandlerForIdentifier:transaction.payment.productIdentifier];
    if (handler.failure != nil) {
        handler.failure(transaction.error);
    }
}

- (void)restoredWithPaymentQueue:(SKPaymentQueue *)queue transaction:(SKPaymentTransaction *)transaction {
    [queue finishTransaction:transaction];
    [self.restoredTransactions addObject:transaction];
}

- (STAddPaymentHandler *)popAddPaymentHandlerForIdentifier:(NSString *)identifier {
    STAddPaymentHandler *handler = self.addPaymentHandlers[identifier];
    [self.addPaymentHandlers removeObjectForKey:identifier];
    return handler;
}

// MARK: - Others

- (BOOL)canMakePayments {
    return [SKPaymentQueue canMakePayments];
}

- (SKProduct *)productForIdentifier:(NSString *)productIdentifier {
    for (SKProduct *product in self.products) {
        if ([product.productIdentifier isEqualToString:productIdentifier]) {
            return product;
        }
    }
    return nil;
}

- (NSString *)localizedPriceOfProduct:(SKProduct *)product {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    numberFormatter.locale = product.priceLocale;
    NSString *formattedString = [numberFormatter stringFromNumber:product.price];
    return formattedString;
}

@end

