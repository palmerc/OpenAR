//
//  OARBasicVideoFrame.h
//  OpenAR
//
//  Created by Cameron Palmer on 20.03.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#ifndef OpenAR_OARBasicVideoFrame_h
#define OpenAR_OARBasicVideoFrame_h

typedef struct
{
    size_t width;
    size_t height;
    size_t bytesPerRow;
    size_t totalBytes;
    unsigned long pixelFormat;
    void *baseAddress;

} OARBasicVideoFrame;

#endif
