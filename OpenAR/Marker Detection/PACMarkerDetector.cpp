//
//  PACMarkerDetector.cpp
//  SmartScan
//
//  Created by Cameron Palmer on 06.11.14.
//  Copyright (c) 2014 NTNU. All rights reserved.
//

#include <iostream>

#include <CoreVideo/CoreVideo.h>
#include <opencv2/core/core.hpp>

#include "OARBasicVideoFrame.h"
#include "PACMarkerDetector.h"
#include "PACMarker.h"
#include "PACTinyLA.h"
#include "OARLoggerCPP.h"

//#define MARKER_IMAGE_DUMP 1



struct PACMarkerDetector::PACInternal {
    PACInternal() :
    _minimumContourLength(10.f)
    {
    }

    ~PACInternal()
    {
    }



    bool findMarkers(const cv::Mat& bgraFrame,
                     std::vector<PACMarker> &detectedMarkers) const;
    void generateGrayscaleImage(const cv::Mat &bgraFrame,
                                cv::Mat &grayscaleImage) const;
    void equalizeHistogram(const cv::Mat &grayscaleImage,
                           cv::Mat &equalizedImage) const;
    void performThreshold(const cv::Mat &originalImage,
                          cv::Mat &thresholdImage) const;

    void findContours(const cv::Mat &thresholdImage,
                      std::vector<std::vector<cv::Point>> &contours,
                      int minContourPointsAllowed) const;
    void findMarkerCandidates(const std::vector<std::vector<cv::Point>> &contours,
                              std::vector<PACMarker> &detectedMarkers) const;
    void detectMarkers(const cv::Mat& grayscale,
                       std::vector<PACMarker> &detectedMarkers) const;
    void estimatePosition(std::vector<PACMarker> &detectedMarkers) const;
    std::vector<cv::Point2f> markerCornersFromSize(const cv::Size &size) const;
    void calcBlockMeanVariance(const cv::Mat& Img,
                               cv::Mat& Res,
                               float blockSide);



    // Internal variables
    float _minimumContourLength;

    std::string _documentDirectory;
    std::shared_ptr<PACCameraCalibration> _cameraCalibration;
    std::map<int, std::shared_ptr<ntnu::Framemarker>> _framemarkers;
    std::vector<std::shared_ptr<ntnu::Framemarker>> _updates;
};



std::unique_ptr<PACMarkerDetectionFacade> markerDetectorWithCalibration(std::shared_ptr<PACCameraCalibration> calibration)
{
    return std::unique_ptr<PACMarkerDetectionFacade>(new PACMarkerDetector(calibration));
}

PACMarkerDetector::PACMarkerDetector(std::shared_ptr<PACCameraCalibration> calibration)
{
    _internal = new PACInternal();

    OARLogDebug("%s", calibration->getDescription().c_str());

    this->_internal->_cameraCalibration = calibration;
}

PACMarkerDetector::~PACMarkerDetector()
{
    delete _internal;
}



#pragma mark - Public methods

void PACMarkerDetector::processVideoFrame(const cv::Mat &bgraFrame)
{
    TIME_START(VIDEOFRAME);

    std::vector<PACMarker> validMarkers;
    this->_internal->findMarkers(bgraFrame, validMarkers);

    this->_internal->_updates.clear();
    for (PACMarker validMarker : validMarkers) {
        if (this->_internal->_framemarkers.find(validMarker.identifier) != this->_internal->_framemarkers.end()) {
            std::shared_ptr<ntnu::Framemarker> framemarker = this->_internal->_framemarkers[validMarker.identifier];
            framemarker->cvPose = validMarker.transformation;
            this->_internal->_updates.push_back(framemarker);
        }
    }

    TIME_END(VIDEOFRAME);

#if defined(DEVELOPMENT)
    std::string comma = "";
    std::stringstream buffer;
    buffer << "Found markers [";
    for (PACMarker validMarker : validMarkers) {
        buffer << comma << validMarker.identifier;
        comma = ", ";
    }
    buffer << "]" << std::endl;
    OARLogVerbose("%s", buffer.str().c_str());
#endif
}

const std::vector<std::shared_ptr<ntnu::Framemarker>> &PACMarkerDetector::updatedMarkers()
{
    return this->_internal->_updates;
}

void PACMarkerDetector::setFramemarkers(std::vector<std::shared_ptr<ntnu::Framemarker>> framemarkers)
{
    std::map<int, std::shared_ptr<ntnu::Framemarker>> framemarkerLookup;
    for (std::shared_ptr<ntnu::Framemarker> framemarker : framemarkers) {
        std::vector<cv::Point3f> corners3D;

        float framemarkerSize = framemarker->size;
        bool centerOrigin = framemarker->centerOrigin;
        if (centerOrigin) {
            float halfMarkerSize = framemarkerSize / 2.f;
            corners3D.push_back(cv::Point3f(-halfMarkerSize, -halfMarkerSize, 0.f));
            corners3D.push_back(cv::Point3f(+halfMarkerSize, -halfMarkerSize, 0.f));
            corners3D.push_back(cv::Point3f(+halfMarkerSize, +halfMarkerSize, 0.f));
            corners3D.push_back(cv::Point3f(-halfMarkerSize, +halfMarkerSize, 0.f));
        } else {
            corners3D.push_back(cv::Point3f(0.f, 0.f, 0.f));
            corners3D.push_back(cv::Point3f(framemarkerSize, 0.f, 0.f));
            corners3D.push_back(cv::Point3f(framemarkerSize, framemarkerSize, 0.f));
            corners3D.push_back(cv::Point3f(0.f, framemarkerSize, 0.f));
        }

        framemarker->corners3D = corners3D;
        framemarkerLookup[framemarker->markerIdentifier] = framemarker;
    }

    this->_internal->_framemarkers = framemarkerLookup;
}

void PACMarkerDetector::setDocumentDirectory(const char *documentDirectory)
{
    this->_internal->_documentDirectory = std::string(documentDirectory);
}



#pragma mark - Marker detector logic

bool PACMarkerDetector::PACInternal::findMarkers(const cv::Mat &grayscaleImage,
                                                 std::vector<PACMarker> &detectedMarkers) const
{
    std::vector<std::vector<cv::Point>> contours;

#if defined(MARKER_IMAGE_DUMP)
    cv::Mat bgrFrame;
    cv::cvtColor(grayscaleImage, bgrFrame, CV_GRAY2BGR);
    cv::imwrite(_documentDirectory + "/markerd-original.jpg", bgrFrame);
#endif

    TIME_START(FIND_MARKERS);
    cv::Mat thresholdImage;
    performThreshold(grayscaleImage, thresholdImage);
    findContours(thresholdImage, contours, 64);
    findMarkerCandidates(contours, detectedMarkers);
    detectMarkers(grayscaleImage, detectedMarkers);

    // Calculate their poses
    estimatePosition(detectedMarkers);

    // sort by id
    std::sort(detectedMarkers.begin(), detectedMarkers.end());
    TIME_END(FIND_MARKERS);

    return false;
}

void PACMarkerDetector::PACInternal::generateGrayscaleImage(const cv::Mat &bgraFrame, cv::Mat &grayscaleImage) const
{
    TIME_START(CV_GRAYSCALE);
    cv::cvtColor(bgraFrame, grayscaleImage, CV_BGRA2GRAY, CV_8UC1);
    TIME_END(CV_GRAYSCALE);

#if defined(MARKER_DEBUG)
    cv::imwrite(_documentDirectory + "/markerd-grayscale.jpg", grayscaleImage);
#endif
}

void PACMarkerDetector::PACInternal::equalizeHistogram(const cv::Mat &grayscaleImage, cv::Mat &equalizedImage) const
{
    TIME_START(CV_EQUALIZE_HISTOGRAM);
    cv::equalizeHist(grayscaleImage, equalizedImage);
    TIME_END(CV_EQUALIZE_HISTOGRAM);

#if defined(MARKER_DEBUG)
    cv::imwrite(_documentDirectory + "/markerd-histogram.jpg", grayscaleImage);
#endif
}

void PACMarkerDetector::PACInternal::performThreshold(const cv::Mat &originalImage, cv::Mat &thresholdImage) const
{
//    int thresholdValue = 127;
    int blockSize = 7;
    int maximumBinaryValue = 255;

    TIME_START(CV_THRESHOLD);
    // The original threshold function
//    cv::threshold(originalImage, thresholdImage, thresholdValue, maximumBinaryValue, cv::THRESH_BINARY_INV);

//    cv::Mat blur(originalImage);
//    cv::medianBlur(originalImage, blur, 3);
    // Gaussian thresholding can be expensive. 51, 17
    cv::adaptiveThreshold(originalImage,
                          thresholdImage,
                          maximumBinaryValue,
                          cv::ADAPTIVE_THRESH_GAUSSIAN_C,
                          cv::THRESH_BINARY_INV,
                          blockSize,
                          7);
    TIME_END(CV_THRESHOLD);

#if defined(MARKER_IMAGE_DUMP)
    cv::imwrite(_documentDirectory + "/markerd-threshold.jpg", thresholdImage);
#endif
}

void PACMarkerDetector::PACInternal::findContours(const cv::Mat &thresholdImage,
                                  std::vector<std::vector<cv::Point>> &contours,
                                  int minContourPointsAllowed) const
{
    std::vector<std::vector<cv::Point>> allContours;
    TIME_START(CV_FIND_CONTOURS);
    cv::findContours(thresholdImage, allContours, CV_RETR_LIST, CV_CHAIN_APPROX_NONE);
    TIME_END(CV_FIND_CONTOURS);

    contours.clear();
    for (size_t i = 0; i < allContours.size(); i++) {
        int contourSize = (int)allContours[i].size();
        if (contourSize > minContourPointsAllowed) {
            contours.push_back(allContours[i]);
        }
    }

#if defined(MARKER_IMAGE_DUMP)
    cv::Mat contoursImage(thresholdImage.size(), CV_8UC1);
    contoursImage = cv::Scalar(0);
    cv::drawContours(contoursImage, contours, -1, cv::Scalar(255), 2, CV_AA);
    cv::imwrite(_documentDirectory + "/markerd-contours.jpg", contoursImage);
#endif
}

void PACMarkerDetector::PACInternal::findMarkerCandidates(const std::vector<std::vector<cv::Point>> &contours,
                                                          std::vector<PACMarker> &detectedMarkers) const
{
    TIME_START(MARKER_CANDIDATES);
    std::vector<cv::Point> approxCurve;
    std::vector<PACMarker> possibleMarkers;

    // For each contour, analyze if it is a parallel piped likely to be the marker
    for (size_t i = 0; i < contours.size(); i++) {
        // Approximate to a polygon
        double epsilon = contours[i].size() * 0.05f;
        cv::approxPolyDP(contours[i], approxCurve, epsilon, true);

        if (approxCurve.size() != 4) {
            continue;
        }

        if (!cv::isContourConvex(approxCurve)) {
            continue;
        }

        // Ensure that the distace between consecutive points is large enough
        float minimumDistance = std::numeric_limits<float>::max();
        for (int i = 0; i < 4; i++) {
            cv::Point side = approxCurve[i] - approxCurve[(i + 1) % 4];
            float squaredSideLength = side.dot(side);
            minimumDistance = std::min(minimumDistance, squaredSideLength);
        }

        // Check that distance is not very small
        if (minimumDistance > this->_minimumContourLength) {
            PACMarker marker;
            for(int i = 0; i < 4; i++) {
                marker.points.push_back(cv::Point2f(approxCurve[i].x, approxCurve[i].y));
            }

            possibleMarkers.push_back(marker);
        }
    }

    //sort the points in anti-clockwise order
    for (size_t i = 0; i < possibleMarkers.size(); i++) {
        PACMarker &marker = possibleMarkers[i];

        //trace a line between the first and second point.
        //if the third point is at the right side, then the points are anti-clockwise
        cv::Point v1 = marker.points[1] - marker.points[0];
        cv::Point v2 = marker.points[2] - marker.points[0];

        double o = (v1.x * v2.y) - (v1.y * v2.x);

        //if the third point is in the left side, then sort in anti-clockwise order
        if (o < 0.f) {
            std::swap(marker.points[1], marker.points[3]);
        }
    }

    // remove these elements whose corners are too close to each other first detect candidates
    std::vector<std::pair<int, int>> tooNearCandidates;
    for (size_t i = 0; i < possibleMarkers.size(); i++) {
        const PACMarker &m1 = possibleMarkers[i];

        //calculate the average distance of each corner to the nearest corner of the other marker candidate
        for (size_t j = i+1; j < possibleMarkers.size(); j++) {
            const PACMarker &m2 = possibleMarkers[j];

            float distanceSquared = 0;

            for(int c = 0; c < 4; c++) {
                cv::Point v = m1.points[c] - m2.points[c];
                distanceSquared += v.dot(v);
            }

            distanceSquared /= 4;

            if (distanceSquared < 100) {
                tooNearCandidates.push_back(std::pair<int, int>(i, j));
            }
        }
    }

    //mark for removal the element of the pair with smaller perimeter
    std::vector<bool> removalMask(possibleMarkers.size(), false);
    for (size_t i = 0; i < tooNearCandidates.size(); i++) {
        float p1 = perimeter(possibleMarkers[tooNearCandidates[i].first].points);
        float p2 = perimeter(possibleMarkers[tooNearCandidates[i].second].points);

        size_t removalIndex;
        if (p1 > p2) {
            removalIndex = tooNearCandidates[i].second;
        } else {
            removalIndex = tooNearCandidates[i].first;
        }

        removalMask[removalIndex] = true;
    }

    // Return candidates
    detectedMarkers.clear();
    for (size_t i = 0; i < possibleMarkers.size(); i++) {
        if (!removalMask[i]) {
            detectedMarkers.push_back(possibleMarkers[i]);
        }
    }
    TIME_END(MARKER_CANDIDATES);
}

void PACMarkerDetector::PACInternal::detectMarkers(const cv::Mat& grayscaleMarkerScene,
                                                   std::vector<PACMarker> &detectedMarkers) const
{
    TIME_START(DETECT_MARKERS);
    std::vector<PACMarker> validMarkers;
    // Identify the markers
    for (size_t i = 0; i < detectedMarkers.size(); i++) {
        PACMarker &marker = detectedMarkers[i];

        cv::RotatedRect box = cv::minAreaRect(cv::Mat(marker.points));
        box.size = cv::Size(100.f, 100.f); // Why 100 you might ask.

        // Note: I could keep the perspective roughly the size of the marker as it
        // appears in the image. However, that would mean correcting assumptions
        // made in the getMarkerId function.
        std::vector<cv::Point2f> markerCorners2d = markerCornersFromSize(box.size);

        // Find the perspective transfomation that brings current marker to rectangular form
        cv::Mat perspectiveTransform = cv::getPerspectiveTransform(marker.points, markerCorners2d);

        // Transform image to get a canonical marker image
        cv::Mat canonicalizedImage;
        int side = (int)std::max(box.size.width, box.size.height);
        cv::warpPerspective(grayscaleMarkerScene,
                            canonicalizedImage,
                            perspectiveTransform,
                            cv::Size(side, side));

        int nRotations;
        int identifier = PACMarker::decodeMarkerWithValidation(canonicalizedImage, nRotations);
        if (identifier > -1) {
#if defined(MARKER_IMAGE_DUMP)
            std::stringstream buffer;
            buffer << std::endl << perspectiveTransform << std::endl;
            SCLogDebug("Marker %d, %s", identifier, buffer.str().c_str());

            cv::imwrite(_documentDirectory + "/markerd-canonical.jpg", canonicalizedImage);
#endif

            marker.identifier = identifier;

            //sort the points so that they are always in the same order no matter the camera orientation
            std::rotate(marker.points.begin(), marker.points.begin() + 4 - nRotations, marker.points.end());

            validMarkers.push_back(marker);
        }
    }

    //refine using subpixel accuracy the corners
    if (validMarkers.size() > 0) {
        std::vector<cv::Point2f> preciseCorners(4 * validMarkers.size());

        for (size_t i = 0; i < validMarkers.size(); i++) {
            PACMarker &marker = validMarkers[i];

            for (int corner = 0; corner < 4; corner++) {
                preciseCorners[i * 4 + corner] = marker.points[corner];
            }
        }

        cv::cornerSubPix(grayscaleMarkerScene,
                         preciseCorners,
                         cvSize(5, 5),
                         cvSize(-1, -1),
                         cvTermCriteria(CV_TERMCRIT_ITER, 30, 0.1));

        //copy back
        for (size_t i = 0; i < validMarkers.size(); i++) {
            PACMarker &marker = validMarkers[i];

            for (int corner = 0; corner < 4; corner++) {
                marker.points[corner] = preciseCorners[i * 4 + corner];
            }
        }
    }

    detectedMarkers = validMarkers;

    TIME_END(DETECT_MARKERS);
}


void PACMarkerDetector::PACInternal::estimatePosition(std::vector<PACMarker> &detectedMarkers) const
{
    TIME_START(ESTIMATE_POSITION);
    cv::Mat cameraMatrix = _cameraCalibration->getIntrinsic();
    cv::Mat distortionCoefficients = _cameraCalibration->getDistortion();

    for (size_t i = 0; i < detectedMarkers.size(); i++) {
        PACMarker &detectedMarker = detectedMarkers[i];

        std::vector<cv::Point3f> markerCorners3d;
        std::map<int, std::shared_ptr<ntnu::Framemarker>> framemarkers = this->_framemarkers;
        if (framemarkers.find(detectedMarker.identifier) != framemarkers.end()) {
            auto framemarker = framemarkers[detectedMarker.identifier];
            markerCorners3d = framemarker->corners3D;
        }

        if (markerCorners3d.size() > 0) {
            cv::Mat rotationVector;
            cv::Mat_<float> translationVector;

            cv::Mat raux, taux;

            cv::solvePnP(markerCorners3d,
                         detectedMarker.points,
                         cameraMatrix,
                         distortionCoefficients,
                         raux,
                         taux);
            raux.convertTo(rotationVector, CV_32F);
            taux.convertTo(translationVector, CV_32F);

            cv::Mat_<float> rotationMatrix(3, 3);
            cv::Rodrigues(rotationVector, rotationMatrix);

            cv::Mat_<float> transposedRotationMatrix(3, 3);
            cv::transpose(rotationMatrix, transposedRotationMatrix);

            // Copy to transformation matrix
            cv::Mat_<float> transformation = cv::Mat_<float>::eye(4, 4);
            for (int row = 0; row < 3; row++) {
                for (int column = 0; column < 3; column++) {
                    transformation(row, column) = rotationMatrix(row, column);
                }

                transformation(row, 3) = -translationVector(row);
            }

            OARLogCVMat("Rotation Matrix", rotationMatrix);
            OARLogCVMat("Translation Vector", translationVector);
            OARLogCVMat("Transformation Matrix", transformation);

            detectedMarker.transformation = transformation;
        }
    }
    TIME_END(ESTIMATE_POSITION);
}

std::vector<cv::Point2f> PACMarkerDetector::PACInternal::markerCornersFromSize(const cv::Size &size) const
{
    std::vector<cv::Point2f> markerCorners2d;
    markerCorners2d.push_back(cv::Point2f(0, 0));
    markerCorners2d.push_back(cv::Point2f(size.width - 1, 0));
    markerCorners2d.push_back(cv::Point2f(size.width - 1, size.height - 1));
    markerCorners2d.push_back(cv::Point2f(0, size.height - 1));

    return markerCorners2d;
}
