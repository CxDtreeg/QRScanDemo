//
//  CDQRCodeScanVC.m
//  Scan QR code Demo
//
//  Created by CxDtreeg CIO on 2019/11/6.
//  Copyright © 2019 CxDtreeg. All rights reserved.
//

#import "CDQRCodeScanVC.h"
#import <AVFoundation/AVFoundation.h>

#define BOXWIDTH  250 //扫描范围宽度
#define BOXHEIGHT 250 //扫描范围高度

@interface CDQRCodeScanVC () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *prevLayer;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic, strong) AVCaptureMetadataOutput *videoMetadataOutput;
@property (nonatomic, strong) UIView *maskView;//遮罩层

@property (nonatomic, assign) BOOL isShowResulting;

@end

@implementation CDQRCodeScanVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialInterface];
    [self initDeviceAuth];
}

#pragma mark - 界面初始化
- (void)initialInterface {
    self.title = @"扫描二维码";
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"相册" style:UIBarButtonItemStylePlain target:self action:@selector(openPhotoAlbumEvent:)];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backPrevVC)];
    self.navigationItem.leftBarButtonItem = backItem;
    [self addMask];
}

- (void)backPrevVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 设置遮罩层
- (void)addMask{
    self.maskView = [[UIView alloc] init];
    self.maskView.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds));
    self.maskView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    [self.view addSubview:self.maskView];
    
    //创建路径
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, CGRectGetWidth(self.maskView.frame), CGRectGetHeight(self.maskView.frame))];//绘制和透明黑色遮盖层一样的矩形
    
    //路径取反
    [path appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake((CGRectGetWidth(self.view.frame)-BOXWIDTH)/2.0, (CGRectGetHeight(self.view.frame)-BOXHEIGHT)/2.0, BOXWIDTH, BOXHEIGHT)] bezierPathByReversingPath]];//绘制中间空白透明的矩形，并且取反路径。这样整个绘制的范围就只剩下，中间的矩形和边界之间的部分
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = path.CGPath;//将路径交给layer绘制
    [self.maskView.layer setMask:shapeLayer];//设置遮罩层
}

#pragma mark - 初始化设备授权信息
- (void)initDeviceAuth {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusAuthorized:
            [self initCapture];
            break;
        case AVAuthorizationStatusNotDetermined:{
            __weak typeof(self) weakSelf = self;
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted) {
                        [strongSelf initCapture];
                    }else {
                        [strongSelf showAuthAlert];
                    }
                });
            }];
        }
            break;
        case AVAuthorizationStatusRestricted:
        case AVAuthorizationStatusDenied:
            [self showAuthAlert];
            break;
        default:
            break;
    }
}

#pragma mark - 初始化扫描设备
- (void)initCapture {
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    
    //设置展示layer
    self.prevLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.prevLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.prevLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.prevLayer];
    [self.view bringSubviewToFront:self.maskView];
    
    self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    //识别区域
    CGRect recognitionRect = CGRectMake((CGRectGetWidth(self.view.frame)-BOXWIDTH)/2.0, (CGRectGetHeight(self.view.frame)-BOXHEIGHT)/2.0, BOXWIDTH, BOXHEIGHT);
    dispatch_async(self.sessionQueue, ^{
        NSError * error;
        //设置设备
        AVCaptureDevice * captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        //设置获取设备输入
        self.videoDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
        if (!self.videoDeviceInput) {//如果无法获取设备输入
            NSLog(@"%@",error.localizedDescription);
            return ;
        }
        //设置设备输出
        self.videoMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
        
        //设置捕获会话
        if ([self.session canAddInput:self.videoDeviceInput]) {
            [self.session addInput:self.videoDeviceInput];//设置设备输入
        }
        
        if ([self.session canAddOutput:self.videoMetadataOutput]) {
            [self.session addOutput:self.videoMetadataOutput];//设置设备输出
        }
        
        //设置输出代理
        dispatch_queue_t dispatchQueue = dispatch_queue_create("VideoDataOutputQueue", NULL);
        [self.videoMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
        //设置解析数据类型 自行在这里添加需要识别的各种码
        [self.videoMetadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeQRCode,AVMetadataObjectTypeUPCECode]];
        
        [self.session startRunning];
        
        //设置识别范围
        self.videoMetadataOutput.rectOfInterest = [self.prevLayer metadataOutputRectOfInterestForRect:recognitionRect];
    });
}

#pragma mark - 显示权限请求
- (void)showAuthAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"需要访问相机" message:@"需要有权访问您设备上的相机，点击“设置”按钮启用相机权限" preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"忽略" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf dismissViewControllerAnimated:YES completion:nil];
    }];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:sureAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - 处理扫描出来的二维码信息
- (void)qrCodeSuccessEvent:(NSString *)resultContent {
    self.isShowResulting = YES;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"扫描结果" message:resultContent preferredStyle:UIAlertControllerStyleAlert];
    __weak __typeof(self)weakSelf = self;
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf.isShowResulting = NO;
    }];
    [alertController addAction:sureAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - 打开相册
- (void)openPhotoAlbumEvent:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:^{}];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (self.isShowResulting) {
            return ;
        }
        for (AVMetadataObject *metadataObject in metadataObjects) {
            if (![metadataObject isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
                continue;
            }
            AVMetadataMachineReadableCodeObject *machineReadableCode = (AVMetadataMachineReadableCodeObject *)metadataObject;
            [self qrCodeSuccessEvent:machineReadableCode.stringValue];
        }
    });
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
    CIContext *ciContext = [CIContext contextWithOptions:nil];
    CIDetector *ciDetector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:ciContext options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
    
    NSArray *detectorArray = [ciDetector featuresInImage:ciImage];
    CGFloat maxCodeArea = 0;
    NSString *messageString = @"";
    //根据二维码的区域面积选择占面积最大的二维码识别
    for(int i = 0; i < detectorArray.count; i++) {
        CIQRCodeFeature *feature = [detectorArray objectAtIndex:i];
        CGFloat area = feature.bounds.size.width*feature.bounds.size.height;
        if (area>maxCodeArea) {
            maxCodeArea = area;
            messageString = feature.messageString;
        }
    }
    if (maxCodeArea > 0) {
        [self qrCodeSuccessEvent:messageString];
    }
}

- (void)dealloc {
    [self.session stopRunning];
    [self.session removeInput:self.videoDeviceInput];
    [self.session removeOutput:self.videoMetadataOutput];
    self.videoMetadataOutput = nil;
    self.videoDeviceInput = nil;
}

@end
