//
//  NTNUCameraCalibrationFactoryJSON.m
//  SmartScan
//
//  Created by Cameron Palmer on 31.01.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import "NTNUCameraCalibrationFactoryJSON.h"

#import "NTNUDeviceCameraJSON.h"
#import "NTNUCameraCalibrationJSON.h"
#import "PACVideoSource.h"
#import "NTNULogger.h"

static NSString *const kCameraCalibrationFile = @"camera_calibration.json";



@implementation NTNUCameraCalibrationFactoryJSON

+ (NTNUCameraCalibration *)cameraCalibrationForVideoSource:(PACVideoSource *)videoSource
{
    NSDictionary *cameraCalibrationDictionary = [NTNUCameraCalibrationFactoryJSON cameraCalibrationDictionary];
    NSMutableDictionary *cameraDictionary = [NSMutableDictionary dictionaryWithCapacity:[cameraCalibrationDictionary count]];

    for (NSString *deviceKey in [cameraCalibrationDictionary allKeys]) {
        NSArray *deviceCameraCalibrations = cameraCalibrationDictionary[deviceKey];
        NTNUDeviceCamera *deviceCamera = [NTNUDeviceCameraJSON deviceCameraWithArray:deviceCameraCalibrations];
        cameraDictionary[deviceKey] = deviceCamera.cameraCalibrations;
    }

    NTNUCameraCalibration *currentCameraCalibration = nil;
    NTNUCameraPosition cameraPosition = videoSource.cameraPosition;
    if (cameraPosition != NTNUCameraPositionUnknown) {
        NSString *currentDeviceKey = [[UIDevice currentDevice] ntnu_deviceString];
        NSArray *cameraCalibrations = cameraDictionary[currentDeviceKey];
        for (NTNUCameraCalibrationJSON *cameraCalibration in cameraCalibrations) {
            if (cameraCalibration.position == cameraPosition) {
                cameraCalibration.videoSource = videoSource;
                currentCameraCalibration = cameraCalibration;
            }
        }
    } else {
        DDLogError(@"%s - No camera associated with video source.", __PRETTY_FUNCTION__);
    }

    if (currentCameraCalibration == nil) {
        DDLogError(@"WARNING - No camera calibration found. The app will not work without a calibrated camera.");
    }

    return currentCameraCalibration;
}


#pragma mark -

+ (NSDictionary *)cameraCalibrationDictionary
{
    NSString *resourceName = [kCameraCalibrationFile stringByDeletingPathExtension];
    NSString *extension = [kCameraCalibrationFile pathExtension];
    NSURL *cameraCalibrationFileURL = [[NSBundle mainBundle] URLForResource:resourceName withExtension:extension];
    NSData *cameraCalibrationData = [NSData dataWithContentsOfURL:cameraCalibrationFileURL];

    NSError *error = nil;
    NSDictionary *cameraCalibrationDictionary = [NSJSONSerialization JSONObjectWithData:cameraCalibrationData options:kNilOptions error:&error];
    if (error != nil) {
        DDLogError(@"%@", error);
    }

    return cameraCalibrationDictionary;
}

@end
