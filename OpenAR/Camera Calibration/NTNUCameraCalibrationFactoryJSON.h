//
//  NTNUCameraCalibrationFactoryJSON.h
//  SmartScan
//
//  Created by Cameron Palmer on 31.01.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import "NTNUCameraCalibrationFactory.h"



@interface NTNUCameraCalibrationFactoryJSON : NTNUCameraCalibrationFactory

+ (NTNUCameraCalibration *)cameraCalibrationForVideoSource:(OARVideoSource *)videoSource;

@end
