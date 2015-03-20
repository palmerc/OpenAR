//
//  UIDevice+Extensions.h
//  OAR
//
//  Created by Cameron Palmer on 01.02.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, OARDeviceIdentifier) {
    DeviceAppleUnknown,
    DeviceAppleSimulator,
    DeviceAppleiPhone,
    DeviceAppleiPhone3G,
    DeviceAppleiPhone3GS,
    DeviceAppleiPhone4,
    DeviceAppleiPhone4S,
    DeviceAppleiPhone5,
    DeviceAppleiPhone5C,
    DeviceAppleiPhone5S,
    DeviceAppleiPhone6,
    DeviceAppleiPhone6_Plus,
    DeviceAppleiPodTouch,
    DeviceAppleiPodTouch2G,
    DeviceAppleiPodTouch3G,
    DeviceAppleiPodTouch4G,
    DeviceAppleiPad,
    DeviceAppleiPad2,
    DeviceAppleiPad3G,
    DeviceAppleiPad4G,
    DeviceAppleiPad5G_Air,
    DeviceAppleiPadMini,
    DeviceAppleiPadMini2G
};



@interface UIDevice (OARExtensions)

+ (OARDeviceIdentifier)ntnu_deviceTypeWithString:(NSString *)deviceString;

- (NSString *)ntnu_deviceString;
- (OARDeviceIdentifier)ntnu_deviceType;

@end
