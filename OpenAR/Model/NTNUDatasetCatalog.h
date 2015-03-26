//
//  NTNUDatasetCatalog.h
//  SmartScan
//
//  Created by Cameron Palmer on 13.11.14.
//  Copyright (c) 2014 NTNU. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface NTNUDatasetCatalog : NSObject

@property (assign, nonatomic, readonly) NSInteger version;
@property (strong, nonatomic, readonly) NSArray *filenames;

+ (NSURL *)libraryDatasetURL;
+ (NSURL *)libraryShadersURL;

@end
