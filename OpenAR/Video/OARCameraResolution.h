//
//  OARCameraResolution.h
//  OpenAR
//
//  Created by Cameron Palmer on 20.03.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#ifndef OpenAR_OARCameraResolution_h
#define OpenAR_OARCameraResolution_h

typedef NS_OPTIONS(NSInteger, OARCameraResolution) {
    OARCameraResolutionUnknown = 0,
    OARCameraResolutionVGA     = 1 << 0,
    OARCameraResolution720p    = 1 << 1,
    OARCameraResolution1080p   = 1 << 2
};

#endif
