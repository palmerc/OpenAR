//
//  OARMarkerDetector.h
//  OpenAR
//
//  Created by Cameron Palmer on 27.03.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <simd/simd.h>

#import "OARCameraAutofocusMode.h"
#import "OARCameraImageFormat.h"
#import "OARCameraPosition.h"
#import "OARCameraResolution.h"

@protocol OARMarkerDetectorDelegate;



@interface OARMarkerDetector : NSObject
@property (weak, nonatomic) id <OARMarkerDetectorDelegate> delegate;

@property (assign, nonatomic, getter=isFlashlightOn) BOOL flashlightOn;
@property (assign, nonatomic) OARCameraAutofocusMode autofocusMode;
@property (assign, nonatomic) OARCameraImageFormat imageFormats;

@property (assign, nonatomic, readonly) OARCameraPosition position;
@property (assign, nonatomic, readonly) OARCameraResolution resolution;
@property (assign, nonatomic, readonly) matrix_float4x4 projectionMatrix;
@property (strong, nonatomic, readonly) NSArray *framemarkers;

- (void)startCameraWithPosition:(OARCameraPosition)cameraPosition resolution:(OARCameraResolution)resolution;
- (void)stopCamera;

// You must start tracking before starting the camera
- (void)startTrackingFramemarkers:(NSArray *)framemarkers;
- (void)stopTracking;

@end



@protocol OARMarkerDetectorDelegate
@required
- (void)didStartMarkerDetector:(OARMarkerDetector *)markerDetector;
- (void)didResumeMarkerDetector:(OARMarkerDetector *)markerDetector;
- (void)didPauseMarkerDetector:(OARMarkerDetector *)markerDetector;
- (void)didStopMarkerDetector:(OARMarkerDetector *)markerDetector;

- (void)didStartCameraWithPosition:(OARCameraPosition)cameraPosition resolution:(OARCameraResolution)resolution;
- (void)didStopCameraWithPosition:(OARCameraPosition)cameraPosition resolution:(OARCameraResolution)resolution;

- (void)didStartTrackingForFramemarkers:(NSArray *)framemarkers;
- (void)didStopTrackingForFramemarkers:(NSArray *)framemarkers;

@optional
- (void)didUpdateProjectionMatrix:(matrix_float4x4)projectionMatrix;
- (void)didUpdateCameraImages:(NSArray *)cameraImages;
- (void)didUpdateMarkerDetectorResults:(NSArray *)framemarkers;

@end
