//
//  NTNUFramemarker.h
//  SmartScan
//
//  Created by Cameron Palmer on 20.02.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreGraphics/CoreGraphics.h>



@interface NTNUFramemarker : NSObject
@property (unsafe_unretained, nonatomic, readonly) void *impl;
@property (assign, nonatomic, readonly) NSInteger markerIdentifier;
@property (strong, nonatomic, readonly) NSString *descriptiveText;
@property (strong, nonatomic, readonly) NSString *reference;
@property (assign, nonatomic, readonly) BOOL centerOrigin;
@property (assign, nonatomic, readonly, getter=isEnabled) BOOL enabled;
@property (assign, nonatomic, readonly) CGFloat size;

- (instancetype)initWithFramemarker:(void *)framemarker;

@end
