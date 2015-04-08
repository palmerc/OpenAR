//
//  QCARUtilities.h
//  OpenAR
//
//  Created by Cameron Palmer on 08.04.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#ifndef __OpenAR__QCARUtilities__
#define __OpenAR__QCARUtilities__

#include <simd/simd.h>
#include <CoreGraphics/CoreGraphics.h>
#include <Eigen/Eigen>
#include <QCAR/Matrices.h>
#include <QCAR/Image.h>



CGImageRef CGImageCreateWithQCARImage(const QCAR::Image *image);

Eigen::Transform<float, 3, Eigen::Affine> eigenTransformWithQCARMatrix34f(const QCAR::Matrix34F &matrix);
Eigen::Matrix4f eigenMatrixWithQCARMatrix44f(const QCAR::Matrix44F &matrix);

matrix_float4x4 simdMatrixWithQCARMatrix44f(const QCAR::Matrix44F &matrix);

#endif /* defined(__OpenAR__QCARUtilities__) */
