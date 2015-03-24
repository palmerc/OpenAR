//
//  OARVideoSource.m
//  OpenAR
//
//  Created by Cameron Palmer on 20.03.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#import "OARVideoSource.h"

#import "OARLogger.h"
#import "NSNumber+CVPixelFormatType.h"
#import "NSString+CameraResolution.h"

static NSString *const kCameraQueueName = @"no.ntnu.oar.cameraQueue";
static NSUInteger kFrameTimeBufferSize = 15;


@interface OARVideoSource ()
@property (strong, nonatomic) NSArray *supportedVideoResolutions;

@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureDevice *videoDevice;

@property (strong, nonatomic) NSPointerArray *observers;

@property (strong, nonatomic) dispatch_queue_t videoDataOutputQueue;
@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) NSNumber *pixelFormat;

@property (strong, nonatomic) id runtimeErrorHandlingObserver;

@property (unsafe_unretained, nonatomic) float *frameTimestamps;
@property (assign, nonatomic) NSUInteger frameTimestampIndex;
@property (assign, nonatomic) NSUInteger frameTimestampCount;
@property (assign, nonatomic) CMTimeValue lastFrameTimestamp;
@property (assign, nonatomic) CGFloat captureQueueFPS;

@property (assign, nonatomic, readwrite) CGSize cameraSize;

@end





@implementation OARVideoSource
@synthesize cameraResolution = _cameraResolution;
@synthesize cameraPosition = _cameraPosition;

- (void)dealloc
{
    free(_frameTimestamps);
    [self.captureSession stopRunning];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.supportedVideoResolutions = @[AVCaptureSessionPreset640x480,
                                           AVCaptureSessionPreset1280x720,
                                           AVCaptureSessionPreset1920x1080];
        _cameraSize = CGSizeZero;
        _cameraPosition = OARCameraPositionUnknown;
        _cameraResolution = OARCameraResolutionUnknown;
        _observers = [NSPointerArray weakObjectsPointerArray];
        _pixelFormat = @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);
        _videoDataOutputQueue = dispatch_queue_create([kCameraQueueName UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_videoDataOutputQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        _frameTimestamps = malloc(kFrameTimeBufferSize * sizeof(float));

        [self setupCaptureSession];
    }

    return self;
}

- (void)updateCameraSize
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

    self.cameraSize = cameraSize;

    @synchronized(self.observers) {
        for (id observer in self.observers) {
            if ([observer respondsToSelector:@selector(didUpdateCameraSize:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [observer didUpdateCameraSize:cameraSize];
                });
            }
        }
    }
}

- (void)addObserver:(id <OARVideoSourceDelegate>)observer
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

- (void)removeObserver:(id <OARVideoSourceDelegate>)observer
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

- (void)setVideoInputWithCameraPosition:(OARCameraPosition)position
{
    AVCaptureDevicePosition devicePosition;
    switch (_cameraPosition) {
        case OARCameraPositionFront:
            devicePosition = AVCaptureDevicePositionFront;
            break;
        case OARCameraPositionBack:
            devicePosition = AVCaptureDevicePositionBack;
            break;
        case OARCameraPositionUnknown:
            devicePosition = AVCaptureDevicePositionUnspecified;
            break;
    }

    DDLogVerbose(@"Starting camera at position %ld", devicePosition);
    AVCaptureDevice *videoDevice = [self cameraWithPosition:devicePosition];
    if (videoDevice == nil) {
        DDLogError(@"No device matching camera position - %ld", devicePosition);
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
        _videoInput = videoInput;
    } else {
        DDLogError(@"Couldn't add video input.");
    }
}



#pragma mark - Camera Start and Stop

- (void)startVideoSource
{
    void (^cameraSessionStart)() = ^{
        self.captureQueueFPS = 0.f;
        self.lastFrameTimestamp = 0.f;
        self.frameTimestampCount = 0;
        self.frameTimestampIndex = 0;

        if (self.cameraPosition == OARCameraPositionUnknown) {
            self.cameraPosition = OARCameraPositionBack;
        }
        [self setVideoInputWithCameraPosition:self.cameraPosition];

        __block NSArray *observersToNotify;
        @synchronized(self.observers) {
            observersToNotify = [self.observers allObjects];
        }

        dispatch_async(self.videoDataOutputQueue, ^{
            [self.captureSession startRunning];

            dispatch_async(dispatch_get_main_queue(), ^{
                for (id observer in observersToNotify) {
                    if ([observer respondsToSelector:@selector(didStartVideoSource:)]) {
                        [observer didStartVideoSource:self];
                    }
                }
            });
        });
    };

    if (self.isRunning) {
        [self stopVideoSourceWithCompletionHandler:cameraSessionStart];
    } else {
        cameraSessionStart();
    }
}

- (void)stopVideoSource
{
    [self stopVideoSourceWithCompletionHandler:NULL];
}

- (void)stopVideoSourceWithCompletionHandler:(void(^)())completionHandler
{
    __block NSArray *observersToNotify;
    @synchronized(self.observers) {
        observersToNotify = [self.observers allObjects];
    }

    [self.captureSession stopRunning];
    [[NSNotificationCenter defaultCenter] removeObserver:self.runtimeErrorHandlingObserver];

    dispatch_async(dispatch_get_main_queue(), ^{
        for (id observer in observersToNotify) {
            if ([observer respondsToSelector:@selector(didStopVideoSource:)]) {
                [observer didStopVideoSource:self];
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

- (OARDeviceIdentifier)device
{
    return [[UIDevice currentDevice] ntnu_deviceType];
}

- (OARCameraPosition)cameraPosition
{
    OARCameraPosition cameraPosition;

    AVCaptureDevicePosition captureDevicePosition = self.videoDevice.position;
    switch (captureDevicePosition) {
        case AVCaptureDevicePositionFront:
            cameraPosition = OARCameraPositionFront;
            break;
        case AVCaptureDevicePositionBack:
            cameraPosition = OARCameraPositionBack;
            break;
        case AVCaptureDevicePositionUnspecified:
            cameraPosition = OARCameraPositionUnknown;
            break;
    }

    return cameraPosition;
}

- (void)setCameraPosition:(OARCameraPosition)position
{
    if (position == _cameraPosition) {
        return;
    }

    _cameraPosition = position;

    if (self.isRunning) {
        [self startVideoSource];
    }
}

- (OARCameraResolution)availableCameraResolutions
{
    OARCameraResolution cameraResolutions = OARCameraResolutionUnknown;
    for (NSString *preset in self.supportedVideoResolutions) {
        if ([self.captureSession canSetSessionPreset:preset]) {
            OARCameraResolution resolution = [preset ntnu_cameraResolution];
            cameraResolutions |= resolution;
        }
    }

    return cameraResolutions;
}

- (OARCameraResolution)cameraResolution
{
    OARCameraResolution resolution = OARCameraResolutionUnknown;

    if ([self.captureSession.sessionPreset isEqualToString:AVCaptureSessionPreset640x480]) {
        resolution = OARCameraResolutionVGA;
    } else if ([self.captureSession.sessionPreset isEqualToString:AVCaptureSessionPreset1280x720]) {
        resolution = OARCameraResolution720p;
    } else if ([self.captureSession.sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
        resolution = OARCameraResolution1080p;
    }

    return resolution;
}

- (void)setCameraResolution:(OARCameraResolution)resolution
{
    if (resolution == _cameraResolution) {
        return;
    }

    int32_t minimumFrameRate, maximumFrameRate = 15;
    NSString *sessionPreset = AVCaptureSessionPresetHigh;
    if (resolution == OARCameraResolutionVGA) {
        sessionPreset = AVCaptureSessionPreset640x480;
        maximumFrameRate = 24;
    } else if (resolution == OARCameraResolution720p) {
        sessionPreset = AVCaptureSessionPreset1280x720;
        maximumFrameRate = 30;
    } else if (resolution == OARCameraResolution1080p) {
        sessionPreset = AVCaptureSessionPreset1920x1080;
        maximumFrameRate = 30;
    }

    if ([self.captureSession canSetSessionPreset:sessionPreset]) {
        DDLogInfo(@"Set session preset %@ at %d FPS", sessionPreset, maximumFrameRate);
        [self.captureSession setSessionPreset:sessionPreset];
    } else {
        DDLogError(@"Cannot set session preset to %@", sessionPreset);
    }

    CMTime minimumFrameDuration = CMTimeMake(1, minimumFrameRate);
    CMTime maximumFrameDuration = CMTimeMake(1, maximumFrameRate);

    NSError *error = nil;
    if ([self.videoDevice lockForConfiguration:&error]) {
        self.videoDevice.activeVideoMinFrameDuration = minimumFrameDuration;
        self.videoDevice.activeVideoMaxFrameDuration = maximumFrameDuration;
        [self.videoDevice unlockForConfiguration];
    } else {
        DDLogError(@"videoDevice lockForConfiguration returned error - %@", error);
    }

    _cameraResolution = resolution;
}

- (void)calculateFPSWithTime:(CMTime)presentationTime
{
    if (self.lastFrameTimestamp == 0) {
        self.lastFrameTimestamp = presentationTime.value;
        self.frameTimestampCount = 1;
    } else {
        float frameTime = (float)(presentationTime.value - self.lastFrameTimestamp) / presentationTime.timescale;
        self.lastFrameTimestamp = presentationTime.value;

        _frameTimestamps[self.frameTimestampIndex++] = frameTime;

        if (self.frameTimestampIndex >= kFrameTimeBufferSize) {
            self.frameTimestampIndex = 0;
        }

        float totalFrameTime = 0.f;
        for (NSUInteger i = 0; i < self.frameTimestampCount; i++) {
            totalFrameTime += _frameTimestamps[i];
        }

        float averageFrameTime = totalFrameTime / self.frameTimestampCount;
        float fps = 1.f / averageFrameTime;

        if (fabsf(fps - self.captureQueueFPS) > 0.1f) {
            self.captureQueueFPS = fps;
        }

        self.frameTimestampCount++;
        if (self.frameTimestampCount > kFrameTimeBufferSize) {
            self.frameTimestampCount = kFrameTimeBufferSize;
        }
    }
}



#pragma mark - AVCaptureSession delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
#if defined(DEBUG)
    static unsigned long frameCount = 1;
    NSDate *start = [NSDate date];
#endif

    CMTime presentationTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
    [self calculateFPSWithTime:presentationTime];

    CVImageBufferRef videoImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    CVPixelBufferLockBaseAddress(videoImageBuffer, kCVPixelBufferLock_ReadOnly);

    void *baseAddress = CVPixelBufferGetBaseAddressOfPlane(videoImageBuffer, 0);
    size_t width = CVPixelBufferGetWidthOfPlane(videoImageBuffer, 0);
    size_t height = CVPixelBufferGetHeightOfPlane(videoImageBuffer, 0);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(videoImageBuffer, 0);
    OSType pixelFormat = CVPixelBufferGetPixelFormatType(videoImageBuffer);
    size_t totalBytes = height * bytesPerRow;

    OARBasicVideoFrame videoFrame;
    videoFrame.width = width;
    videoFrame.height = height;
    videoFrame.bytesPerRow = bytesPerRow;
    videoFrame.totalBytes = totalBytes;
    videoFrame.pixelFormat = pixelFormat;
    videoFrame.baseAddress = baseAddress;

    if (self.cameraSize.width != width && self.cameraSize.height != height) {
        [self updateCameraSize];
    }

    @synchronized(self.observers) {
        for (id observer in self.observers) {
            if ([observer respondsToSelector:@selector(didUpdateGrayscaleVideoFrame:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [observer didUpdateGrayscaleVideoFrame:videoFrame];
                });
            }
            
            if ([observer respondsToSelector:@selector(didUpdateVideoImage:)]) {
                CIImage *videoImage = [CIImage imageWithCVPixelBuffer:videoImageBuffer];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [observer didUpdateVideoImage:videoImage];
                });
            }
        }
    }

    CVPixelBufferUnlockBaseAddress(videoImageBuffer, kCVPixelBufferLock_ReadOnly);

#if defined(DEBUG)
    NSDate *end = [NSDate date];
    NSTimeInterval time = [end timeIntervalSinceDate:start];
    NSString *imageSizeText = NSStringFromCGSize(CGSizeMake(width, height));
    DDLogDebug(@"Frame %lu, %@, processing time %.2fms, %.2f FPS", frameCount, imageSizeText, time * 1000, self.captureQueueFPS);
    frameCount++;
#endif
}

@end
