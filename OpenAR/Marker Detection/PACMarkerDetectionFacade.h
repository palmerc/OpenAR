//
//  PACMarkerDetectionFacade.h
//  SmartScan
//
//  Created by Cameron Palmer on 06.11.14.
//  Copyright (c) 2014 NTNU. All rights reserved.
//

#ifndef PACMarkerDetectionFacade_h
#define PACMarkerDetectionFacade_h

#include <vector>
#include <memory>

#include "PACCameraCalibration.h"
#include "Framemarker.h"
#include "NTNUBasicVideoFrame.h"



class PACMarkerDetectionFacade
{
public:
    virtual void setDocumentDirectory(const char *documentDirectory) = 0;
    virtual void processVideoFrame(const cv::Mat &videoFrame) = 0;
    virtual void setFramemarkers(std::vector<std::shared_ptr<ntnu::Framemarker>> framemarkers) = 0;
    virtual const std::vector<std::shared_ptr<ntnu::Framemarker>> &updatedMarkers() = 0;

    virtual ~PACMarkerDetectionFacade() {}
};

std::unique_ptr<PACMarkerDetectionFacade> markerDetectorWithCalibration(std::shared_ptr<PACCameraCalibration> calibration);

#endif
