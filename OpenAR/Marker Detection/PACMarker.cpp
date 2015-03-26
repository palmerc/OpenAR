//
//  PACMarker.cpp
//  SmartScan
//
//  Created by Cameron Palmer on 06.11.14.
//  Copyright (c) 2014 NTNU. All rights reserved.
//

#include "PACMarker.h"

//#define MARKER_DEBUG 1



PACMarker::PACMarker()
: identifier(-1)
{
}

bool operator<(const PACMarker &M1, const PACMarker &M2)
{
    return M1.identifier < M2.identifier;
}

cv::Mat PACMarker::rotate(cv::Mat marker)
{
    cv::Mat transpose(marker.t());
    cv::flip(transpose, transpose, 1);
    return transpose;
}

int PACMarker::hammingDistance(const cv::Mat &message)
{
    int validCodewords[4][5] =
    {
        {1,0,0,0,0},
        {1,0,1,1,1},
        {0,1,0,0,1},
        {0,1,1,1,0}
    };

    int distance = 0;

    for (int y = 0; y < 5; y++) {
        int minimumSum = std::numeric_limits<int>::max();

        for (int p = 0; p < 4; p++) {
            int sum = 0;
            //now, count
            for (int x = 0; x < 5; x++) {
                sum += message.at<uchar>(y,x) == validCodewords[p][x] ? 0 : 1;
            }

            if (minimumSum > sum) {
                minimumSum = sum;
            }
        }

        //do the and
        distance += minimumSum;
    }

    return distance;
}

int PACMarker::decodeMarkerMessage(const cv::Mat &message)
{
    int identifier = 0;
    for (int y = 0; y < 5; y++) {
        identifier <<= 1;
        if (message.at<uchar>(y, 1)) {
            identifier |= 1;
        }

        identifier <<= 1;
        if (message.at<uchar>(y, 3)) {
            identifier |= 1;
        }
    }

    return identifier;
}

int PACMarker::decodeMarkerWithValidation(const cv::Mat &markerImage, int &rotationCount)
{
    assert(markerImage.rows == markerImage.cols);
    assert(markerImage.type() == CV_8UC1);

    //threshold image
    cv::Mat thresholdMarkerImage(markerImage.rows, markerImage.cols, CV_8UC1);
    cv::threshold(markerImage, thresholdMarkerImage, 127, 255, cv::THRESH_BINARY | cv::THRESH_OTSU);
    
#if defined(MARKER_DEBUG)
    std::string homeDirectory = getenv("HOME");
    cv::imwrite(homeDirectory + "/Documents/markerd-candidate.jpg", markerImage);
#endif

    //Markers  are divided in 7x7 regions, of which the inner 5x5 belongs to marker info
    //the external border should be entirely black
    int cellSize = thresholdMarkerImage.rows / 7;
    for (int y = 0; y < 7; y++) {
        int inc = 6;
        if (y == 0 || y == 6) {
            inc = 1; //for first and last row, check the whole border
        }

        for (int x = 0; x < 7; x += inc) {
            int cellX = x * cellSize;
            int cellY = y * cellSize;
            cv::Mat cell = thresholdMarkerImage(cv::Rect(cellX, cellY, cellSize, cellSize));

            int nonzeroCount = cv::countNonZero(cell);

            if (nonzeroCount > (cellSize * cellSize) / 2) {
                return -1;//can not be a marker because the border element is not black!
            }
        }
    }

    cv::Mat bitMatrix = cv::Mat::zeros(5, 5, CV_8UC1);

    //get information(for each inner square, determine if it is  black or white)
    for (int y = 0; y < 5; y++) {
        for (int x = 0; x < 5; x++) {
            int cellX = (x + 1) * cellSize;
            int cellY = (y + 1) * cellSize;
            cv::Mat cell = thresholdMarkerImage(cv::Rect(cellX, cellY, cellSize, cellSize));

            int nonzeroCount = cv::countNonZero(cell);
            if (nonzeroCount > (cellSize * cellSize) / 2)
                bitMatrix.at<uchar>(y, x) = 1;
        }
    }

    //check all possible rotations
    cv::Mat rotations[4];
    int distances[4];

    rotations[0] = bitMatrix;
    distances[0] = hammingDistance(rotations[0]);

    std::pair<int, int> minimumDistance(distances[0], 0);

    for (int i = 1; i < 4; i++) {
        //get the hamming distance to the nearest possible word
        rotations[i] = rotate(rotations[i - 1]);
        distances[i] = hammingDistance(rotations[i]);
        
        if (distances[i] < minimumDistance.first) {
            minimumDistance.first  = distances[i];
            minimumDistance.second = i;
        }
    }
    
    rotationCount = minimumDistance.second;
    if (minimumDistance.first == 0) {
        return decodeMarkerMessage(rotations[minimumDistance.second]);
    }
    
    return -1;
}
