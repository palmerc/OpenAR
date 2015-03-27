//
//  NTNUMarkerDetectorBridge.m
//  SmartScan
//
//  Created by Cameron Palmer on 09.01.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import "NTNUMarkerDetectorBridge.h"

#import <stdlib.h>
#import <memory.h>
#import <opencv2/core/core.hpp>
#import <Accelerate/Accelerate.h>

#import "OARAppDelegate.h"
#import "NTNUCameraCalibration.h"
#import "OARFramemarker.h"
#import "OARLogger.h"
#import "PACMarkerDetectionFacade.h"
#import "OARBasicVideoFrame.h"

static NSString *const kOpenCVDispatchQueueName = @"no.ntnu.smartscan.OpenCV";



@interface NTNUMarkerDetectorBridge () {
    std::unique_ptr<PACMarkerDetectionFacade> _markerDetectorFacade;
}

@property (strong, nonatomic) NSPointerArray *observers;
@property (strong, nonatomic) dispatch_queue_t openCVDispatchQueue;

@property (assign, nonatomic) CGSize histogramSize;

@property (strong, nonatomic, getter=isProcessingFrame) NSNumber *processingFrame;

@end



@implementation NTNUMarkerDetectorBridge

- (instancetype)init
{
    self = [super init];
    if (self) {
        _observers = [NSPointerArray weakObjectsPointerArray];
        _openCVDispatchQueue = dispatch_queue_create([kOpenCVDispatchQueueName UTF8String], DISPATCH_QUEUE_SERIAL);
    }

    return self;
}

- (void)setCameraCalibration:(NTNUCameraCalibration *)cameraCalibration
{
    float focalLength = cameraCalibration.focalLength;
    float width = cameraCalibration.currentResolution.width;
    float height = cameraCalibration.currentResolution.height;
    float focalLengthPixelsWidth = cameraCalibration.focalLengthPixels.width;
    float focalLengthPixelsHeight = cameraCalibration.focalLengthPixels.height;
    float principalPointX = cameraCalibration.principalPoint.x;
    float principalPointY = cameraCalibration.principalPoint.y;
    auto calibration = std::make_shared<PACCameraCalibration>(focalLength, width, height, focalLengthPixelsWidth, focalLengthPixelsHeight, principalPointX, principalPointY);

    _markerDetectorFacade.release();
    _markerDetectorFacade = markerDetectorWithCalibration(calibration);
    _markerDetectorFacade->setDocumentDirectory([[[OARAppDelegate applicationDocumentURL] path] UTF8String]);
}

- (void)setFramemarkers:(NSArray *)framemarkers
{
    std::vector<std::shared_ptr<ntnu::Framemarker>> markers;
    for (OARFramemarker *framemarker in framemarkers) {
        ntnu::Framemarker *oldMarker = static_cast<ntnu::Framemarker *>(framemarker.impl);
        std::shared_ptr<ntnu::Framemarker> marker(new ntnu::Framemarker(*oldMarker));
        markers.push_back(marker);
    }

    _markerDetectorFacade->setFramemarkers(markers);
}



#pragma mark - Observer handling methods

- (void)addObserver:(id <NTNUMarkerDetectorDelegate>)observer
{
    if (observer == nil) {
        return;
    }

    DDLogVerbose(@"%s - %@", __PRETTY_FUNCTION__, observer);

    @synchronized(self.observers) {
        for (id object in self.observers) {
            if (object == observer) {
                return;
            }
        }
        
        [self.observers addPointer:(__bridge void *)(observer)];
    }
}

- (void)removeObserver:(id <NTNUMarkerDetectorDelegate>)observer
{
    if (observer == nil) {
        return;
    }

    DDLogVerbose(@"%s - %@", __PRETTY_FUNCTION__, observer);

    @synchronized(self.observers) {
        NSInteger deletionIndex = -1;
        for (int i = 0; i < [[self.observers allObjects] count]; i++) {
            id candidate = (id)[self.observers pointerAtIndex:i];
            if (candidate == observer) {
                deletionIndex = i;
            }
        }

        if (deletionIndex >= 0) {
            [self.observers removePointerAtIndex:deletionIndex];
        }
    }
}



#pragma mark - PACVideoSourceDelegate methods

- (void)didUpdateGrayscaleVideoFrame:(OARBasicVideoFrame)grayscaleVideoFrame
{
    @synchronized (self.processingFrame) {
        if ([self.isProcessingFrame boolValue]) {
            return;
        }

        self.processingFrame = @YES;
    }

    void *grayscaleData = malloc(grayscaleVideoFrame.totalBytes);
    memcpy(grayscaleData, grayscaleVideoFrame.baseAddress, grayscaleVideoFrame.totalBytes);

    __block OARBasicVideoFrame videoFrame = {
        .width = grayscaleVideoFrame.width,
        .height = grayscaleVideoFrame.height,
        .bytesPerRow = grayscaleVideoFrame.bytesPerRow,
        .totalBytes = grayscaleVideoFrame.totalBytes,
        .baseAddress = grayscaleData
    };
    dispatch_async(self.openCVDispatchQueue, ^{
        cv::Mat cvMatVideoFrame = [self cvMatFromVideoFrame:videoFrame];

        [self processVideo:cvMatVideoFrame];
        free(videoFrame.baseAddress);
        @synchronized (self.processingFrame) {
            self.processingFrame = @NO;
        }
    });
}

- (void)processVideo:(cv::Mat)cvMatVideoFrame
{
    if (_markerDetectorFacade == nullptr) {
        return;
    }

    cv::Mat equalizedImage(cvMatVideoFrame.size(), CV_8UC1);
    equalizeHistogram(cvMatVideoFrame, equalizedImage);
    _markerDetectorFacade->processVideoFrame(equalizedImage);

    const std::vector<std::shared_ptr<ntnu::Framemarker>> markers = _markerDetectorFacade->updatedMarkers();
    if (markers.size() > 0) {
        NSMutableArray *mutableFrameMarkers = [[NSMutableArray alloc] initWithCapacity:markers.size()];
        for (auto marker : markers) {
            OARFramemarker *framemarker = [[OARFramemarker alloc] initWithFramemarker:marker.get()];
            [mutableFrameMarkers addObject:framemarker];
        }

        @synchronized (self.observers) {
            for (id <NTNUMarkerDetectorDelegate> observer in self.observers) {
                if ([observer respondsToSelector:@selector(didUpdateFramemarkerPositions:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [observer didUpdateFramemarkerPositions:[mutableFrameMarkers copy]];
                    });
                }
            }
        }
    }
}

- (cv::Mat)cvMatFromVideoFrame:(const OARBasicVideoFrame &)videoFrame
{
    cv::Mat cvMat(cv::Size((int)videoFrame.width, (int)videoFrame.height),
                  CV_8UC1,
                  videoFrame.baseAddress);
    return cvMat;
}

void equalizeHistogram(const cv::Mat &planar8Image, cv::Mat &equalizedImage)
{
    cv::Size size = planar8Image.size();
    vImagePixelCount width = static_cast<vImagePixelCount>(size.width);
    vImagePixelCount height = static_cast<vImagePixelCount>(size.height);
    CGSize imageSize = CGSizeMake(width, height);

    static vImage_Buffer planarImageBuffer;
    static vImage_Buffer equalizedImageBuffer;
    static CGSize histogramSize = CGSizeZero;
    if (!CGSizeEqualToSize(imageSize, histogramSize)) {
        histogramSize = imageSize;

        planarImageBuffer = {
            .width = width,
            .height = height
        };

        equalizedImageBuffer = {
            .width = width,
            .height = height
        };
    }

    planarImageBuffer.rowBytes = planar8Image.step;
    planarImageBuffer.data = planar8Image.data;

    equalizedImageBuffer.rowBytes = equalizedImage.step;
    equalizedImageBuffer.data = equalizedImage.data;

    TIMER_START(VIMAGE_EQUALIZE_HISTOGRAM);
    vImage_Error error = vImageEqualization_Planar8(&planarImageBuffer, &equalizedImageBuffer, kvImageNoFlags);
    TIMER_END(VIMAGE_EQUALIZE_HISTOGRAM);
    if (error != kvImageNoError) {
        NSLog(@"%s, vImage error %zd", __PRETTY_FUNCTION__, error);
    }
}

@end
