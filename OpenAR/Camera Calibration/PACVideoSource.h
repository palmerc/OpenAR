//
//  PACVideoSource.h
//  SmartScan
//
//  Created by Cameron Palmer on 06.11.14.
//  Copyright (c) 2014 NTNU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

#import "NTNUBasicVideoFrame.h"
#import "NTNUCameraCalibration.h"
#import "UIDevice+NTNUExtensions.h"

@protocol PACVideoSourceDelegate;



@interface PACVideoSource : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (assign, nonatomic, getter=isRunning, readonly) BOOL running;

@property (strong, nonatomic, readonly) AVCaptureSession *captureSession;
@property (strong, nonatomic, readonly) AVCaptureDevice *videoDevice;

@property (assign, nonatomic, readonly) NTNUDeviceIdentifier device;

@property (assign, nonatomic) NTNUCameraPosition cameraPosition;
@property (assign, nonatomic) NTNUCameraResolution cameraResolution;
@property (assign, nonatomic, readonly) CGSize cameraSize;

- (void)start;
- (void)stop;

- (NTNUCameraResolution)availableCameraResolutions;

- (void)addObserver:(id <PACVideoSourceDelegate>)observer;
- (void)removeObserver:(id <PACVideoSourceDelegate>)observer;

@end



@protocol PACVideoSourceDelegate <NSObject>
@optional
- (void)didUpdateGrayscaleVideoFrame:(NTNUBasicVideoFrame)videoFrame;
- (void)didUpdateVideoImage:(CIImage *)videoImage;
- (void)didStartCaptureSession:(AVCaptureSession *)captureSession;
- (void)didStopCaptureSession:(AVCaptureSession *)captureSession;

@end