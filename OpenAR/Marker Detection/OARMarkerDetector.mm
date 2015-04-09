//
//  OARMarkerDetector.m
//  OpenAR
//
//  Created by Cameron Palmer on 27.03.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#import "OARMarkerDetector.h"

#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <Accelerate/Accelerate.h>
#import <UIKit/UIKit.h>

#import <iostream>

#import <QCAR/QCAR.h>
#import <QCAR/QCAR_iOS.h>
#import <QCAR/CameraDevice.h>
#import <QCAR/Tool.h>
#import <QCAR/Renderer.h>
#import <QCAR/VideoBackgroundConfig.h>
#import <QCAR/UpdateCallback.h>
#import <QCAR/TrackerManager.h>
#import <QCAR/MarkerTracker.h>
#import <QCAR/Marker.h>
#import <QCAR/Image.h>
#import <QCAR/MarkerResult.h>
#import <QCAR/Trackable.h>

#import "QCARUtilities.h"
#import "OARMarkerDetectorResult.h"
#import "OARFramemarker.h"
#import "OARLogger.h"

static QCAR::PIXEL_FORMAT kQCARFrameFormat = QCAR::PIXEL_FORMAT::RGB888;

static NSString *const kQCARLicenseFileName = @"vuforia-license.json";
static NSString *const kQCARLicenseFileKey = @"key";
static NSString *const OAR_ERROR_DOMAIN = @"vuforia_error_domain";

namespace {
    OARMarkerDetector* instance = nil;

    class OpenAR_UpdateCallback : public QCAR::UpdateCallback {
        virtual void QCAR_onUpdate(QCAR::State& state);
    } qcarUpdate;
}


@interface OARMarkerDetector () {
    QCAR::CameraDevice::CAMERA _camera;
}

@property (assign, nonatomic) CGSize viewBoundsSize;
@property (assign, nonatomic) UIInterfaceOrientation mARViewOrientation;
@property (assign, nonatomic) BOOL mIsActivityInPortraitMode;

@property (assign, nonatomic, readwrite) OARCameraPosition position;
@property (assign, nonatomic, readwrite) OARCameraResolution resolution;
@property (strong, nonatomic, readwrite) NSArray *framemarkers;
@property (strong, nonatomic) NSDictionary *markerIdentifierToFramemarker;

@property (assign, nonatomic, getter=isCameraActive) BOOL cameraActive;

@property (assign, nonatomic) struct tagViewport {
int posX;
int posY;
int sizeX;
int sizeY;
} viewport;

@end


/**
 * 1. QCAR is initialized on a background thread.
 * 2. Register for resume and pause and initialize the tracker.
 * 3.
 */

@implementation OARMarkerDetector

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        instance = self;
        self.cameraActive = NO;
        self.position = OARCameraPositionUnknown;
        self.resolution = OARCameraResolutionUnknown;
        _camera = QCAR::CameraDevice::CAMERA_DEFAULT;

        [self performSelectorInBackground:@selector(initializeQCAR) withObject:nil];
    }

    return self;
}

- (void)initializeQCAR
{
    DDLogDebug(@"%s", __PRETTY_FUNCTION__);

    @autoreleasepool {
        QCAR::setInitParameters(QCAR::GL_20, [[self licenseKey] UTF8String]);
        NSInteger progress = 0;
        do {
            progress = QCAR::init();
            DDLogDebug(@"%d %%", progress);
        } while (0 <= progress && 100 > progress);

        if (progress == 100) {
            [self performSelectorOnMainThread:@selector(didInitializeMarkerDetector) withObject:nil waitUntilDone:NO];
        }
    }
}

- (void)didInitializeMarkerDetector
{
    DDLogDebug(@"%s", __PRETTY_FUNCTION__);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseMarkerDetector) name:UIApplicationWillResignActiveNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeMarkerDetector) name:UIApplicationDidBecomeActiveNotification object:nil];

    QCAR::TrackerManager &trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker *trackerBase = trackerManager.initTracker(QCAR::MarkerTracker::getClassType());
    if (trackerBase == NULL) {
        DDLogError(@"Failed to initialize MarkerTracker.");
    }

    QCAR::registerCallback(&qcarUpdate);

    [self.delegate didStartMarkerDetector:self];
}

- (void)pauseMarkerDetector
{
    QCAR::onPause();

    [self.delegate didPauseMarkerDetector:self];
}

- (void)resumeMarkerDetector
{
    QCAR::onResume();

    [self.delegate didResumeMarkerDetector:self];
}

- (void)stopMarkerDetector
{
    [self stopCamera];
    [self stopTracking];

    QCAR::onPause();
    QCAR::deinit();

    [self.delegate didStopMarkerDetector:self];
}



#pragma mark - Camera control

- (void)startCameraWithPosition:(OARCameraPosition)cameraPosition resolution:(OARCameraResolution)resolution
{
    QCAR::CameraDevice::CAMERA camera;
    switch (cameraPosition) {
        case OARCameraPositionFront:
            camera = QCAR::CameraDevice::CAMERA_FRONT;
            break;
        case OARCameraPositionBack:
            camera = QCAR::CameraDevice::CAMERA_BACK;
            break;
        case OARCameraPositionUnknown:
            camera = QCAR::CameraDevice::CAMERA_DEFAULT;
            break;
    }
    _position = cameraPosition;

    QCAR::CameraDevice::MODE mode = QCAR::CameraDevice::MODE_DEFAULT;
    switch (resolution) {
        case OARCameraResolutionVGA:
            mode = QCAR::CameraDevice::MODE_OPTIMIZE_SPEED;
            break;
        case OARCameraResolutionUnknown:
        case OARCameraResolution720p:
            mode = QCAR::CameraDevice::MODE_DEFAULT;
            break;
        case OARCameraResolution1080p:
            mode = QCAR::CameraDevice::MODE_OPTIMIZE_QUALITY;
            break;
    }
    _resolution = resolution;

    [self startCamera:camera withMode:mode];

    [self.delegate didStartCameraWithPosition:cameraPosition resolution:resolution];
}

- (void)startCamera:(QCAR::CameraDevice::CAMERA)camera withMode:(QCAR::CameraDevice::MODE)mode
{
    if (self.isCameraActive && _camera != camera) {
        [self stopCamera];
    }

    if (!QCAR::CameraDevice::getInstance().init(camera)) {
        DDLogError(@"Failed to initialize camera.");
    }

    if (!QCAR::CameraDevice::getInstance().start()) {
        DDLogError(@"Failed to start camera.");
    }

    if (!QCAR::CameraDevice::getInstance().selectVideoMode(mode)) {
        DDLogError(@"Failed to select video mode.");
    }

    if (!QCAR::setFrameFormat(kQCARFrameFormat, true)) {
        DDLogError(@"Failed to set frame format.");
    }

    _camera = camera;

    self.cameraActive = YES;
}

- (void)stopCamera
{
    if (self.isCameraActive) {
        QCAR::CameraDevice::getInstance().stop();
        QCAR::CameraDevice::getInstance().deinit();

        self.cameraActive = NO;
    }

    OARCameraPosition previousPosition = self.position;
    self.position = OARCameraPositionUnknown;

    OARCameraResolution previousResolution = self.resolution;
    self.resolution = OARCameraResolutionUnknown;

    _camera = QCAR::CameraDevice::CAMERA_DEFAULT;

    [self.delegate didStopCameraWithPosition:previousPosition resolution:previousResolution];
}



#pragma mark - Tracking control

- (void)startTrackingFramemarkers:(NSArray *)framemarkers
{
    DDLogDebug(@"%s", __PRETTY_FUNCTION__);

    QCAR::TrackerManager &trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker *trackerBase = trackerManager.getTracker(QCAR::MarkerTracker::getClassType());
    if (trackerBase == NULL) {
        DDLogError(@"Failed to get QCAR::MarkerTracker instance .");
    }

    QCAR::MarkerTracker *markerTracker = static_cast<QCAR::MarkerTracker *>(trackerBase);
    if (markerTracker == NULL) {
        DDLogError(@"Failed to get QCAR::MarkerTracker instance.");
    }

    NSMutableArray *mutableFramemarkersToTrack = [[NSMutableArray alloc] initWithCapacity:[framemarkers count]];
    for (OARFramemarker *framemarker in framemarkers) {
        int markerIdentifier = framemarker.markerIdentifier;
        if (markerIdentifier >= 0 && markerIdentifier < 512) {
            const char *description = [framemarker.descriptiveText UTF8String];
            float size = framemarker.size;
            QCAR::Marker *marker = markerTracker->createFrameMarker(markerIdentifier, description, QCAR::Vec2F(size, size));
            DDLogVerbose(@"Marker tracking for %d initialized.", marker->getMarkerId());
            [mutableFramemarkersToTrack addObject:framemarker];
        } else {
            DDLogError(@"Marker tracking identifier %d out-of-range.", markerIdentifier);
        }
    }

    if ([mutableFramemarkersToTrack count] > 0) {
        self.framemarkers = [mutableFramemarkersToTrack copy];
        NSMutableDictionary *mutableMarkerIdentifierToFramemarker = [[NSMutableDictionary alloc] initWithCapacity:[self.framemarkers count]];
        for (OARFramemarker *framemarker in self.framemarkers) {
            mutableMarkerIdentifierToFramemarker[@(framemarker.markerIdentifier)] = framemarker;
        }
        self.markerIdentifierToFramemarker = [mutableMarkerIdentifierToFramemarker copy];

        [self.delegate didStartTrackingForFramemarkers:self.framemarkers];
        trackerBase->start();
    }
}

- (void)stopTracking
{
    if (!self.isCameraActive) {
        if (!QCAR::TrackerManager::getInstance().deinitTracker(QCAR::MarkerTracker::getClassType())) {
            DDLogError(@"Failed to deinitialize QCAR:TrackerManager.");
        }

        self.framemarkers = nil;
        self.markerIdentifierToFramemarker = nil;
    } else {
        DDLogError(@"You MUST deinitialize the camera before deinitializing the QCAR::TrackerManager.");
    }
}



#pragma mark - QCAR Callback C++ / Obj-C

void OpenAR_UpdateCallback::QCAR_onUpdate(QCAR::State &state)
{
    if (instance != nil) {
        [instance QCAR_onUpdate:&state];
    }
}

- (void)QCAR_onUpdate:(QCAR::State *)state
{
    DDLogDebug(@"%s", __PRETTY_FUNCTION__);

    QCAR::Frame frame = state->getFrame();

    NSMutableArray *mutableImages = [[NSMutableArray alloc] initWithCapacity:frame.getNumImages()];
    for (int i = 0; i < frame.getNumImages(); i++) {
        const QCAR::Image *image = frame.getImage(i);
        CGImageRef imageRef = CGImageCreateWithQCARImage(image);
        [mutableImages addObject:[UIImage imageWithCGImage:imageRef]];
        CGImageRelease(imageRef);
    }

    if ([mutableImages count] > 0) {
        [self.delegate didUpdateCameraImages:[mutableImages copy]];
    }

    NSMutableArray *mutableMarkerDetectorResults = [[NSMutableArray alloc] initWithCapacity:state->getNumTrackableResults()];
    for (int i = 0; i < state->getNumTrackableResults(); ++i) {
        const QCAR::TrackableResult *trackableResult = state->getTrackableResult(i);
        NSAssert(trackableResult->isOfType(QCAR::MarkerResult::getClassType()), @"Not a marker result.");
        const QCAR::MarkerResult *markerResult = static_cast<const QCAR::MarkerResult *>(trackableResult);
        const QCAR::Marker &marker = markerResult->getTrackable();

        OARFramemarker *framemarker = self.markerIdentifierToFramemarker[@(marker.getMarkerId())];
        const QCAR::Matrix34F pose = trackableResult->getPose();
        matrix_float4x3 poseMatrix = simdMatrixWithQCARMatrix34F(pose);
        OARMarkerDetectorResult *markerDetectorResult = [OARMarkerDetectorResult markerDetectorResultWithFramemarker:framemarker];
        markerDetectorResult.pose = poseMatrix;
        [mutableMarkerDetectorResults addObject:markerDetectorResult];

#if defined(MATRICES)
        const char *title = [[NSString stringWithFormat:@"Marker %d pose matrix", marker.getMarkerId()] UTF8String];
        OARLogSIMD4x3(title, poseMatrix);
#endif
    }

    if ([mutableMarkerDetectorResults count] > 0) {
        [self.delegate didUpdateMarkerDetectorResults:[mutableMarkerDetectorResults copy]];
    }
}



#pragma mark - Projection Matrix

- (matrix_float4x4)projectionMatrix
{
    float nearPlane = 2.f;
    float farPlane = 5000.f;

    const QCAR::CameraCalibration &cameraCalibration = QCAR::CameraDevice::getInstance().getCameraCalibration();
    const QCAR::Matrix44F projectionMatrix = QCAR::Tool::getProjectionGL(cameraCalibration, nearPlane, farPlane);

    return simdMatrixWithQCARMatrix44f(projectionMatrix);
}



#pragma mark - License key

- (NSString *)licenseKey
{
    NSString *resourceName = [kQCARLicenseFileName stringByDeletingPathExtension];
    NSString *extension = [kQCARLicenseFileName pathExtension];
    NSURL *URL = [[NSBundle mainBundle] URLForResource:resourceName withExtension:extension];
    NSData *data = [[NSData alloc] initWithContentsOfURL:URL];

    NSError *error = nil;
    NSDictionary *licenseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
        DDLogError(@"%@", error);
    }

    return licenseDictionary[kQCARLicenseFileKey];
}

@end
