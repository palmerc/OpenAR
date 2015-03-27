//
//  PACCameraCalibration.cpp
//  SmartScan
//
//  Created by Cameron Palmer on 06.11.14.
//  Copyright (c) 2014 NTNU. All rights reserved.
//

#include "PACCameraCalibration.h"

#include "OARLoggerCPP.h"



class PACCameraCalibration::PACCameraCalibrationInternal
{
public:
    PACCameraCalibrationInternal() :
    _focalLength(0.f),
    _width(0.f),
    _height(0.f),
    _intrinsic(cv::Mat::zeros(3, 3, CV_32F)),
    _distortion(cv::Mat::zeros(5, 1, CV_32F))
    {
    }

    ~PACCameraCalibrationInternal()
    {
    }

    cv::Mat _intrinsic;
    cv::Mat _distortion;
    float _focalLength;
    float _width;
    float _height;

    void initializePACCameraCalibration(float focalLength,
                                     float width,
                                     float height,
                                     float calibratedFocalLengthX,
                                     float calibratedFocalLengthY,
                                     float calibratedCenterX,
                                     float calibratedCenterY,
                                     float distortionCoefficient[5]);
};



#pragma mark - Constructors

PACCameraCalibration::~PACCameraCalibration()
{
    delete _internal;
}

PACCameraCalibration::PACCameraCalibration(float focalLength,
                                     float width,
                                     float height,
                                     float calibratedFocalLengthX,
                                     float calibratedFocalLengthY,
                                     float calibratedCenterX,
                                     float calibratedCenterY)
{
    this->_internal = new PACCameraCalibrationInternal();

    float distortionCoefficient[] = {0.f, 0.f, 0.f, 0.f, 0.f};
    this->_internal->initializePACCameraCalibration(focalLength, width, height, calibratedFocalLengthX, calibratedFocalLengthY, calibratedCenterX, calibratedCenterY, distortionCoefficient);
}

PACCameraCalibration::PACCameraCalibration(float focalLength,
                                     float width,
                                     float height,
                                     float calibratedFocalLengthX,
                                     float calibratedFocalLengthY,
                                     float calibratedCenterX,
                                     float calibratedCenterY,
                                     float distortionCoefficient[5])
{
    this->_internal = new PACCameraCalibrationInternal();

    this->_internal->initializePACCameraCalibration(focalLength, width, height, calibratedFocalLengthX, calibratedFocalLengthY, calibratedCenterX, calibratedCenterY, distortionCoefficient);
}

void PACCameraCalibration::PACCameraCalibrationInternal::initializePACCameraCalibration(float focalLength,
                                                    float width,
                                                    float height,
                                                    float calibratedFocalLengthX,
                                                    float calibratedFocalLengthY,
                                                    float calibratedCenterX,
                                                    float calibratedCenterY,
                                                    float distortionCoefficient[5])
{
    this->_focalLength = focalLength;
    this->_width = width;
    this->_height = height;

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

const std::string PACCameraCalibration::getDescription() const
{
    std::stringstream buffer;
    buffer << std::endl << "Camera intrinsic" << std::endl << this->_internal->_intrinsic << std::endl;
    buffer << std::endl << "Camera distortion" << std::endl << this->_internal->_distortion << std::endl;

    return buffer.str();
}

const cv::Mat PACCameraCalibration::getIntrinsic() const
{
    return this->_internal->_intrinsic;
}

const cv::Mat &PACCameraCalibration::getDistortion() const
{
    return this->_internal->_distortion;
}
