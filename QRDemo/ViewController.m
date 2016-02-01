//
//  ViewController.m
//  QRDemo
//
//  Created by CxDtreeg on 16/1/25.
//  Copyright © 2016年 CxDtreeg. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "QRCodeScanVC.h"

#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height

@interface ViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (strong, nonatomic) AVCaptureSession * captureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer * videoPreviewLayer;
@property (assign, nonatomic) CGFloat scaleValue;//

@property (strong, nonatomic) UIImageView * qrImageView;//生成的二维码图片
@property (strong, nonatomic) UITapGestureRecognizer * tapGesture;//单击手势

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor blueColor];
    button.frame = CGRectMake(0, 50, 100, 100);
    [button addTarget:self action:@selector(button) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"扫描二维码" forState:UIControlStateNormal];
    [self.view addSubview:button];
    
    UIButton * qrButton = [UIButton buttonWithType:UIButtonTypeCustom];
    qrButton.backgroundColor = [UIColor yellowColor];
    qrButton.frame = CGRectMake(110, 50, 100, 100);
    [qrButton setTitle:@"生成二维码" forState:UIControlStateNormal];
    [qrButton addTarget:self action:@selector(qrButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:qrButton];
    
    _qrImageView = [[UIImageView alloc] init];
    _qrImageView.backgroundColor = [UIColor whiteColor];
    _qrImageView.bounds = CGRectMake(0, 0, 100, 100);
    _qrImageView.center = self.view.center;
    _qrImageView.userInteractionEnabled = YES;
    
    _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureHandle)];
    [_qrImageView addGestureRecognizer:_tapGesture];
    
}

#pragma mark - 生成二维码
- (CIImage *)generatorQRCode{
    //二维码滤镜 只有2个参数 (ps:要找到这些参数必须得看开发文档,不然是找不到的)
    CIFilter * filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setDefaults];
    NSData * data = [@"我是二维码" dataUsingEncoding:NSISOLatin1StringEncoding];
    [filter setValue:data forKey:@"inputMessage"];
    CIImage * output = [filter outputImage];
    
    return output;
}

- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));//计算放大倍数
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;//计算放大之后的宽度
    size_t height = CGRectGetHeight(extent) * scale;//计算放大之后的高度
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();//创建设备颜色空间 灰色...what's this?
    
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}

#pragma mark - 单击手势处理
- (void)tapGestureHandle{
    [_qrImageView removeFromSuperview];
}

#pragma mark - 生成二维码按钮点击
- (void)qrButtonPressed{
    _qrImageView.image = [self createNonInterpolatedUIImageFormCIImage:[self generatorQRCode] withSize:50];
    [self.view addSubview:_qrImageView];
    
}

#pragma mark - 扫描二维码按钮点击
- (void)button{
    QRCodeScanVC * vc = [[QRCodeScanVC alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
