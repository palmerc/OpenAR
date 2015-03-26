//
//  NTNUCameraCalibration.m
//  SmartScan
//
//  Created by Cameron Palmer on 31.01.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import "NTNUCameraCalibration.h"



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

@property (assign, nonatomic) CGSize internal_focalLengthPixels;
@property (assign, nonatomic) CGPoint internal_principalPoint;


@end



@implementation NTNUCameraCalibration

- (NSString *)description
{
    return self.descriptiveText;
}

- (CGSize)focalLengthPixels
{
    CGFloat nativeFocalLengthPixelsWidth = self.internal_focalLengthPixels.width;
    CGFloat nativeFocalLengthPixelsHeight = self.internal_focalLengthPixels.height;
    CGFloat averageFocalLengthPixels = (nativeFocalLengthPixelsWidth + nativeFocalLengthPixelsHeight) / 2.f;

    CGFloat maximumNativeResolution = MAX(self.nativeResolution.width, self.nativeResolution.height);

    CGFloat currentResolutionWidth = self.currentResolution.width;
    CGFloat currentResolutionHeight = self.currentResolution.height;
    CGFloat maximumCurrentResolution = MAX(currentResolutionWidth, currentResolutionHeight);

    CGFloat scaledPixelsPerMillimeter = averageFocalLengthPixels *  (maximumCurrentResolution / maximumNativeResolution);

    return CGSizeMake(scaledPixelsPerMillimeter, scaledPixelsPerMillimeter);
}

- (CGPoint)principalPoint
{
    CGFloat leadingSpaceX = (self.nativeResolution.width - self.currentResolution.width) / 2.f;
    CGFloat scaledPrincipalPointX = self.internal_principalPoint.x - leadingSpaceX;

    CGFloat leadingSpaceY = (self.nativeResolution.height - self.currentResolution.height) / 2.f;
    CGFloat scaledPrincipalPointY = self.internal_principalPoint.y - leadingSpaceY;

    return CGPointMake(scaledPrincipalPointX, scaledPrincipalPointY);
}

@end
