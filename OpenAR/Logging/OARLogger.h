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


// Performance - Timing
#if defined(PERFORMANCE_DEBUG)
#define TIMER_START(name) int64 t_##name = cv::getTickCount()
#define TIMER_END(name) printf("TIMER_" #name ": %.2fms\n", \
1000.f * ((cv::getTickCount() - t_##name) / cv::getTickFrequency()))
#else
#define TIMER_START(name)
#define TIMER_END(name)
#endif

// Matrices
#if defined(MATRICES)
#define SSLogEigen(name, matrix) std::stringstream b_##matrix; \
b_##matrix << std::endl << name << std::endl << matrix << std::endl; \
NSLogCPP("%s", b_##matrix.str().c_str())
#define SSLogCVMat(name, matrix) std::stringstream b_##matrix; \
b_##matrix << name << std::endl << (matrix) << std::endl; \
std::cerr << b_##matrix.str()
#else
#define SSLogEigen(name, matrix)
#define SSLogCVMat(name, matrix)
#endif


#endif

// Objective-C

#if defined(__OBJC__)

#import <CocoaLumberjack/DDLog.h>
extern int ddLogLevel;

#endif

#endif
