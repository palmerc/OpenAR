//
//  NTNUCameraCalibration.h
//  SmartScan
//
//  Created by Cameron Palmer on 31.01.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "NTNUCameraPosition.h"
#import "NTNUCameraResolution.h"



@interface NTNUCameraCalibration : NSObject
@property (strong, nonatomic, readonly) NSString *tool;
@property (assign, nonatomic, readonly) CGFloat rms;
@property (assign, nonatomic, readonly) CGSize focalLengthPixels;
@property (assign, nonatomic, readonly) CGFloat focalLength;
@property (assign, nonatomic, readonly) CGPoint principalPoint;
@property (assign, nonatomic, readonly) CGFloat skew;
@property (strong, nonatomic, readonly) NSArray *distortionCoefficients;
@property (strong, nonatomic, readonly) NSString *descriptiveText;
@property (assign, nonatomic, readonly) NTNUCameraPosition position;
@property (strong, nonatomic, readonly) NSString *device;
@property (strong, nonatomic, readonly) NSString *manufacturer;
@property (assign, nonatomic, readonly) CGSize nativeResolution;
@property (assign, nonatomic, readonly) CGSize currentResolution;

@end
