//
//  QRCodeScanVC.m
//  QRDemo
//
//  这是一个最简化的二维码/条形码扫描VC可以在此基础上添加扫描动画等效果
//
//  Created by CxDtreeg on 16/1/25.
//  Copyright © 2016年 CxDtreeg. All rights reserved.
//

#import "QRCodeScanVC.h"

#define BOXWIDTH  250 //扫描范围宽度
#define BOXHEIGHT 250 //扫描范围高度

@interface QRCodeScanVC () <AVCaptureMetadataOutputObjectsDelegate>

@property (strong, nonatomic) AVCaptureSession * captureSession;//捕获会话
@property (strong, nonatomic) AVCaptureVideoPreviewLayer * captureVideoPreviewLayer;//视频预览层

@end

@implementation QRCodeScanVC

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //要在页面完全显示之后执行
    [self lazyExcute];
}

#pragma mark - 延迟执行
- (void)lazyExcute{
    if (![self isAuthorizationCamera]) {
        return ;
    }
    
    //添加通知设置 扫描范围
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandle:) name:AVCaptureInputPortFormatDescriptionDidChangeNotification object:nil];
    
    [self startScan];
    [self addMask];
}

#pragma mark - 判断是否具有调用摄像头权限
- (BOOL)isAuthorizationCamera{
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authorizationStatus == AVAuthorizationStatusRestricted ||
        authorizationStatus == AVAuthorizationStatusDenied) {
        UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:@"" message:@"请在iPhone的“设置-隐私-相机”选项中设置访问权限" preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertVC animated:YES completion:nil];
        
        UIAlertAction * action = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        
        UIAlertAction * action1 = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            dispatch_after(0.2, dispatch_get_main_queue(), ^{//添加多线程消除错误
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Privacy"]];//隐私设置
            });
        }];
        
        [alertVC addAction:action];
        [alertVC addAction:action1];
        return NO;
    }
    
    return YES;
}

#pragma mark - Notification 处理
- (void)notificationHandle:(NSNotification *)notification{
    AVCaptureMetadataOutput * output = (AVCaptureMetadataOutput*)_captureSession.outputs[0];
    CGRect rect = CGRectMake((CGRectGetWidth(self.view.frame)-BOXWIDTH)/2.0, (CGRectGetHeight(self.view.frame)-BOXHEIGHT)/2.0, BOXWIDTH, BOXHEIGHT);
    
    output.rectOfInterest = [_captureVideoPreviewLayer metadataOutputRectOfInterestForRect:rect];
}

#pragma mark - 设置遮罩层
- (void)addMask{
    
    UIView * maskView = [[UIView alloc] init];
    maskView.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds));
    maskView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    [self.view addSubview:maskView];
    
    //创建路径
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, CGRectGetWidth(maskView.frame), CGRectGetHeight(maskView.frame))];//绘制和透明黑色遮盖层一样的矩形
    
    //路径取反
    [path appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake((CGRectGetWidth(self.view.frame)-BOXWIDTH)/2.0, (CGRectGetHeight(self.view.frame)-BOXHEIGHT)/2.0, BOXWIDTH, BOXHEIGHT)] bezierPathByReversingPath]];//绘制中间空白透明的矩形，并且取反路径。这样整个绘制的范围就只剩下，中间的矩形和边界之间的部分
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = path.CGPath;//将路径交给layer绘制
    [maskView.layer setMask:shapeLayer];//设置遮罩层
}

#pragma mark - 开始扫描
- (void)startScan{
    NSError * error;
    //设置设备
    AVCaptureDevice * captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];//设置媒体类型AVMediaTypeVideo:视频类型；AVMediaTypeAudio:音频类型；AVMediaTypeMuxed：混合类型
    
    //设置获取设备输入
    AVCaptureDeviceInput * deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    if (!deviceInput) {//如果无法获取设备输入
        NSLog(@"%@",error.localizedDescription);
        return ;
    }
    
    //设置设备输出
    AVCaptureMetadataOutput * captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    
    //设置捕获会话
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession addInput:deviceInput];//设置设备输入
    [_captureSession addOutput:captureMetadataOutput];//设置设备输出
    
    //设置输出代理
    dispatch_queue_t dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    //设置解析数据类型 自行在这里添加需要识别的各种码
    [captureMetadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeQRCode,AVMetadataObjectTypeUPCECode]];
    
    //设置展示layer
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    _captureVideoPreviewLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    [self.view.layer addSublayer:_captureVideoPreviewLayer];
    
    //放大1.5倍
    _captureVideoPreviewLayer.affineTransform = CGAffineTransformMakeScale(1.5, 1.5);
    AVCaptureOutput * output = (AVCaptureOutput *)_captureSession.outputs[0];
    AVCaptureConnection * focus = [output connectionWithMediaType:AVMediaTypeVideo];//获得摄像头焦点
    focus.videoScaleAndCropFactor = 1.5;//焦点放大
    
    //开始执行摄像头
    [_captureSession startRunning];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject * metadataObj = [metadataObjects objectAtIndex:0];
        //在这里获取解析出来的值
        //打印扫描出来的字符串
        NSLog(@"%@",[metadataObj stringValue]);
        [_captureSession stopRunning];//停止运行
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"显示" message:[metadataObj stringValue] preferredStyle:UIAlertControllerStyleAlert];
            __weak typeof(self) weakSelf = self;
            UIAlertAction * action1 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf.captureSession startRunning];
            }];
            [alert addAction:action1];
            [self presentViewController:alert animated:YES completion:nil];
        });
        
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
