//
//  NTNUCameraCalibrationFactory.m
//  SmartScan
//
//  Created by Cameron Palmer on 10.01.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import "NTNUCameraCalibrationFactory.h"

#import "NTNUCameraCalibrationFactoryJSON.h"
#import "NTNUCameraCalibration.h"
#import "PACVideoSource.h"
#import "UIDevice+NTNUExtensions.h"
#import "NTNULogger.h"



@implementation NTNUCameraCalibrationFactory

+ (NTNUCameraCalibration *)cameraCalibrationForVideoSource:(PACVideoSource *)videoSource
{
    NTNUCameraCalibration *cameraCalibration = nil;
    if (videoSource.isRunning) {        
        cameraCalibration = [NTNUCameraCalibrationFactoryJSON cameraCalibrationForVideoSource:videoSource];
    } else {
        DDLogError(@"%s - Video source is not running.", __PRETTY_FUNCTION__);
    }

    return cameraCalibration;
}

@end
