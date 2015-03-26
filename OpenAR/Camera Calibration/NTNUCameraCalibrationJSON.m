//
//  NTNUCameraCalibrationJSON.m
//  SmartScan
//
//  Created by Cameron Palmer on 31.01.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import "NTNUCameraCalibrationJSON.h"

#import "PACVideoSource.h"
#import "NTNULogger.h"



@interface NTNUCameraCalibration ()
@property (strong, nonatomic, readwrite) NSString *tool;
@property (assign, nonatomic, readwrite) CGFloat rms;
@property (assign, nonatomic, readwrite) CGFloat focalLength;
@property (assign, nonatomic, readwrite) CGFloat skew;
@property (strong, nonatomic, readwrite) NSArray *distortionCoefficients;
@property (strong, nonatomic, readwrite) NSString *descriptiveText;
@property (assign, nonatomic, readwrite) NTNUCameraPosition position;
@property (strong, nonatomic, readwrite) NSString *device;
@property (strong, nonatomic, readwrite) NSString *manufacturer;
@property (assign, nonatomic, readwrite) CGSize nativeResolution;
@property (assign, nonatomic, readwrite) CGSize currentResolution;

@property (assign, nonatomic, readwrite) CGSize internal_focalLengthPixels;
@property (assign, nonatomic, readwrite) CGPoint internal_principalPoint;

@end



@implementation NTNUCameraCalibrationJSON

+ (instancetype)cameraCalibrationWithDictionary:(NSDictionary *)dictionary
{
    return [[NTNUCameraCalibrationJSON alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        [self updateWithDictionary:dictionary];
    }

    return self;
}

- (void)updateWithDictionary:(NSDictionary *)dictionary
{
    for (NSString *key in [dictionary keyEnumerator]) {
        id JSONValue = [dictionary objectForKey:key];

        SEL selector = [[self.dispatchTable valueForKey:key] pointerValue];
        if (selector != NULL && [self respondsToSelector:selector]) {
            IMP imp = [self methodForSelector:selector];
            void (*method)(id, SEL, id) = (void *)imp;
            method(self, selector, JSONValue);
        } else {
            DDLogInfo(@"No selector found for pair - %@: %@", key, JSONValue);
        }
    }
}

- (NSDictionary *)dispatchTable
{
    return @{
             @"camera_calibration": [NSValue valueWithPointer:@selector(setCameraCalibrationWithDictionary:)],
             @"focal_length": [NSValue valueWithPointer:@selector(setFocalLengthWithDictionary:)],
             @"distortion": [NSValue valueWithPointer:@selector(setDistortionWithDictionary:)],
             @"principal_point": [NSValue valueWithPointer:@selector(setPrincipalPointWithDictionary:)],
             @"skew": [NSValue valueWithPointer:@selector(setSkewWithNumber:)],
             @"rms": [NSValue valueWithPointer:@selector(setRMSWithNumber:)],
             @"tool": [NSValue valueWithPointer:@selector(setToolWithString:)],

             @"camera_metadata": [NSValue valueWithPointer:@selector(setCameraMetadataWithDictionary:)],
             @"description": [NSValue valueWithPointer:@selector(setDescriptionWithString:)],
             @"device": [NSValue valueWithPointer:@selector(setDeviceWithString:)],
             @"position": [NSValue valueWithPointer:@selector(setPositionWithString:)],
             @"manufacturer": [NSValue valueWithPointer:@selector(setManufacturerWithString:)],
             @"native_resolution": [NSValue valueWithPointer:@selector(setNativeResolutionWithDictionary:)]
             };
}

- (void)setCameraCalibrationWithDictionary:(id)sender
{
    if ([sender isKindOfClass:[NSDictionary class]]) {
        NSDictionary *cameraCalibrationDictionary = sender;
        [self updateWithDictionary:cameraCalibrationDictionary];
    }
}

- (void)setCameraMetadataWithDictionary:(id)sender
{
    if ([sender isKindOfClass:[NSDictionary class]]) {
        NSDictionary *cameraMetadataDictionary = sender;
        [self updateWithDictionary:cameraMetadataDictionary];
    }
}

- (void)setDistortionWithDictionary:(id)sender
{
    if ([sender isKindOfClass:[NSDictionary class]]) {
        NSDictionary *distortionDictionary = sender;
        NSNumber *radial_k1 = distortionDictionary[@"k1"];
        NSNumber *radial_k2 = distortionDictionary[@"k2"];
        NSNumber *radial_k3 = distortionDictionary[@"k3"];
        NSNumber *tangential_p1 = distortionDictionary[@"p1"];
        NSNumber *tangential_p2 = distortionDictionary[@"p2"];
        self.distortionCoefficients = @[radial_k1, radial_k2, tangential_p1, tangential_p2, radial_k3];
    }
}

- (void)setSkewWithNumber:(id)sender
{
    if ([sender isKindOfClass:[NSNumber class]]) {
        NSNumber *skew = sender;
        self.skew = [skew floatValue];
    }
}

- (void)setFocalLengthWithDictionary:(id)sender
{
    if ([sender isKindOfClass:[NSDictionary class]]) {
        NSDictionary *focalLengthDictionary = sender;
        CGFloat mm = [focalLengthDictionary[@"mm"] floatValue];
        CGFloat x = [focalLengthDictionary[@"x"] doubleValue];
        CGFloat y = [focalLengthDictionary[@"y"] doubleValue];

        self.internal_focalLengthPixels = CGSizeMake(x, y);
        self.focalLength = mm;
    }
}

- (void)setPrincipalPointWithDictionary:(id)sender
{
    if ([sender isKindOfClass:[NSDictionary class]]) {
        NSDictionary *principalPointDictionary = sender;
        CGFloat x = [principalPointDictionary[@"x"] doubleValue];
        CGFloat y = [principalPointDictionary[@"y"] doubleValue];

        self.internal_principalPoint = CGPointMake(x, y);
    }
}

- (void)setRMSWithNumber:(id)sender
{
    if ([sender isKindOfClass:[NSNumber class]]) {
        NSNumber *rms = sender;
        self.rms = [rms doubleValue];
    }
}

- (void)setToolWithString:(id)sender
{
    if ([sender isKindOfClass:[NSString class]]) {
        NSString *tool = sender;
        self.tool = tool;
    }
}

- (void)setDescriptionWithString:(id)sender
{
    if ([sender isKindOfClass:[NSString class]]) {
        NSString *descriptiveText = sender;
        self.descriptiveText = descriptiveText;
    }
}

- (void)setDeviceWithString:(id)sender
{
    if ([sender isKindOfClass:[NSString class]]) {
        NSString *device = sender;
        self.device = device;
    }
}

- (void)setPositionWithString:(id)sender
{
    if ([sender isKindOfClass:[NSString class]]) {
        NSString *locationValue = sender;

        NTNUCameraPosition position;
        if ([locationValue isEqualToString:@"front"]) {
            position = NTNUCameraPositionFront;
        } else if ([locationValue isEqualToString:@"rear"]) {
            position = NTNUCameraPositionBack;
        } else {
            position = NTNUCameraPositionUnknown;
        }

        self.position = position;
    }
}

- (void)setManufacturerWithString:(id)sender
{
    if ([sender isKindOfClass:[NSString class]]) {
        NSString *manufacturer = sender;
        self.manufacturer = manufacturer;
    }
}

- (void)setNativeResolutionWithDictionary:(id)sender
{
    if ([sender isKindOfClass:[NSDictionary class]]) {
        NSDictionary *nativeResolutionDictionary = sender;
        CGFloat width = [nativeResolutionDictionary[@"width"] doubleValue];
        CGFloat height = [nativeResolutionDictionary[@"height"]  doubleValue];
        CGSize nativeResolution = CGSizeMake(width, height);
        self.nativeResolution = nativeResolution;
    }
}

- (void)setVideoSource:(PACVideoSource *)videoSource
{
    if (videoSource.isRunning) {
        CGSize cameraSize = videoSource.cameraSize;
        self.currentResolution = cameraSize;
    } else {
        DDLogError(@"Camera is not running, therefore camera calibration is likely wrong.");
    }

    _videoSource = videoSource;
}

@end
