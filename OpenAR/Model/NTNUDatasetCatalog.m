//
//  NTNUDatasetCatalog.m
//  SmartScan
//
//  Created by Cameron Palmer on 13.11.14.
//  Copyright (c) 2014 NTNU. All rights reserved.
//

#import "NTNUDatasetCatalog.h"

#import "NTNUAppDelegate.h"
#import "NTNUSmartScanDirectory.h"



@interface NTNUDatasetCatalog ()
@property (assign, nonatomic, readwrite) NSInteger version;
@property (strong, nonatomic, readwrite) NSArray *filenames;

@end



@implementation NTNUDatasetCatalog

+ (NSURL *)libraryDatasetURL
{
    NSString *directory = [NSString stringWithCString:kSmartScanDatasetDirectory encoding:NSUTF8StringEncoding];
    NSURL *applicationLibraryURL = [NTNUAppDelegate applicationLibraryURL];
    return [applicationLibraryURL URLByAppendingPathComponent:directory];
}

+ (NSURL *)libraryShadersURL
{
    NSString *directory = [NSString stringWithCString:kSmartScanShadersDirectory encoding:NSUTF8StringEncoding];
    NSURL *applicationLibraryURL = [NTNUAppDelegate applicationLibraryURL];
    return [applicationLibraryURL URLByAppendingPathComponent:directory];
}

@end
