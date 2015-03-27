//
//  NTNUCameraCalibrationFactory.h
//  SmartScan
//
//  Created by Cameron Palmer on 10.01.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class NTNUCameraCalibration;
@class OARVideoSource;



@interface NTNUCameraCalibrationFactory : NSObject

+ (NTNUCameraCalibration *)cameraCalibrationForVideoSource:(OARVideoSource *)videoSource;

@end
