//
//  NTNUFramemarker.mm
//  SmartScan
//
//  Created by Cameron Palmer on 20.02.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import "NTNUFramemarker.h"

#import "Framemarker.h"



namespace ntnu
{
    struct FramemarkerImpl
    {
    };

    Framemarker::Framemarker() :
    impl(new FramemarkerImpl),
    markerIdentifier(-1),
    centerOrigin(false),
    enabled(false),
    size(7.0f)
    {
    }

    Framemarker::Framemarker(Framemarker &framemarker)
    : impl(new FramemarkerImpl),
    markerIdentifier(framemarker.markerIdentifier),
    descriptiveText(framemarker.descriptiveText),
    reference(framemarker.reference),
    centerOrigin(framemarker.centerOrigin),
    enabled(framemarker.enabled),
    size(framemarker.size),
    cvPose(framemarker.cvPose),
    corners3D(framemarker.corners3D)
    {
    }

    Framemarker::~Framemarker()
    {
        delete impl;
    }
}



@interface NTNUFramemarker ()
@property (unsafe_unretained, nonatomic) std::shared_ptr<ntnu::Framemarker> framemarker;
@property (assign, nonatomic, readwrite) NSInteger markerIdentifier;
@property (strong, nonatomic, readwrite) NSString *descriptiveText;
@property (strong, nonatomic, readwrite) NSString *reference;
@property (assign, nonatomic, readwrite) BOOL centerOrigin;
@property (assign, nonatomic, readwrite, getter=isEnabled) BOOL enabled;
@property (assign, nonatomic, readwrite) CGFloat size;

@end



@implementation NTNUFramemarker

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.framemarker = std::make_shared<ntnu::Framemarker>();
    }

    return self;
}

- (instancetype)initWithFramemarker:(void *)framemarker
{
    self = [super init];
    if (self) {
        ntnu::Framemarker *otherMarker = static_cast<ntnu::Framemarker *>(framemarker);
        self.framemarker = std::shared_ptr<ntnu::Framemarker>(new ntnu::Framemarker(*otherMarker));
    }

    return self;
}

- (void *)impl
{
    return static_cast<void *>(self.framemarker.get());
}



#pragma mark - C++ object Getters and Setters

- (void)setMarkerIdentifier:(NSInteger)markerIdentifier
{
    self.framemarker->markerIdentifier = markerIdentifier;
}

- (NSInteger)markerIdentifier
{
    return self.framemarker->markerIdentifier;
}

- (void)setDescriptiveText:(NSString *)descriptiveText
{
    self.framemarker->descriptiveText = std::string([descriptiveText UTF8String]);
}

- (NSString *)descriptiveText
{
    return [NSString stringWithUTF8String:self.framemarker->descriptiveText.c_str()];
}

- (void)setReference:(NSString *)reference
{
    self.framemarker->reference = std::string([reference UTF8String]);
}

- (NSString *)reference
{
    return [NSString stringWithUTF8String:self.framemarker->reference.c_str()];
}

- (void)setCenterOrigin:(BOOL)centerOrigin
{
    self.framemarker->centerOrigin = centerOrigin;
}

- (BOOL)centerOrigin
{
    return self.framemarker->centerOrigin;
}

- (void)setEnabled:(BOOL)enabled
{
    self.framemarker->enabled = enabled;
}

- (BOOL)isEnabled
{
    return self.framemarker->enabled;
}

- (void)setSize:(CGFloat)size
{
    self.framemarker->size = size;
}

- (CGFloat)size
{
    return self.framemarker->size;
}

@end
