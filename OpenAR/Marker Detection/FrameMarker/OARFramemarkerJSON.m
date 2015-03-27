//
//  OARFramemarkerJSON.m
//  SmartScan
//
//  Created by Cameron Palmer on 20.02.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import "OARFramemarkerJSON.h"

#import "OARLogger.h"



@interface OARFramemarker ()
@property (assign, nonatomic, readwrite) NSInteger markerIdentifier;
@property (strong, nonatomic, readwrite) NSString *descriptiveText;
@property (strong, nonatomic, readwrite) NSString *reference;
@property (assign, nonatomic, readwrite) BOOL centerOrigin;
@property (assign, nonatomic, readwrite, getter=isEnabled) BOOL enabled;
@property (assign, nonatomic, readwrite) CGFloat size;

@end



@implementation OARFramemarkerJSON

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        [self updateWithDictionary:dictionary];
    }

    return self;
}

- (void)updateWithDictionary:(NSDictionary *)dictionary
{
    for (NSString *key in [dictionary keyEnumerator]) {
        id JSONValue = [dictionary objectForKey:key];

        SEL selector = [[self.dispatchTable valueForKey:key] pointerValue];
        if (selector != NULL && [self respondsToSelector:selector]) {
            IMP imp = [self methodForSelector:selector];
            void (*method)(id, SEL, id) = (void *)imp;
            method(self, selector, JSONValue);
        } else {
            DDLogInfo(@"No selector found for pair - %@: %@", key, JSONValue);
        }
    }
}

- (NSDictionary *)dispatchTable
{
    return @{
             @"center_origin": [NSValue valueWithPointer:@selector(setCenterOriginWithNumber:)],
             @"description": [NSValue valueWithPointer:@selector(setDescriptionWithString:)],
             @"enabled": [NSValue valueWithPointer:@selector(setEnabledWithNumber:)],
             @"identifier": [NSValue valueWithPointer:@selector(setIdentifierWithNumber:)],
             @"reference": [NSValue valueWithPointer:@selector(setReferenceWithString:)],
             @"size": [NSValue valueWithPointer:@selector(setWithSizeWithNumber:)]
             };
}

- (void)setCenterOriginWithNumber:(id)sender
{
    if ([sender isKindOfClass:[NSNumber class]]) {
        NSNumber *centerOrigin = sender;
        self.centerOrigin = [centerOrigin boolValue];
    }
}

- (void)setDescriptionWithString:(id)sender
{
    if ([sender isKindOfClass:[NSString class]]) {
        self.descriptiveText = sender;
    }
}

- (void)setEnabledWithNumber:(id)sender
{
    if ([sender isKindOfClass:[NSNumber class]]) {
        NSNumber *enabled = sender;
        self.enabled = [enabled boolValue];
    }
}

- (void)setIdentifierWithNumber:(id)sender
{
    if ([sender isKindOfClass:[NSNumber class]]) {
        NSNumber *identifier = sender;
        self.markerIdentifier = [identifier integerValue];
    }
}

- (void)setReferenceWithString:(id)sender
{
    if ([sender isKindOfClass:[NSString class]]) {
        self.reference = sender;
    }
}

- (void)setWithSizeWithNumber:(id)sender
{
    if ([sender isKindOfClass:[NSNumber class]]) {
        NSNumber *size = sender;
        self.size = [size floatValue];
    }
}

@end
