//
//  NTNUBasicVideoFrame.h
//  SmartScan
//
//  Created by Cameron Palmer on 12.01.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#ifndef SmartScan_NTNUBasicVideoFrame_h
#define SmartScan_NTNUBasicVideoFrame_h



typedef struct
{
    size_t width;
    size_t height;
    size_t bytesPerRow;
    size_t totalBytes;
    unsigned long pixelFormat;
    void *rawPixelData;
    
} NTNUBasicVideoFrame;

#endif
