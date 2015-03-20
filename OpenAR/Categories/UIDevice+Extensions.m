//
//  UIDevice+Extensions.m
//  OAR
//
//  Created by Cameron Palmer on 01.02.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#import "UIDevice+Extensions.h"

#import <sys/utsname.h>



@implementation UIDevice (OARExtensions)

#pragma mark - Extension methods

+ (OARDeviceIdentifier)ntnu_deviceTypeWithString:(NSString *)deviceString
{
    NSDictionary *deviceTypeStringLookupTable = [UIDevice ntnu_deviceTypeStringLookupTable];
    NSNumber *deviceType = deviceTypeStringLookupTable[deviceString];

    return [deviceType unsignedIntegerValue];
}

- (NSString *)ntnu_deviceString
{
    NSDictionary *deviceStringLookup = [UIDevice ntnu_deviceStringLookupTable];
    OARDeviceIdentifier deviceType = [self ntnu_deviceType];
    NSString *deviceString = deviceStringLookup[@(deviceType)];

    return deviceString;
}

- (OARDeviceIdentifier)ntnu_deviceType
{
    NSDictionary *deviceTypeLookup = [UIDevice ntnu_deviceTypeLookupTable];
    NSString *appleDeviceDescription = [UIDevice ntnu_appleDeviceDescription];
    NSNumber *deviceType = deviceTypeLookup[appleDeviceDescription];

    return [deviceType unsignedIntegerValue];
}



#pragma mark - Helper methods

+ (NSDictionary *)ntnu_deviceTypeStringLookupTable
{
    NSDictionary *deviceStringLookupTable = [UIDevice ntnu_deviceStringLookupTable];
    NSArray *keys = [deviceStringLookupTable allKeys];
    NSMutableDictionary *deviceTypeStringLookupTable = [NSMutableDictionary dictionaryWithCapacity:[keys count]];
    for (NSString *key in keys) {
        NSNumber *value = deviceStringLookupTable[key];
        deviceTypeStringLookupTable[value] = key;
    }

    return [deviceTypeStringLookupTable copy];
}

+ (NSDictionary *)ntnu_deviceStringLookupTable
{
    return @{
             @(DeviceAppleSimulator): @"APPLE_IOS_SIMULATOR",
             @(DeviceAppleiPodTouch): @"APPLE_IPOD_TOUCH",
             @(DeviceAppleiPodTouch2G): @"APPLE_IPOD_TOUCH_2G",
             @(DeviceAppleiPodTouch3G): @"APPLE_IPOD_TOUCH_3G",
             @(DeviceAppleiPodTouch4G): @"APPLE_IPOD_TOUCH_4G",
             @(DeviceAppleiPhone): @"APPLE_IPHONE",
             @(DeviceAppleiPhone3G): @"APPLE_IPHONE_3G",
             @(DeviceAppleiPhone3GS): @"APPLE_IPHONE_3GS",
             @(DeviceAppleiPhone4): @"APPLE_IPHONE_4",
             @(DeviceAppleiPhone4S): @"APPLE_IPHONE_4S",
             @(DeviceAppleiPhone5): @"APPLE_IPHONE_5",
             @(DeviceAppleiPhone5C): @"APPLE_IPHONE_5C",
             @(DeviceAppleiPhone5S): @"APPLE_IPHONE_5S",
             @(DeviceAppleiPhone6_Plus): @"APPLE_IPHONE_6_PLUS",
             @(DeviceAppleiPhone6): @"APPLE_IPHONE_6",
             @(DeviceAppleiPad): @"APPLE_IPAD",
             @(DeviceAppleiPad2): @"APPLE_IPAD_2",
             @(DeviceAppleiPad3G): @"APPLE_IPAD_3G",
             @(DeviceAppleiPad4G): @"APPLE_IPAD_4G",
             @(DeviceAppleiPad5G_Air): @"APPLE_IPAD_5G_AIR",
             @(DeviceAppleiPadMini): @"APPLE_IPAD_MINI",
             @(DeviceAppleiPadMini2G): @"APPLE_IPAD_MINI_2G"
             };
}

+ (NSDictionary *)ntnu_deviceTypeLookupTable
{
    return @{
             @"i386": @(DeviceAppleSimulator),
             @"x86_64": @(DeviceAppleSimulator),
             @"iPod1,1": @(DeviceAppleiPodTouch),
             @"iPod2,1": @(DeviceAppleiPodTouch2G),
             @"iPod3,1": @(DeviceAppleiPodTouch3G),
             @"iPod4,1": @(DeviceAppleiPodTouch4G),
             @"iPhone1,1": @(DeviceAppleiPhone),
             @"iPhone1,2": @(DeviceAppleiPhone3G),
             @"iPhone2,1": @(DeviceAppleiPhone3GS),
             @"iPhone3,1": @(DeviceAppleiPhone4),
             @"iPhone3,3": @(DeviceAppleiPhone4),
             @"iPhone4,1": @(DeviceAppleiPhone4S),
             @"iPhone5,1": @(DeviceAppleiPhone5),
             @"iPhone5,2": @(DeviceAppleiPhone5),
             @"iPhone5,3": @(DeviceAppleiPhone5C),
             @"iPhone5,4": @(DeviceAppleiPhone5C),
             @"iPhone6,1": @(DeviceAppleiPhone5S),
             @"iPhone6,2": @(DeviceAppleiPhone5S),
             @"iPhone7,1": @(DeviceAppleiPhone6_Plus),
             @"iPhone7,2": @(DeviceAppleiPhone6),
             @"iPad1,1": @(DeviceAppleiPad),
             @"iPad2,1": @(DeviceAppleiPad2),
             @"iPad2,5": @(DeviceAppleiPadMini),
             @"iPad3,1": @(DeviceAppleiPad3G),
             @"iPad3,4": @(DeviceAppleiPad4G),
             @"iPad4,1": @(DeviceAppleiPad5G_Air),
             @"iPad4,2": @(DeviceAppleiPad5G_Air),
             @"iPad4,4": @(DeviceAppleiPadMini2G),
             @"iPad4,5": @(DeviceAppleiPadMini2G)
             };
}

+ (NSString *)ntnu_appleDeviceDescription
{
    struct utsname systemInfo;
    uname(&systemInfo);

    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

@end
