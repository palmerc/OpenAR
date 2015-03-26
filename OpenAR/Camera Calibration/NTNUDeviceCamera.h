//
//  NTNUDeviceCameraCalibrations.h
//  SmartScan
//
//  Created by Cameron Palmer on 01.02.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import "NTNUCameraCalibration.h"



@interface NTNUDeviceCamera : NSObject
@property (strong, nonatomic, readonly) NSArray *cameraCalibrations;

@end
