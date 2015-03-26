//
//  PACMarker.h
//  SmartScan
//
//  Created by Cameron Palmer on 06.11.14.
//  Copyright (c) 2014 NTNU. All rights reserved.
//

#ifndef PACMarker_h
#define PACMarker_h

#include <vector>
#include <iostream>
#include <opencv2/opencv.hpp>



class PACMarker
{
public:
    PACMarker();

    friend bool operator<(const PACMarker &M1, const PACMarker &M2);
    friend std::ostream & operator<<(std::ostream &str, const PACMarker &M);

    static cv::Mat rotate(cv::Mat marker);
    static int hammingDistance(const cv::Mat &message);
    static int decodeMarkerMessage(const cv::Mat &message);
    static int decodeMarkerWithValidation(const cv::Mat &markerImage, int &nRotations);

    std::vector<cv::Point2f> points;
    cv::Mat transformation;

    int identifier;
};

#endif
