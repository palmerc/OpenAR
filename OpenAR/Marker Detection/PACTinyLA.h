//
//  PACTinyLA.h
//  SmartScan
//
//  Created by Cameron Palmer on 06.11.14.
//  Copyright (c) 2014 NTNU. All rights reserved.
//

#ifndef PACTinyLA_h
#define PACTinyLA_h

#include <vector>
#include <opencv2/opencv.hpp>



float perimeter(const std::vector<cv::Point2f> &a);
bool isInto(cv::Mat &contour, std::vector<cv::Point2f> &b);

#endif
