//
//  NTNUDatasetCatalogJSON.m
//  SmartScan
//
//  Created by Cameron Palmer on 13.11.14.
//  Copyright (c) 2014 NTNU. All rights reserved.
//

#import "NTNUDatasetCatalogJSON.h"

#import "NTNUSmartScanDirectory.h"

#import "NTNULogger.h"
#import "NSBundle+URLResourceExtensions.h"

NSString *const kDatasetCatalogFilename = @"dataset_catalog.json";
NSString *const kShadersCatalogFilename = @"shaders_catalog.json";



@interface NTNUDatasetCatalog ()
@property (assign, nonatomic, readwrite) NSInteger version;
@property (strong, nonatomic, readwrite) NSArray *filenames;

@end



@implementation NTNUDatasetCatalogJSON

+ (instancetype)datasetFromCatalog:(NSString *)catalogName inBundle:(NSBundle *)bundle
{
    const char *directory;
    if ([catalogName isEqualToString:kDatasetCatalogFilename]) {
        directory = kSmartScanDatasetDirectory;
    } else if ([catalogName isEqualToString:kShadersCatalogFilename]) {
        directory = kSmartScanShadersDirectory;
    }

    NSString *datasetDirectory = [NSString stringWithCString:directory encoding:NSUTF8StringEncoding];
    NSURL *catalogURL = [NSBundle ntnu_URLForResourceWithName:catalogName inBundle:bundle subdirectory:datasetDirectory];
    return [[self class] datasetFromCatalogAtURL:catalogURL];
}

+ (instancetype)datasetFromCatalogAtURL:(NSURL *)catalogURL
{
    id datasetCatalog = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[catalogURL path]]) {
        NSData *catalogData = [NSData dataWithContentsOfURL:catalogURL];

        NSError *error = nil;
        NSDictionary *catalogDictionary = [NSJSONSerialization JSONObjectWithData:catalogData options:0 error:&error];
        if (error) {
            DDLogError(@"Failed to parse bundle dataset catalog. - %@", error);
        }

        datasetCatalog = [[self class] datasetCatalogWithDictionary:catalogDictionary];
    }

    return datasetCatalog;
}

+ (instancetype)datasetCatalogWithDictionary:(NSDictionary *)dictionary
{
    return [[[self class] alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        [self initializeWithDictionary:dictionary];
    }

    return self;
}



- (void)initializeWithDictionary:(NSDictionary *)dictionary
{
    for (NSString *key in [dictionary keyEnumerator]) {
        id JSONValue = [dictionary objectForKey:key];

        SEL selector = [[self.dispatchTable valueForKey:key] pointerValue];
        if (selector != NULL && [self respondsToSelector:selector]) {
            IMP imp = [self methodForSelector:selector];
            void (*method)(id, SEL, id) = (void *)imp;
            method(self, selector, JSONValue);
        } else {
            DDLogError(@"No selector found for pair - %@: %@", key, JSONValue);
        }
    }
}

- (NSDictionary *)dispatchTable
{
    return @{
             @"version": [NSValue valueWithPointer:@selector(setVersionWithNumber:)],
             @"files": [NSValue valueWithPointer:@selector(setFilesWithArray:)]
             };
}



#pragma mark - Setters

- (void)setVersionWithNumber:(id)sender
{
    if ([sender isKindOfClass:[NSNumber class]]) {
        self.version = [(NSNumber *)sender integerValue];
    }
}

- (void)setFilesWithArray:(id)sender
{
    if ([sender isKindOfClass:[NSArray class]]) {
        self.filenames = (NSArray *)sender;
    }
}

@end
