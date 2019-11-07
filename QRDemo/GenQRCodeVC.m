//
//  GenQRCodeVC.m
//  QRDemo
//
//  Created by CxDtreeg CIO on 2019/11/7.
//  Copyright © 2019 CxDtreeg. All rights reserved.
//

#import "GenQRCodeVC.h"

#define QRCodeSize 250

@interface GenQRCodeVC ()

@property(nonatomic, strong) UIImageView *qrImageView;

@end

@implementation GenQRCodeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialInterface];
    self.qrImageView.image = [self createQRCodeWithSize:QRCodeSize dataString:@"我是二维码"];
}

- (void)initialInterface {
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.qrImageView];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backPrevVC)];
    self.navigationItem.leftBarButtonItem = backItem;
}

- (void)backPrevVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.qrImageView.bounds = CGRectMake(0, 0, QRCodeSize, QRCodeSize);
    self.qrImageView.center = self.view.center;
}

#pragma mark - QRCode
// 生成原始的二维码图片
- (UIImage *)createQRCodeWithSize:(CGFloat)size dataString:(NSString *)dataString{
    // 1.创建滤镜对象
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 2.还原滤镜初始化属性
    [filter setDefaults];
    // 3.将需要生成二维码的数据转换成二进制
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    // 4.给二维码滤镜设置数据
    [filter setValue:data forKeyPath:@"inputMessage"];
    // 5.获取滤镜生成的图片
    CIImage *ciImage =  [filter outputImage];
    UIImage *newImage = [self createNonInterpolatedUIImageFormCIImage:ciImage withSize:size];
    return newImage;
}

//生成指定大小的UIImage
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));//计算放大倍数
    
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;//计算放大之后的宽度
    size_t height = CGRectGetHeight(extent) * scale;//计算放大之后的高度
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
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

#pragma mark - setter & getter
- (UIImageView *)qrImageView {
    if (!_qrImageView) {
        _qrImageView = [[UIImageView alloc] init];
    }
    return _qrImageView;
}

@end
