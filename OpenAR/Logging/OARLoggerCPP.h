//
//  OARLoggerCPP.h
//  OpenAR
//
//  Created by Cameron Palmer on 27.03.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#ifndef OpenAR_OARLoggerCPP_h
#define OpenAR_OARLoggerCPP_h

#if defined(__APPLE__) && defined(__MACH__)

#if defined(COCOALUMBERJACK)

#define LOGD(logTag, ...) Log.d(logTag, __VA_ARGS__)
#define LOGI(logTag, ...) Log.i(logTag, __VA_ARGS__)
#define LOGV(logTag, ...) Log.v(logTag, __VA_ARGS__)
#define LOGW(logTag, ...) Log.w(logTag, __VA_ARGS__)
#define LOGE(logTag, ...) Log.e(logTag, __VA_ARGS__)

#else

#include "NSLogCPP.h"

#define clean_errno() (errno == 0 ? "None" : strerror(errno))
#define OARLogVerbose(M, ...) NSLogCPP(("[VERBOSE] " M), ##__VA_ARGS__)
#define OARLogDebug(M, ...) NSLogCPP("[DEBUG] (%s:%d) " M, __FILE__, __LINE__, ##__VA_ARGS__)
#define OARLogError(M, ...) NSLogCPP("[ERROR] (%s:%d: errno: %s) " M, __FILE__, __LINE__, clean_errno(), ##__VA_ARGS__)


#if defined(TIME_PERFORMANCE)
#define TIME_START(name) int64 t_##name = cv::getTickCount()
#define TIME_END(name) NSLogCPP("TIMER_" #name ": %.2fms\n", \
1000.f * ((cv::getTickCount() - t_##name) / cv::getTickFrequency()))
#else
#define TIME_START(name)
#define TIME_END(name)
#endif

#if defined(MATRICES)
#define SSLogEigen(name, matrix) std::stringstream b_##matrix; \
b_##matrix << std::endl << name << std::endl << matrix << std::endl; \
NSLogCPP("%s", b_##matrix.str().c_str())
#define SSLogCVMat(name, matrix) std::stringstream b_##matrix; \
b_##matrix << name << std::endl << (matrix) << std::endl; \
std::cerr << b_##matrix.str()
#else
#define OARLogEigen(name, matrix)
#define OARLogCVMat(name, matrix)
#endif

#endif

#elif defined(__ANDROID_API__)

#include <android/log.h>

#define LOGD(logTag, ...) __android_log_print(ANDROID_LOG_DEBUG, logTag, __VA_ARGS__)
#define LOGI(logTag, ...) __android_log_print(ANDROID_LOG_INFO, logTag, __VA_ARGS__)
#define LOGV(logTag, ...) __android_log_print(ANDROID_LOG_VERBOSE, logTag, __VA_ARGS__)
#define LOGW(logTag, ...) __android_log_print(ANDROID_LOG_WARN, logTag, __VA_ARGS__)
#define LOGE(logTag, ...) __android_log_print(ANDROID_LOG_ERROR, logTag, __VA_ARGS__)

#endif

#endif
