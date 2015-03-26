//
//  PACCameraCalibration.h
//  SmartScan
//
//  Created by Cameron Palmer on 06.11.14.
//  Copyright (c) 2014 NTNU. All rights reserved.
//

#ifndef PACCameraCalibration_h
#define PACCameraCalibration_h

#include <opencv2/opencv.hpp>



class PACCameraCalibration
{
public:
    PACCameraCalibration();
    PACCameraCalibration(float focalLength,
                      float nativeWidth,
                      float nativeHeight,
                      float calibratedFocalLengthX,
                      float calibratedFocalLengthY,
                      float calibratedCenterX,
                      float calibratedCenterY);
    PACCameraCalibration(float focalLength,
                      float nativeWidth,
                      float nativeHeight,
                      float calibratedFocalLengthX,
                      float calibratedFocalLengthY,
                      float calibratedCenterX,
                      float calibratedCenterY,
                      float distortionCoefficient[5]);

    const cv::Mat getIntrinsic() const;
    const cv::Mat getIntrinsic(float width, float height) const;
    const cv::Mat &getDistortion() const;

    const std::string getDescription() const;

private:
    class PACCameraCalibrationInternal;
    PACCameraCalibrationInternal *_internal;
};

#endif
