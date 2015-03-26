//
//  NTNUDatasetCatalogJSON.h
//  SmartScan
//
//  Created by Cameron Palmer on 13.11.14.
//  Copyright (c) 2014 NTNU. All rights reserved.
//

#import "NTNUDatasetCatalog.h"

extern NSString *const kDatasetCatalogFilename;
extern NSString *const kShadersCatalogFilename;



@interface NTNUDatasetCatalogJSON : NTNUDatasetCatalog

+ (instancetype)datasetFromCatalog:(NSString *)catalogName inBundle:(NSBundle *)bundleOrNil;
+ (instancetype)datasetFromCatalogAtURL:(NSURL *)catalogURL;
+ (instancetype)datasetCatalogWithDictionary:(NSDictionary *)dictionary;

@end
