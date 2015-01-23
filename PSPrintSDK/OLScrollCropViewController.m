//
//  OLScrollCropViewController.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 1/21/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import "OLScrollCropViewController.h"
#import <RMImageCropper.h>

@interface OLScrollCropViewController ()

@end

@implementation OLScrollCropViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self.cropView setFillRectWithColor:NO];
//    [self.cropView setResizeScrollViewToImage:NO];
    [self.cropView setClipsToBounds:YES];
}

-(void)viewWillAppear:(BOOL)animated{
    [self.cropView removeConstraint:self.aspectRatioConstraint];
    NSLayoutConstraint *con = [NSLayoutConstraint constraintWithItem:self.cropView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.cropView attribute:NSLayoutAttributeWidth multiplier:self.aspectRatio constant:0];
    [self.cropView addConstraints:@[con]];
    
    [self.cropView setImage:self.fullImage];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

-(void)viewDidLayoutSubviews{
//    [self.cropView centerImage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onBarButtonDoneTapped:(UIBarButtonItem *)sender {
    if ([self.delegate respondsToSelector:@selector(userDidCropImage:)]){
        [self.delegate userDidCropImage:[self.cropView editedImage]];
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end