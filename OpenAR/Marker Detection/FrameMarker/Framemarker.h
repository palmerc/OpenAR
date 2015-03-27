//
//  Framemarker.h
//  OpenAR
//
//  Created by Cameron Palmer on 21.02.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#ifndef OpenAR_Framemarker_h
#define OpenAR_Framemarker_h

#include <vector>
#include <opencv2/opencv.hpp>
#include <Eigen/Eigen>
#include <opencv2/core/eigen.hpp>



namespace ntnu {
    struct FramemarkerImpl;

    class Framemarker
    {
    public:
        Framemarker();
        Framemarker(Framemarker &framemarker);
        virtual ~Framemarker();

        int markerIdentifier;
        std::string descriptiveText;
        std::string reference;
        bool centerOrigin;
        bool enabled;
        float size;

        cv::Mat cvPose;
        std::vector<cv::Point3f> corners3D;

        Eigen::Matrix4f eigenPose()
        {
            Eigen::Matrix4f eigenPose(Eigen::Matrix4f::Zero());
            cv::cv2eigen(this->cvPose, eigenPose);
            return eigenPose;
        }

    private:
        FramemarkerImpl *impl;
    };
}

#endif
