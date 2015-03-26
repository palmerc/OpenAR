//
//  NTNUDeviceCameraCalibrationsJSON.m
//  SmartScan
//
//  Created by Cameron Palmer on 01.02.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import "NTNUDeviceCameraJSON.h"

#import "NTNUCameraCalibrationJSON.h"
#import "UIDevice+NTNUExtensions.h"
#import "NTNULogger.h"



@interface NTNUDeviceCamera ()
@property (strong, nonatomic, readwrite) NSArray *cameraCalibrations;

@end



@implementation NTNUDeviceCameraJSON

+ (instancetype)deviceCameraWithArray:(NSArray *)cameraDictionaries
{
    return [[NTNUDeviceCameraJSON alloc] initWithArray:cameraDictionaries];
}

- (instancetype)initWithArray:(NSArray *)cameraDictionaries
{
    self = [super init];
    if (self) {
        [self updateWithArray:cameraDictionaries];
    }

    return self;
}

- (void)updateWithArray:(NSArray *)cameraDictionaries
{
    if ([cameraDictionaries isKindOfClass:[NSArray class]]) {
        NSMutableArray *mutableCameras = [NSMutableArray arrayWithCapacity:[cameraDictionaries count]];
        for (NSDictionary *cameraDictionary in cameraDictionaries) {
            NTNUCameraCalibration *cameraCalibraton = [NTNUCameraCalibrationJSON cameraCalibrationWithDictionary:cameraDictionary];
            [mutableCameras addObject:cameraCalibraton];
        }

        if ([mutableCameras count] > 0) {
            self.cameraCalibrations = [mutableCameras copy];
        }
    }
}

@end
