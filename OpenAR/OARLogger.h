//
//  OARLogger.h
//  OpenAR
//
//  Created by Cameron Palmer on 20.03.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#ifndef OpenAR_OARLogger_h
#define OpenAR_OARLogger_h

// C++

#if defined(__cplusplus)

#if defined(PERFORMANCE_DEBUG)
#define TIMER_START(name) int64 t_##name = cv::getTickCount()
#define TIMER_END(name) printf("TIMER_" #name ": %.2fms\n", \
1000.f * ((cv::getTickCount() - t_##name) / cv::getTickFrequency()))
#else
#define TIMER_START(name)
#define TIMER_END(name)
#endif

#endif

// Objective-C

#if defined(__OBJC__)

#import <CocoaLumberjack/DDLog.h>
extern int ddLogLevel;

#endif

#endif
