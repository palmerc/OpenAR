//
//  NSString+CameraResolution.m
//  OAR
//
//  Created by Cameron Palmer on 05.03.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import "NSString+CameraResolution.h"

#import <AVFoundation/AVFoundation.h>



@implementation NSString (CameraResolution)

- (OARCameraResolution)ntnu_cameraResolution
{
    return [[[NSString ntnu_cameraResolutionLookupTable] objectForKey:self] integerValue];
}

+ (NSDictionary *)ntnu_cameraResolutionLookupTable
{
    return @{
             AVCaptureSessionPresetLow: @(OARCameraResolutionUnknown),
             AVCaptureSessionPreset640x480: @(OARCameraResolutionVGA),
             AVCaptureSessionPreset1280x720: @(OARCameraResolution720p),
             AVCaptureSessionPreset1920x1080: @(OARCameraResolution1080p)
             };
}

@end
