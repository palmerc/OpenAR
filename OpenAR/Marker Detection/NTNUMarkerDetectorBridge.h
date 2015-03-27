//
//  NTNUMarkerDetectorBridge.h
//  SmartScan
//
//  Created by Cameron Palmer on 09.01.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OARVideoSource.h"

@class NTNUCameraCalibration;

@protocol NTNUMarkerDetectorDelegate;



@interface NTNUMarkerDetectorBridge : NSObject <OARVideoSourceDelegate>

- (instancetype)init;
- (void)setCameraCalibration:(NTNUCameraCalibration *)cameraCalibration;
- (void)setFramemarkers:(NSArray *)framemarkers;

- (void)addObserver:(id <NTNUMarkerDetectorDelegate>)observer;
- (void)removeObserver:(id <NTNUMarkerDetectorDelegate>)observer;

@end



@protocol NTNUMarkerDetectorDelegate <NSObject>
@optional
- (void)didUpdateFramemarkerPositions:(NSArray *)framemarkers;

@end