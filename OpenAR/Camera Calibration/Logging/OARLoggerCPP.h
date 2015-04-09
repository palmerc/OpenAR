//
//  OARLoggerCPP.h
//  OpenAR
//
//  Created by Cameron Palmer on 27.03.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#ifndef OpenAR_OARLoggerCPP_h
#define OpenAR_OARLoggerCPP_h

#if defined(__cplusplus)

#include "NSLogCPP.h"

#define clean_errno() (errno == 0 ? "None" : strerror(errno))
#define OARLogVerbose(M, ...) NSLogCPP(("[VERBOSE] " M), ##__VA_ARGS__)
#define OARLogDebug(M, ...) NSLogCPP("[DEBUG] (%s:%d) " M, __FILE__, __LINE__, ##__VA_ARGS__)
#define OARLogError(M, ...) NSLogCPP("[ERROR] (%s:%d: errno: %s) " M, __FILE__, __LINE__, clean_errno(), ##__VA_ARGS__)


#if defined(TIME_PERFORMANCE)

#include <opencv2/opencv.hpp>
#include <iomanip>

#define TIMER_START(name) int64 t_##name = cv::getTickCount()
#define TIMER_END(name) NSLogCPP("TIMER_" #name ": %.2fms\n", \
1000.f * ((cv::getTickCount() - t_##name) / cv::getTickFrequency()))
#else
#define TIMER_START(name)
#define TIMER_END(name)

#endif // defined(TIME_PERFORMANCE)

#if defined(MATRICES)
#define OARLogEigen(name, matrix) \
do { \
   std::stringstream b_##matrix; \
   b_##matrix << std::endl << name << std::endl << matrix << std::endl; \
   NSLogCPP("%s", b_##matrix.str().c_str()); \
} while(0)

#define OARLogCVMat(name, matrix) \
do { \
   std::stringstream b_##matrix; \
   b_##matrix << std::endl << name << std::endl << matrix << std::endl; \
   NSLogCPP("%s", b_##matrix.str().c_str()); \
} while(0)

#define OARLogSIMD4x3(name, matrix) \
do { \
   std::stringstream b_##matrix; \
   b_##matrix << std::endl << name << std::endl; \
   int columnCount = 4; \
   int rowCount = 3; \
   for (int row = 0; row < rowCount; row++) { \
      for (int column = 0; column < columnCount; column++) { \
        b_##matrix << std::setfill(' ') << std::setw(9) << matrix.columns[column][row]; \
        b_##matrix << ' '; \
      } \
      b_##matrix << std::endl; \
   } \
   b_##matrix << std::endl; \
   NSLogCPP("%s", b_##matrix.str().c_str()); \
} while (0)

#else
#define OARLogEigen(name, matrix)
#define OARLogCVMat(name, matrix)
#define OARLogSIMD4x3(name, matrix)
#endif

#endif

#endif
