//
//  QCARUtilities.cpp
//  OpenAR
//
//  Created by Cameron Palmer on 08.04.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#include "QCARUtilities.h"

#include "OARLogger.h"



#pragma mark - Image conversion

CGImageRef CGImageCreateWithQCARImage(const QCAR::Image *image)
{
    CGImageRef imageRef = NULL;

    TIMER_START(QCAR_TO_CGIMAGE);

    if (image) {
        QCAR::PIXEL_FORMAT pixelFormat = image->getFormat();

        CGColorSpaceRef colorSpace = NULL;
        switch (pixelFormat) {
            case QCAR::RGB888:
                colorSpace = CGColorSpaceCreateDeviceRGB();
                break;
            case QCAR::GRAYSCALE:
                colorSpace = CGColorSpaceCreateDeviceGray();
                break;
            case QCAR::YUV:
            case QCAR::RGB565:
            case QCAR::RGBA8888:
            case QCAR::INDEXED:
                OARLogError("Image format conversion not implemented.");
                break;
            case QCAR::UNKNOWN_FORMAT:
                OARLogError("Image format unknown.");
                break;
        }

        if (colorSpace != NULL) {
            int bitsPerComponent = 8;
            int width = image->getWidth();
            int height = image->getHeight();
            const void *baseAddress = image->getPixels();
            size_t totalBytes = QCAR::getBufferSize(width, height, pixelFormat);

            CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNone;
            CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

            int bitsPerPixel = QCAR::getBitsPerPixel(pixelFormat);
            int bytesPerRow = image->getStride();
            CGDataProviderRef provider = CGDataProviderCreateWithData(NULL,
                                                                      baseAddress,
                                                                      totalBytes,
                                                                      NULL);

            imageRef = CGImageCreate(width,
                                     height,
                                     bitsPerComponent,
                                     bitsPerPixel,
                                     bytesPerRow,
                                     colorSpace,
                                     bitmapInfo,
                                     provider,
                                     NULL,
                                     false,
                                     renderingIntent);
            CGDataProviderRelease(provider);
            CGColorSpaceRelease(colorSpace);
        }
    }
    
    TIMER_END(QCAR_TO_CGIMAGE);
    
    return imageRef;
}



#pragma mark - Matrix conversion

Eigen::Transform<float, 3, Eigen::Affine> eigenTransformWithQCARMatrix34f(const QCAR::Matrix34F &matrix)
{
    Eigen::Matrix3f rotationMatrix;
    rotationMatrix << matrix.data[0], matrix.data[1],  matrix.data[2],
                      matrix.data[4], matrix.data[5],  matrix.data[6],
                      matrix.data[8], matrix.data[9], matrix.data[10];
    Eigen::Affine3f rotation(rotationMatrix);

    Eigen::Vector3f translationVector;
    translationVector << matrix.data[3], matrix.data[7], matrix.data[11];
    Eigen::Translation3f translation(translationVector);

    return Eigen::Transform<float, 3, Eigen::Affine>(translation * rotation);
}

matrix_float4x3 simdMatrixWithQCARMatrix34F(const QCAR::Matrix34F &matrix)
{
    vector_float3 col0 = { matrix.data[0], matrix.data[4], matrix.data[8] };
    vector_float3 col1 = { matrix.data[1], matrix.data[5], matrix.data[9] };
    vector_float3 col2 = { matrix.data[2], matrix.data[6], matrix.data[10] };
    vector_float3 col3 = { matrix.data[3], matrix.data[7], matrix.data[11] };

    return matrix_from_columns(col0, col1, col2, col3);
}

matrix_float4x4 simdMatrixWithQCARMatrix44f(const QCAR::Matrix44F &matrix)
{
    vector_float4 col0 = { matrix.data[0], matrix.data[1], matrix.data[2], matrix.data[3] };
    vector_float4 col1 = { matrix.data[4], matrix.data[5], matrix.data[6], matrix.data[7] };
    vector_float4 col2 = { matrix.data[8], matrix.data[9], matrix.data[10], matrix.data[11] };
    vector_float4 col3 = { matrix.data[12], matrix.data[13], matrix.data[14], matrix.data[15] };

    return matrix_from_columns(col0, col1, col2, col3);
}

Eigen::Matrix4f eigenMatrixWithQCARMatrix44f(const QCAR::Matrix44F &matrix)
{
    float *data = reinterpret_cast<float *>(const_cast<float *>(matrix.data));
    return Eigen::Map<Eigen::Matrix<float, 4, 4, Eigen::RowMajor>>(data);
}

