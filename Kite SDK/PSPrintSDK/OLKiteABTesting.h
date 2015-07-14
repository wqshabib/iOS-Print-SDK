//
//  OLKiteABTesting.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 14/7/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OLKiteABTesting : NSObject

@property (assign, nonatomic) BOOL showProductDescriptionWithPrintOrder;
@property (assign, nonatomic) BOOL offerAddressSearch;
@property (assign, nonatomic) BOOL requirePhoneNumber;
@property (strong, nonatomic) NSString *qualityBannerType;
@property (strong, nonatomic) NSString *checkoutScreenType;

+ (instancetype)sharedInstance;

- (void)setupABTestVariantsWillSkipHomeScreens:(BOOL)skipHomeScreen;

@end
