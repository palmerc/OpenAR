//
//  NTNUVideoFrame.h
//  SmartScan
//
//  Created by Cameron Palmer on 11.01.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>



@interface NTNUVideoFrame : NSObject

@property (assign, nonatomic) size_t width;
@property (assign, nonatomic) size_t height;
@property (assign, nonatomic) size_t bytesPerRow;
@property (assign, nonatomic) OSType pixelFormat;

@property (strong, nonatomic) NSData *rawPixelData;

@end
