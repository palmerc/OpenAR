//
//  CameraCalibration.cpp
//  SmartScan
//
//  Created by Cameron Palmer on 06.11.14.
//  Copyright (c) 2014 NTNU. All rights reserved.
//

#include "CameraCalibration.h"

#include "vesLogger.h"



class CameraCalibration::CameraCalibrationInternal
{
public:
    CameraCalibrationInternal()
    {
        _focalLength = 0.f;
        _nativeWidth = 0.f;
        _nativeHeight = 0.f;
        _intrinsic = cv::Mat::zeros(3, 3, CV_32F);
        _distortion = cv::Mat::zeros(5, 1, CV_32F);
    }

    ~CameraCalibrationInternal()
    {
    }

    cv::Mat _intrinsic;
    cv::Mat _distortion;
    float _focalLength;
    float _nativeWidth;
    float _nativeHeight;

    void initializeCameraCalibration(float focalLength,
                                     float nativeWidth,
                                     float nativeHeight,
                                     float calibratedFocalLengthX,
                                     float calibratedFocalLengthY,
                                     float calibratedCenterX,
                                     float calibratedCenterY,
                                     float distortionCoefficient[5]);
};



#pragma mark - Constructors

CameraCalibration::CameraCalibration()
{
    this->_internal = new CameraCalibrationInternal();
}

CameraCalibration::CameraCalibration(float focalLength,
                                     float nativeWidth,
                                     float nativeHeight,
                                     float calibratedFocalLengthX,
                                     float calibratedFocalLengthY,
                                     float calibratedCenterX,
                                     float calibratedCenterY)
{
    this->_internal = new CameraCalibrationInternal();

    float distortionCoefficient[] = {0.f, 0.f, 0.f, 0.f, 0.f};
    this->_internal->initializeCameraCalibration(focalLength, nativeWidth, nativeHeight, calibratedFocalLengthX, calibratedFocalLengthY, calibratedCenterX, calibratedCenterY, distortionCoefficient);
}

CameraCalibration::CameraCalibration(float focalLength,
                                     float nativeWidth,
                                     float nativeHeight,
                                     float calibratedFocalLengthX,
                                     float calibratedFocalLengthY,
                                     float calibratedCenterX,
                                     float calibratedCenterY,
                                     float distortionCoefficient[5])
{
    this->_internal = new CameraCalibrationInternal();

    this->_internal->initializeCameraCalibration(focalLength, nativeWidth, nativeHeight, calibratedFocalLengthX, calibratedFocalLengthY, calibratedCenterX, calibratedCenterY, distortionCoefficient);
}

void CameraCalibration::CameraCalibrationInternal::initializeCameraCalibration(float focalLength,
                                                    float nativeWidth,
                                                    float nativeHeight,
                                                    float calibratedFocalLengthX,
                                                    float calibratedFocalLengthY,
                                                    float calibratedCenterX,
                                                    float calibratedCenterY,
                                                    float distortionCoefficient[5])
{
    this->_focalLength = focalLength;
    this->_nativeWidth = nativeWidth;
    this->_nativeHeight = nativeHeight;

    cv::Mat intrinsic = cv::Mat::eye(3, 3, CV_32F);
    intrinsic.at<float>(0, 0) = calibratedFocalLengthX;
    intrinsic.at<float>(1, 1) = calibratedFocalLengthY;
    intrinsic.at<float>(0, 2) = calibratedCenterX;
    intrinsic.at<float>(1, 2) = calibratedCenterY;
    this->_intrinsic = intrinsic;

    cv::Mat distortion = cv::Mat::zeros(5, 1, CV_32F);
    for (int i = 0; i < 5; i++) {
        distortion.at<float>(i) = distortionCoefficient[i];
    }
    this->_distortion = distortion;
}



#pragma mark - Getters

const std::string CameraCalibration::getDescription() const
{
    std::stringstream buffer;
    buffer << std::endl << "Camera intrinsic" << std::endl << this->_internal->_intrinsic << std::endl;
    buffer << std::endl << "Camera distortion" << std::endl << this->_internal->_distortion << std::endl;

    return buffer.str();
}

const cv::Mat CameraCalibration::getIntrinsic() const
{
    return this->_internal->_intrinsic;
}

const cv::Mat CameraCalibration::getIntrinsic(float width, float height) const
{
    float fx = this->_internal->_intrinsic.at<float>(0, 0);
    float fy = this->_internal->_intrinsic.at<float>(1, 1);
    float cx = this->_internal->_intrinsic.at<float>(0, 2);
    float cy = this->_internal->_intrinsic.at<float>(1, 2);
    float widthScaleFactor = fx / this->_internal->_focalLength;
    float heightScaleFactor = fy / this->_internal->_focalLength;
    float widthCross = widthScaleFactor * width;
    float heightCross = heightScaleFactor * height;
    float scaledFx = this->_internal->_focalLength * widthCross / this->_internal->_nativeWidth;
    float scaledFy = this->_internal->_focalLength * heightCross / this->_internal->_nativeHeight;

    float centerXCross = cx * width;
    float centerYCross = cy * height;
    float scaledCx = centerXCross / this->_internal->_nativeWidth;
    float scaledCy = centerYCross / this->_internal->_nativeHeight;

    cv::Mat intrinsic = cv::Mat::eye(3, 3, CV_32F);
    intrinsic.at<float>(0, 0) = scaledFx;
    intrinsic.at<float>(1, 1) = scaledFy;
    intrinsic.at<float>(0, 2) = scaledCx;
    intrinsic.at<float>(1, 2) = scaledCy;

    return intrinsic;
}

const cv::Mat &CameraCalibration::getDistortion() const
{
    return this->_internal->_distortion;
}