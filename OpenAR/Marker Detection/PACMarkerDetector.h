//
//  PACMarkerDetector.h
//  SmartScan
//
//  Created by Cameron Palmer on 06.11.14.
//  Copyright (c) 2014 NTNU. All rights reserved.
//

#ifndef PACMarkerDetector_h
#define PACMarkerDetector_h

#include <vector>
#include "PACMarkerDetectionFacade.h"



class PACMarkerDetector : public PACMarkerDetectionFacade
{
public:

    PACMarkerDetector(std::shared_ptr<PACCameraCalibration> calibration);
    ~PACMarkerDetector();

    void setDocumentDirectory(const char *documentDirectory);
    void setFramemarkers(std::vector<std::shared_ptr<ntnu::Framemarker>> framemarkers);

    void processVideoFrame(const cv::Mat &bgraFrame);
    const std::vector<std::shared_ptr<ntnu::Framemarker>> &updatedMarkers();

private:
    struct PACInternal;
    PACInternal *_internal;
};

#endif
