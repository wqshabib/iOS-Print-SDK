//
//  OLCreditCardCaptureViewController.m
//  Kite Print SDK
//
//  Created by Deon Botha on 20/11/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import "OLCreditCardCaptureViewController.h"
#import <SVProgressHUD.h>
#import "OLConstants.h"
#import "OLPayPalCard.h"
#import "OLJudoPayCard.h"
#import "OLPrintOrder.h"
#import "CardIO.h"
#import "OLKitePrintSDK.h"
#import <AVFoundation/AVFoundation.h>
#import "NSString+Formatting.h"
#import "UITextField+Selection.h"
#import "UIView+RoundRect.h"

static const NSUInteger kOLSectionCardNumber = 0;
static const NSUInteger kOLSectionExpiryDate = 1;
static const NSUInteger kOLSectionCVV = 2;

typedef enum {
    kCardTypeVisa,
    kCardTypeMasterCard,
    kCardTypeDinersClub,
    kCardTypeAmex,
    kCardTypeDiscover,
    kCardTypeUnknown
} CardType;

static NSString *const kRegexVisa = @"^4[0-9]{3}?";
static NSString *const kRegexMasterCard = @"^5[1-5][0-9]{2}$";
static NSString *const kRegexAmex = @"^3[47][0-9]{2}$";
static NSString *const kRegexDinersClub = @"^3(?:0[0-5]|[68][0-9])[0-9]$";
static NSString *const kRegexDiscover = @"^6(?:011|5[0-9]{2})$";

static NSString *const kCardIOAppToken = @"f1d07b66ad21407daf153c0ac66c09d7";

static CardType getCardType(NSString *cardNumber) {
    if(cardNumber.length < 4) {
        return kCardTypeUnknown;
    }
    
    CardType cardType;
    NSRegularExpression *regex;
    NSError *error;
    
    for (NSUInteger i = 0; i < kCardTypeUnknown; ++i) {
        cardType = (CardType) i;
        switch(i) {
            case kCardTypeVisa:
                regex = [NSRegularExpression regularExpressionWithPattern:kRegexVisa options:0 error:&error];
                break;
            case kCardTypeMasterCard:
                regex = [NSRegularExpression regularExpressionWithPattern:kRegexMasterCard options:0 error:&error];
                break;
            case kCardTypeAmex:
                regex = [NSRegularExpression regularExpressionWithPattern:kRegexAmex options:0 error:&error];
                break;
            case kCardTypeDinersClub:
                regex = [NSRegularExpression regularExpressionWithPattern:kRegexDinersClub options:0 error:&error];
                break;
            case kCardTypeDiscover:
                regex = [NSRegularExpression regularExpressionWithPattern:kRegexDiscover options:0 error:&error];
                break;
        }
        
        NSUInteger matches = [regex numberOfMatchesInString:cardNumber options:0 range:NSMakeRange(0, 4)];
        if (matches == 1) {
            return cardType;
        }
        
    }
    
    return kCardTypeUnknown;
}

@interface OLKitePrintSDK (Private)
+ (BOOL)useJudoPayForGBP;
@end

@interface OLCreditCardCaptureRootController : UITableViewController <UITableViewDelegate,
#ifdef OL_KITE_OFFER_PAYPAL
CardIOPaymentViewControllerDelegate,
#endif
UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textFieldCardNumber, *textFieldExpiryDate, *textFieldCVV;
@property (nonatomic, strong) OLPrintOrder *printOrder;
@property (nonatomic, weak) id <UINavigationControllerDelegate, OLCreditCardCaptureDelegate> delegate;
- (id)initWithPrintOrder:(OLPrintOrder *)printOrder;
@end

@interface OLCreditCardCaptureViewController ()
@property (nonatomic, strong) OLCreditCardCaptureRootController *rootVC;
- (id)initWithPrintOrder:(OLPrintOrder *)printOrder;
@end

@implementation OLCreditCardCaptureViewController

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder {
    self.rootVC = [[OLCreditCardCaptureRootController alloc] initWithPrintOrder:printOrder];
    if (self = [super initWithRootViewController:self.rootVC]) {

    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setDelegate:(id<UINavigationControllerDelegate,OLCreditCardCaptureDelegate>)delegate {
    self.rootVC.delegate = delegate;
}

- (id<UINavigationControllerDelegate, OLCreditCardCaptureDelegate>)delegate {
    return self.rootVC.delegate;
}

@end

@implementation OLCreditCardCaptureRootController

- (id)initWithPrintOrder:(OLPrintOrder *)printOrder {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        self.printOrder = printOrder;
        self.title = NSLocalizedString(@"Pay with Credit Card", @"");
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(onButtonCancelClicked)];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *buttonPay = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 44)];
    buttonPay.backgroundColor = [UIColor colorWithRed:74 / 255.0f green:137 / 255.0f blue:220 / 255.0f alpha:1.0];
    [buttonPay addTarget:self action:@selector(onButtonPayClicked) forControlEvents:UIControlEventTouchUpInside];
    [buttonPay setTitle:NSLocalizedString(@"Pay", @"") forState:UIControlStateNormal];
    [buttonPay makeRoundRect];
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44 + 40)];
    [footerView addSubview:buttonPay];
    
    UIView *view = buttonPay;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-20-[view]-20-|",
                         @"V:|-20-[view(44)]"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [view.superview addConstraints:con];
    
    self.tableView.tableFooterView = footerView;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Pay", @"")
                                                                             style:UIBarButtonItemStyleDone
                                                                            target:self
                                                                            action:@selector(onButtonPayClicked)];
}

- (NSString *)cardNumber {
    return [NSString stringByTrimmingSpecialCharacters:self.textFieldCardNumber.text];
}

- (NSUInteger)cardExpireMonth {
    NSString *expiryDate = [NSString stringByTrimmingSpecialCharacters:self.textFieldExpiryDate.text];
    return [[expiryDate substringToIndex:2] integerValue];
}

- (NSUInteger)cardExpireYear {
    NSString *expiryDate = [NSString stringByTrimmingSpecialCharacters:self.textFieldExpiryDate.text];
    return [[expiryDate substringFromIndex:2] integerValue];
}

- (NSString *)cardCVV {
    return self.textFieldCVV.text;
}

- (void)onButtonPayClicked {
    [self.textFieldCardNumber resignFirstResponder];
    [self.textFieldExpiryDate resignFirstResponder];
    [self.textFieldCVV resignFirstResponder];
    
    if (self.textFieldCardNumber.text.length < 4) {
        NSString *localizedDescription = NSLocalizedStringFromTableInBundle(@"Enter a valid credit card number", @"KitePrintSDK", [OLConstants bundle], @"");
        [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil] show];
        return;
    }
    
    if (self.textFieldExpiryDate.text.length != 5) {
        NSString *localizedDescription = NSLocalizedStringFromTableInBundle(@"Enter a valid expiry date", @"KitePrintSDK", [OLConstants bundle], @"");
        [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil] show];
        return;
    }
    
    if (self.textFieldCVV.text.length == 0) {
        NSString *localizedDescription = NSLocalizedStringFromTableInBundle(@"Enter a valid CVV number", @"KitePrintSDK", [OLConstants bundle], @"");
        [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil] show];
        return;
    }
    
    NSUInteger expireMonth = [self cardExpireMonth];
    NSUInteger expireYear = [self cardExpireYear];
    if (expireMonth > 12) {
        NSString *localizedDescription = NSLocalizedStringFromTableInBundle(@"Enter a valid expiry date", @"KitePrintSDK", [OLConstants bundle], @"");
        [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil] show];
        return;
    }
    
    CardType cardType = getCardType(self.textFieldCardNumber.text);
    OLPayPalCardType paypalCard;
    switch (cardType) {
        case kCardTypeAmex:
            paypalCard = kOLPayPalCardTypeAmex;
            break;
        case kCardTypeMasterCard:
            paypalCard = kOLPayPalCardTypeMastercard;
            break;
        case kCardTypeVisa:
            paypalCard = kOLPayPalCardTypeVisa;
            break;
        case kCardTypeDiscover:
            paypalCard = kOLPayPalCardTypeDiscover;
            break;
        default: {
            NSString *localizedDescription = NSLocalizedStringFromTableInBundle(@"Enter a valid credit card number", @"KitePrintSDK", [OLConstants bundle], @"");
            [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil] show];
            return;
        }
    }
    
    OLPayPalCard *card = [[OLPayPalCard alloc] init];
    card.type = paypalCard;
    card.number = [self cardNumber];
    card.expireMonth = expireMonth;
    card.expireYear = expireYear;
    card.cvv2 = [self cardCVV];
    
    [self storeAndChargeCard:card];
}

- (void)storeAndChargeCard:(OLPayPalCard *)card{
    [SVProgressHUD showWithStatus:NSLocalizedStringFromTableInBundle(@"Processing", @"KitePrintSDK", [OLConstants bundle], @"") maskType:SVProgressHUDMaskTypeBlack];
    [card storeCardWithCompletionHandler:^(NSError *error) {
        // ignore error as I'd rather the user gets a nice checkout experience than we store the card in PayPal vault.
        [card chargeCard:self.printOrder.cost currencyCode:self.printOrder.currencyCode description:self.printOrder.paymentDescription completionHandler:^(NSString *proofOfPayment, NSError *error) {
            if (error) {
                [SVProgressHUD dismiss];
                [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Oops!", @"KitePrintSDK", [OLConstants bundle], @"") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"OK", @"KitePrintSDK", [OLConstants bundle], @"") otherButtonTitles:nil] show];
                return;
            }
            
            [SVProgressHUD dismiss];
            [self.delegate creditCardCaptureController:(OLCreditCardCaptureViewController *) self.navigationController didFinishWithProofOfPayment:proofOfPayment];
            [card saveAsLastUsedCard];
        }];
    }];
}

- (void)onButtonCancelClicked {
    [self.textFieldCardNumber resignFirstResponder];
    [self.textFieldCVV resignFirstResponder];
    [self.textFieldExpiryDate resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) showCardScanner{
#ifdef OL_KITE_OFFER_PAYPAL
    
    CardIOPaymentViewController *scanViewController = [[CardIOPaymentViewController alloc] initWithPaymentDelegate:self];
    scanViewController.appToken = kCardIOAppToken; // get your app token from the card.io website
    scanViewController.disableManualEntryButtons = YES;
    scanViewController.collectCVV = NO;
    scanViewController.collectExpiry = NO;
    scanViewController.suppressScanConfirmation = YES;
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusNotDetermined){
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted){
            if (granted){
                [self presentViewController:scanViewController animated:YES completion:nil];
            }
        }];
    }
    else if (authStatus == AVAuthorizationStatusDenied){
        if ([UIAlertController class]){
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Camera Permission Denied", @"") message:NSLocalizedString(@"You have previously denied acces to the camera. If you wish to use the camera to scan your card, please allow access to the camera in the Settings app.", @"") preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            }]];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:NULL]];
            [self presentViewController:ac animated:YES completion:NULL];
        }
        else{
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Camera Permission Denied", @"") message:NSLocalizedString(@"You have previously denied acces to the camera. If you wish to use the camera to scan your card, please allow access to the camera in the Settings app.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [av show];
        }
    }
    else{
        [self presentViewController:scanViewController animated:YES completion:nil];
    }
#endif
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == kOLSectionCardNumber) {
        return NSLocalizedString(@"Your 16 digit card number", @"");
    } else if (section == kOLSectionExpiryDate) {
        return NSLocalizedString(@"Your card expiry date", @"");
    } else if (section == kOLSectionCVV) {
        return NSLocalizedString(@"This is the 3-4 digit verification number/security code normally found on the back of your card", @"");
    } else {
        return @"";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const CellIdentifier = @"CreditCardCaptureCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(20, 0, self.view.frame.size.width - 63, 43)];
        textField.delegate = self;
        textField.tag = 99;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        [cell addSubview:textField];
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8){
            UIView *view = textField;
            view.translatesAutoresizingMaskIntoConstraints = NO;
            NSDictionary *views = NSDictionaryOfVariableBindings(view);
            NSMutableArray *con = [[NSMutableArray alloc] init];
            
            NSArray *visuals = @[@"H:|-20-[view]-43-|", @"V:[view(43)]"];
            
            
            for (NSString *visual in visuals) {
                [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
            }
            
            NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
            [con addObject:centerY];
            
            [view.superview addConstraints:con];
        }

    }
    
    UITextField *textField = (UITextField *) [cell viewWithTag:99];
    if (indexPath.section == kOLSectionCardNumber) {
        textField.placeholder = NSLocalizedString(@"Card Number", @"");
        self.textFieldCardNumber = textField;
        
#ifdef OL_KITE_OFFER_PAYPAL
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
            AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            if ((authStatus == AVAuthorizationStatusAuthorized || authStatus == AVAuthorizationStatusNotDetermined || authStatus == AVAuthorizationStatusDenied)){
                UIButton *cameraIcon = [[UIButton alloc] initWithFrame:CGRectMake(self.tableView.frame.size.width - 43, 0, 43, 43)];
                [cameraIcon setImage:[UIImage imageNamed:@"button_camera"] forState:UIControlStateNormal];
                [cameraIcon addTarget:self action:@selector(showCardScanner) forControlEvents:UIControlEventTouchUpInside];
                [cell.contentView addSubview:cameraIcon];
                
                if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
                    UIView *view = cameraIcon;
                    view.translatesAutoresizingMaskIntoConstraints = NO;
                    NSDictionary *views = NSDictionaryOfVariableBindings(view);
                    NSMutableArray *con = [[NSMutableArray alloc] init];
                    
                    NSArray *visuals = @[@"H:[view(43)]-0-|",
                                         @"V:[view(43)]"];
                    
                    
                    for (NSString *visual in visuals) {
                        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
                    }
                    
                    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
                    [con addObject:centerY];
                    
                    [view.superview addConstraints:con];
                }

            }
        }
        
#endif
        
    } else if (indexPath.section == kOLSectionExpiryDate) {
        textField.placeholder = NSLocalizedString(@"MM/YY", @"");
        self.textFieldExpiryDate = textField;
    } else if (indexPath.section == kOLSectionCVV) {
        textField.placeholder = NSLocalizedString(@"CVV", @"");
        self.textFieldCVV = textField;
    }
    
    return cell;
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.textFieldExpiryDate) {
        self.textFieldExpiryDate.text = [NSString stringByFormattingCreditCardExpiry:[self.textFieldExpiryDate.text stringByReplacingCharactersInRange:range withString:string]];
        if (string.length == 0 && self.textFieldExpiryDate.text.length == 3) {
            self.textFieldExpiryDate.text = [self.textFieldExpiryDate.text substringToIndex:2];
        }
        
        return NO;
    }
    else if (textField == self.textFieldCardNumber) {
        UITextRange *selRange = textField.selectedTextRange;
        UITextPosition *selStartPos = selRange.start;
        NSInteger idx = [textField offsetFromPosition:textField.beginningOfDocument toPosition:selStartPos];
        NSInteger offset = -1;
        
        if ([[self.textFieldCardNumber.text substringWithRange:range] isEqualToString:@" "] && string.length == 0){
            range = NSMakeRange(range.location-1, range.length);
            offset = -2;
        }
        
        self.textFieldCardNumber.text = [NSString stringByFormattingCreditCardNumber:[self.textFieldCardNumber.text stringByReplacingCharactersInRange:range withString:string]];
        
        if (string.length == 0 && idx + offset > textField.text.length){
            offset = -2;
        }
        else if (string.length > 0){
            offset = 1;
            if (textField.text.length > idx){
                NSString *s = [textField.text substringWithRange:NSMakeRange(idx, 1)];
                if ([s isEqualToString:@" "]){
                    offset = 2;
                }
            }
            else{
                offset = 0;
            }
        }
        [textField setSelectedRange:NSMakeRange(idx + offset, 0)];
        
        return NO;
    }
    
    return YES;
}

#pragma mark - CardIOPaymentViewControllerDelegate methods

#ifdef OL_KITE_OFFER_PAYPAL
- (void)userDidCancelPaymentViewController:(CardIOPaymentViewController *)paymentViewController {
    [self.textFieldCardNumber becomeFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)userDidProvideCreditCardInfo:(CardIOCreditCardInfo *)cardInfo inPaymentViewController:(CardIOPaymentViewController *)paymentViewController {
    [self.textFieldExpiryDate becomeFirstResponder];
    self.textFieldCardNumber.text = [NSString stringByFormattingCreditCardNumber:cardInfo.cardNumber];
    [self dismissViewControllerAnimated:YES completion:^(){}];
}
#endif

#pragma mark - Autorotate and Orientation Methods
// Currently here to disable landscape orientations and rotation on iOS 7. When support is dropped, these can be deleted.

- (BOOL)shouldAutorotate {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return YES;
    }
    else{
        return NO;
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
