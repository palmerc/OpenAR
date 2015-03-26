//
//  PACVideoSource.mm
//  SmartScan
//
//  Created by Cameron Palmer on 06.11.14.
//  Copyright (c) 2014 NTNU. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>
#import <CoreVideo/CoreVideo.h>
#import <UIKit/UIKit.h>

#import "NTNULogger.h"
#import "NTNUCameraCalibration.h"
#import "PACVideoSource.h"
#import "NSNumber+CVPixelFormatType.h"
#import "NSString+NTNUCameraResolution.h"

static NSString *const kCameraQueueName = @"no.ntnu.smartscan.cameraQueue";



@interface PACVideoSource ()
@property (strong, nonatomic) NSArray *supportedVideoResolutions;

@property (strong, nonatomic, readwrite) AVCaptureSession *captureSession;
@property (strong, nonatomic, readwrite) AVCaptureDevice *videoDevice;

@property (strong, nonatomic) NSPointerArray *observers;

@property (strong, nonatomic) dispatch_queue_t videoDataOutputQueue;
@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) NSNumber *pixelFormat;

@property (strong, nonatomic) id runtimeErrorHandlingObserver;

@end



@implementation PACVideoSource
@synthesize cameraResolution = _cameraResolution;
@synthesize cameraPosition = _cameraPosition;

- (void)dealloc
{
    [self.captureSession stopRunning];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.supportedVideoResolutions = @[AVCaptureSessionPreset640x480,
                                           AVCaptureSessionPreset1280x720,
                                           AVCaptureSessionPreset1920x1080];
        _cameraPosition = NTNUCameraPositionUnknown;
        _cameraResolution = NTNUCameraResolutionUnknown;
        _observers = [NSPointerArray weakObjectsPointerArray];
        _pixelFormat = @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);
        _videoDataOutputQueue = dispatch_queue_create([kCameraQueueName UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_videoDataOutputQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));

        [self setupCaptureSession];
    }

    return self;
}

- (CGSize)cameraSize
{
    CGSize cameraSize = CGSizeZero;

    if ([self.captureSession isRunning]) {
        NSArray *ports = [self.videoInput ports];
        AVCaptureInputPort *usePort = nil;
        for (AVCaptureInputPort *port in ports) {
            if (usePort == nil || [port.mediaType isEqualToString:AVMediaTypeVideo]) {
                usePort = port;
            }
        }

        if (usePort) {
            CMFormatDescriptionRef formatDescription = [usePort formatDescription];
            CMVideoDimensions videoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription);
        
            cameraSize = CGSizeMake(videoDimensions.width, videoDimensions.height);
        }
    }

    return cameraSize;
}

- (void)addObserver:(id <PACVideoSourceDelegate>)observer
{
    if (observer == nil) {
        return;
    }

    DDLogVerbose(@"%s - %@", __PRETTY_FUNCTION__, observer);

    @synchronized(self.observers) {
        for (id object in self.observers) {
            if (object == observer) {
                return;
            }
        }

        [self.observers addPointer:(__bridge void *)(observer)];
    }
}

- (void)removeObserver:(id <PACVideoSourceDelegate>)observer
{
    if (observer == nil) {
        return;
    }

    DDLogVerbose(@"%s - %@", __PRETTY_FUNCTION__, observer);

    @synchronized(self.observers) {
        NSInteger deletionIndex = -1;
        for (int i = 0; i < [[self.observers allObjects] count]; i++) {
            id candidate = [self.observers pointerAtIndex:i];
            if (candidate == observer) {
                deletionIndex = i;
            }
        }

        if (deletionIndex >= 0) {
            [self.observers removePointerAtIndex:deletionIndex];
        }
    }
}



#pragma mark - Capture Session Configuration

- (void)setupCaptureSession
{
    self.captureSession = [[AVCaptureSession alloc] init];
    [self addRawViewOutput];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    AVCaptureDevice *captureDevice = nil;

    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            captureDevice = device;
            break;
        }
    }

    return captureDevice;
}

- (void)addRawViewOutput
{
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    captureOutput.alwaysDiscardsLateVideoFrames = YES;

    [captureOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];

    NSMutableArray *mutablePixelFormatTypes = [NSMutableArray array];
    [captureOutput.availableVideoCVPixelFormatTypes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [mutablePixelFormatTypes addObject:[obj ntnu_descriptivePixelFormat]];
    }];
    NSString *pixelFormats = [mutablePixelFormatTypes componentsJoinedByString:@",\n"];
    DDLogVerbose(@"Available pixel formats:\n%@\n", pixelFormats);
    
    NSString *pixelBufferFormatKey = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    captureOutput.videoSettings = @{pixelBufferFormatKey: self.pixelFormat};

    if ([self.captureSession canAddOutput:captureOutput]) {
        [self.captureSession addOutput:captureOutput];
    }
}

- (void)setVideoInputWithCameraPosition:(NTNUCameraPosition)position
{
    AVCaptureDevicePosition devicePosition;
    switch (_cameraPosition) {
        case NTNUCameraPositionFront:
            devicePosition = AVCaptureDevicePositionFront;
            break;
        case NTNUCameraPositionBack:
            devicePosition = AVCaptureDevicePositionBack;
            break;
        case NTNUCameraPositionUnknown:
            devicePosition = AVCaptureDevicePositionUnspecified;
            break;
    }

    DDLogVerbose(@"Starting camera at position %d", devicePosition);
    AVCaptureDevice *videoDevice = [self cameraWithPosition:devicePosition];
    if (videoDevice == nil) {
        DDLogError(@"No device matching camera position - %d", devicePosition);
    }
    DDLogVerbose(@"Device reported field of view as %.02f degrees", videoDevice.activeFormat.videoFieldOfView);
    self.videoDevice = videoDevice;

    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:&error];
    if (error != nil) {
        DDLogError(@"Couldn't create video input. - %@", error);
    }

    self.videoInput = videoInput;
}

- (void)setVideoInput:(AVCaptureDeviceInput *)videoInput
{
    if (self.videoInput != videoInput) {
        [self.captureSession removeInput:self.videoInput];
    }

    if ([self.captureSession canAddInput:videoInput]) {
        [self.captureSession addInput:videoInput];
        [self enumerateSessionPresets];
        _videoInput = videoInput;
    } else {
        DDLogError(@"Couldn't add video input.");
    }
}

- (void)enumerateSessionPresets
{

}



#pragma mark - Camera Start and Stop

- (void)start
{
    void (^cameraSessionStart)() = ^{
        [self setVideoInputWithCameraPosition:self.cameraPosition];

        __block NSArray *observersToNotify;
        @synchronized(self.observers) {
            observersToNotify = [self.observers allObjects];
        }

        dispatch_async(self.videoDataOutputQueue, ^{
            [self.captureSession startRunning];

            dispatch_async(dispatch_get_main_queue(), ^{
                for (id observer in observersToNotify) {
                    if ([observer respondsToSelector:@selector(didStartCaptureSession:)]) {
                        [observer didStartCaptureSession:self.captureSession];
                    }
                }
            });
        });
    };

    if (self.isRunning) {
        [self stopWithCompletionHandler:cameraSessionStart];
    } else {
        cameraSessionStart();
    }
}

- (void)stop
{
    [self stopWithCompletionHandler:NULL];
}

- (void)stopWithCompletionHandler:(void(^)())completionHandler
{
    __block NSArray *observersToNotify;
    @synchronized(self.observers) {
        observersToNotify = [self.observers allObjects];
    }

    [self.captureSession stopRunning];
    [[NSNotificationCenter defaultCenter] removeObserver:self.runtimeErrorHandlingObserver];

    dispatch_async(dispatch_get_main_queue(), ^{
        for (id observer in observersToNotify) {
            if ([observer respondsToSelector:@selector(didStopCaptureSession:)]) {
                [observer didStopCaptureSession:self.captureSession];
            }
        }

        if (completionHandler != NULL) {
            completionHandler();
        }
    });
}



#pragma mark - Camera Getters

- (BOOL)isRunning
{
    return self.captureSession.isRunning;
}

- (NTNUDeviceIdentifier)device
{
    return [[UIDevice currentDevice] ntnu_deviceType];
}

- (NTNUCameraPosition)cameraPosition
{
    NTNUCameraPosition cameraPosition;

    AVCaptureDevicePosition captureDevicePosition = self.videoDevice.position;
    switch (captureDevicePosition) {
        case AVCaptureDevicePositionFront:
            cameraPosition = NTNUCameraPositionFront;
            break;
        case AVCaptureDevicePositionBack:
            cameraPosition = NTNUCameraPositionBack;
            break;
        case AVCaptureDevicePositionUnspecified:
            cameraPosition = NTNUCameraPositionUnknown;
            break;
    }

    return cameraPosition;
}

- (void)setCameraPosition:(NTNUCameraPosition)position
{
    if (position == _cameraPosition) {
        return;
    }

    _cameraPosition = position;

    if (self.isRunning) {
        [self start];
    }
}

- (NTNUCameraResolution)availableCameraResolutions
{
    NTNUCameraResolution cameraResolutions = NTNUCameraResolutionUnknown;
    for (NSString *preset in self.supportedVideoResolutions) {
        if ([self.captureSession canSetSessionPreset:preset]) {
            NTNUCameraResolution resolution = [preset ntnu_cameraResolution];
            cameraResolutions |= resolution;
        }
    }

    return cameraResolutions;
}

- (NTNUCameraResolution)cameraResolution
{
    NTNUCameraResolution resolution = NTNUCameraResolutionUnknown;

    if ([self.captureSession.sessionPreset isEqualToString:AVCaptureSessionPreset640x480]) {
        resolution = NTNUCameraResolutionVGA;
    } else if ([self.captureSession.sessionPreset isEqualToString:AVCaptureSessionPreset1280x720]) {
        resolution = NTNUCameraResolution720p;
    } else if ([self.captureSession.sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
        resolution = NTNUCameraResolution1080p;
    }

    return resolution;
}

- (void)setCameraResolution:(NTNUCameraResolution)resolution
{
    if (resolution == _cameraResolution) {
        return;
    }

    int32_t frameRate = 15;
    NSString *sessionPreset = AVCaptureSessionPresetHigh;
    if (resolution == NTNUCameraResolutionVGA) {
        sessionPreset = AVCaptureSessionPreset640x480;
        frameRate = 24;
    } else if (resolution == NTNUCameraResolution720p) {
        sessionPreset = AVCaptureSessionPreset1280x720;
        frameRate = 30;
    } else if (resolution == NTNUCameraResolution1080p) {
        sessionPreset = AVCaptureSessionPreset1920x1080;
        frameRate = 30;
    }

    if ([self.captureSession canSetSessionPreset:sessionPreset]) {
        DDLogInfo(@"Set session preset %@ at %d FPS", sessionPreset, frameRate);
        [self.captureSession setSessionPreset:sessionPreset];
    } else {
        DDLogError(@"Cannot set session preset to %@", sessionPreset);
    }

    CMTime frameDuration = CMTimeMake(1, frameRate);

    NSError *error = nil;
    if ([self.videoDevice lockForConfiguration:&error]) {
        self.videoDevice.activeVideoMinFrameDuration = frameDuration;
        self.videoDevice.activeVideoMaxFrameDuration = frameDuration;
        [self.videoDevice unlockForConfiguration];
    } else {
        DDLogError(@"videoDevice lockForConfiguration returned error - %@", error);
    }



    _cameraResolution = resolution;
}



#pragma mark - AVCaptureSession delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
#if defined(DEBUG)
    static unsigned long frameCount = 1;
    NSDate *start = [NSDate date];
#endif

    CVImageBufferRef videoImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    CVPixelBufferLockBaseAddress(videoImageBuffer, kCVPixelBufferLock_ReadOnly);

    CIImage *videoImage = [CIImage imageWithCVPixelBuffer:videoImageBuffer];

    void *baseAddress = CVPixelBufferGetBaseAddressOfPlane(videoImageBuffer, 0);
    size_t width = CVPixelBufferGetWidthOfPlane(videoImageBuffer, 0);
    size_t height = CVPixelBufferGetHeightOfPlane(videoImageBuffer, 0);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(videoImageBuffer, 0);
    OSType pixelFormat = CVPixelBufferGetPixelFormatType(videoImageBuffer);
    size_t totalBytes = height * bytesPerRow;

    NTNUBasicVideoFrame videoFrame;
    videoFrame.width = width;
    videoFrame.height = height;
    videoFrame.bytesPerRow = bytesPerRow;
    videoFrame.totalBytes = totalBytes;
    videoFrame.pixelFormat = pixelFormat;
    videoFrame.rawPixelData = baseAddress;

    @synchronized(self.observers) {
        for (id observer in self.observers) {
            if ([observer respondsToSelector:@selector(didUpdateGrayscaleVideoFrame:)]) {
                [observer didUpdateGrayscaleVideoFrame:videoFrame];
            }
            if ([observer respondsToSelector:@selector(didUpdateVideoImage:)]) {
                [observer didUpdateVideoImage:videoImage];
            }
        }
    }

    CVPixelBufferUnlockBaseAddress(videoImageBuffer, kCVPixelBufferLock_ReadOnly);

#if defined(DEBUG)
    NSDate *end = [NSDate date];
    NSTimeInterval time = [end timeIntervalSinceDate:start];
    NSString *imageSizeText = NSStringFromCGSize(CGSizeMake(width, height));
    DDLogDebug(@"Frame %lu, %@, processing time %.1fms", frameCount, imageSizeText, time * 1000);
    frameCount++;
#endif
}

@end