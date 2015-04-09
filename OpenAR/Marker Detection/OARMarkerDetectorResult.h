//
//  OARMarkerDetectorResult.h
//  OpenAR
//
//  Created by Cameron Palmer on 09.04.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>

#import "OARFramemarker.h"



@interface OARMarkerDetectorResult : NSObject

@property (strong, nonatomic) OARFramemarker *framemarker;
@property (assign, nonatomic) matrix_float4x3 pose;

+ (instancetype)markerDetectorResultWithFramemarker:(OARFramemarker *)framemarker;
- (instancetype)initWithFramemarker:(OARFramemarker *)framemarker;

@end
