//
//  OARVideoSource.h
//  OpenAR
//
//  Created by Cameron Palmer on 20.03.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

#import "OARBasicVideoFrame.h"
#import "OARCameraResolution.h"
#import "OARCameraPosition.h"
#import "UIDevice+Extensions.h"

@protocol OARVideoSourceDelegate;



@interface OARVideoSource : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (assign, nonatomic, getter=isRunning, readonly) BOOL running;

@property (assign, nonatomic, readonly) OARDeviceIdentifier device;

@property (assign, nonatomic) OARCameraPosition cameraPosition;
@property (assign, nonatomic) OARCameraResolution cameraResolution;
@property (assign, nonatomic, readonly) CGSize cameraSize;

- (void)startVideoSource;
- (void)stopVideoSource;

- (OARCameraResolution)availableCameraResolutions;

- (void)addObserver:(id <OARVideoSourceDelegate>)observer;
- (void)removeObserver:(id <OARVideoSourceDelegate>)observer;

@end



@protocol OARVideoSourceDelegate <NSObject>
@optional
- (void)didUpdateCameraSize:(CGSize)cameraSize;
- (void)didUpdateGrayscaleVideoFrame:(OARBasicVideoFrame)videoFrame;
- (void)didUpdateVideoImage:(CIImage *)videoImage;
- (void)didStartVideoSource:(OARVideoSource *)captureSession;
- (void)didStopVideoSource:(OARVideoSource *)captureSession;

@end
