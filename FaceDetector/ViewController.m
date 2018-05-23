//
//  ViewController.m
//  FaceDetector
//
//  Created by denghb on 2018/5/24.
//  Copyright © 2018年 denghb. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession  *_captureSession;
    GLKView           *_glview;
    CIContext         *_cicontext;
}

@end

@implementation ViewController
    
- (void)viewDidLoad {
    [super viewDidLoad];
}
    
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self openCamera];
}
    
- (void)openCamera
{
    NSLog(@"openCamera");
    // 上下文和预览视图
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _glview = [[GLKView alloc]initWithFrame:self.view.bounds context:context];
    [EAGLContext setCurrentContext:context];
    _glview.transform = CGAffineTransformMakeRotation(M_PI_2);
    _glview.frame = [UIApplication sharedApplication].keyWindow.bounds;
    _cicontext = [CIContext contextWithEAGLContext:context];
    [self.view addSubview:_glview];
    
    // 捕捉会话
    AVCaptureSession *session = [[AVCaptureSession alloc]init];
    [session setSessionPreset:AVCaptureSessionPreset1920x1080];
    _captureSession = session;
    
    // 输入
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    if (videoInput) {
        if ([_captureSession canAddInput:videoInput]){
            [_captureSession addInput:videoInput];
        }
    }
    
    // 输出
    AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
    [videoOut setAlwaysDiscardsLateVideoFrames:YES];
    [videoOut setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]}];
    [videoOut setSampleBufferDelegate:self queue:dispatch_queue_create("video.buffer", DISPATCH_QUEUE_SERIAL)];
    if ([_captureSession canAddOutput:videoOut]){
        [_captureSession addOutput:videoOut];
    }
    if (!_captureSession.isRunning){
        [_captureSession startRunning];
    }
}
    
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (_glview.context != [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:_glview.context];
    }
    CVImageBufferRef imageRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *image = [CIImage imageWithCVImageBuffer:imageRef];
    
    // 面部检测
    NSDictionary *opts = [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh
                                                     forKey:CIDetectorAccuracy];
    
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil
                                              options:opts];
    //得到面部数据
    NSArray* features = [detector featuresInImage:image];
    if (features.count > 0) {
        NSLog(@"%lu",features.count);
        for (CIFaceFeature *f in features)
        {
            CGRect aRect = f.bounds;
            NSLog(@"%f, %f, %f, %f", aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height);
            
            //眼睛和嘴的位置
            if(f.hasLeftEyePosition) NSLog(@"Left eye %g %g\n", f.leftEyePosition.x, f.leftEyePosition.y);
            if(f.hasRightEyePosition) NSLog(@"Right eye %g %g\n", f.rightEyePosition.x, f.rightEyePosition.y);
            if(f.hasMouthPosition) NSLog(@"Mouth %g %g\n", f.mouthPosition.x, f.mouthPosition.y);
        }
    }
    
    [_glview bindDrawable];
    [_cicontext drawImage:image inRect:image.extent fromRect:image.extent];
    [_glview display];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
