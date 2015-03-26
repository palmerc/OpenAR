//
//  NTNUCameraResolution.h
//  SmartScan
//
//  Created by Cameron Palmer on 05.03.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#ifndef SmartScan_NTNUCameraResolution_h
#define SmartScan_NTNUCameraResolution_h

typedef NS_OPTIONS(NSInteger, NTNUCameraResolution) {
    NTNUCameraResolutionUnknown = 0,
    NTNUCameraResolutionVGA     = 1 << 0,
    NTNUCameraResolution720p    = 1 << 1,
    NTNUCameraResolution1080p   = 1 << 2
};

#endif
