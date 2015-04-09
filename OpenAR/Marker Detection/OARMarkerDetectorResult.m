//
//  OARMarkerDetectorResult.m
//  OpenAR
//
//  Created by Cameron Palmer on 09.04.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#import "OARMarkerDetectorResult.h"



@implementation OARMarkerDetectorResult

+ (instancetype)markerDetectorResultWithFramemarker:(OARFramemarker *)framemarker
{
    return [[[self class] alloc] initWithFramemarker:framemarker];
}

- (instancetype)initWithFramemarker:(OARFramemarker *)framemarker
{
    self = [super init];
    if (self) {
        _framemarker = framemarker;
    }

    return self;
}

@end
