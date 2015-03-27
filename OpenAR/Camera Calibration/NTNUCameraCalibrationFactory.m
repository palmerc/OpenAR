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
#import "OARVideoSource.h"
#import "UIDevice+Extensions.h"
#import "OARLogger.h"



@implementation NTNUCameraCalibrationFactory

+ (NTNUCameraCalibration *)cameraCalibrationForVideoSource:(OARVideoSource *)videoSource
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
