//
//  ViewController.m
//  QRDemo
//
//  Created by CxDtreeg on 16/1/25.
//  Copyright © 2016年 CxDtreeg. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "CDQRCodeScanVC.h"
#import "GenQRCodeVC.h"

#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor blueColor];
    button.frame = CGRectMake(0, 50, 100, 100);
    [button addTarget:self action:@selector(scanQRButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"扫描二维码" forState:UIControlStateNormal];
    [self.view addSubview:button];
    
    UIButton * qrButton = [UIButton buttonWithType:UIButtonTypeCustom];
    qrButton.backgroundColor = [UIColor redColor];
    qrButton.frame = CGRectMake(110, 50, 100, 100);
    [qrButton setTitle:@"生成二维码" forState:UIControlStateNormal];
    [qrButton addTarget:self action:@selector(genQRButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:qrButton];
}

#pragma mark - 生成二维码按钮点击
- (void)genQRButtonPressed{
    GenQRCodeVC *vc = [[GenQRCodeVC alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - 扫描二维码按钮点击
- (void)scanQRButtonPressed{
    CDQRCodeScanVC *vc = [[CDQRCodeScanVC alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
