//
//  NTNUDeviceCameraCalibrationsJSON.h
//  SmartScan
//
//  Created by Cameron Palmer on 01.02.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import "NTNUDeviceCamera.h"



@interface NTNUDeviceCameraJSON : NTNUDeviceCamera

+ (instancetype)deviceCameraWithArray:(NSArray *)cameraDictionaries;

- (instancetype)initWithArray:(NSArray *)cameraDictionaries;

@end
