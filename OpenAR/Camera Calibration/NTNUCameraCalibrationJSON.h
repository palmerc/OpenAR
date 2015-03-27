//
//  NTNUCameraCalibrationJSON.h
//  SmartScan
//
//  Created by Cameron Palmer on 31.01.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NTNUCameraCalibration.h"

@class OARVideoSource;



@interface NTNUCameraCalibrationJSON : NTNUCameraCalibration
@property (weak, nonatomic) OARVideoSource *videoSource;

+ (instancetype)cameraCalibrationWithDictionary:(NSDictionary *)dictionary;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
