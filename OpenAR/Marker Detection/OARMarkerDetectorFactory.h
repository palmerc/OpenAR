//
//  OARMarkerDetectorFactory.h
//  OpenAR
//
//  Created by Cameron Palmer on 27.03.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OARMarkerDetector;

typedef NS_ENUM(NSInteger, OARMarkerDetectorBackend) {
    OARMarkerDetectorBackendPAC,
    OARMarkerDetectorBackendVuforia
};



@interface OARMarkerDetectorFactory : NSObject

+ (id <OARMarkerDetector>)markerDetectorWithBackend:(OARMarkerDetectorBackend)backend;

@end
