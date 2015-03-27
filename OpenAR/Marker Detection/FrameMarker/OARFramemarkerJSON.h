//
//  OARFramemarkerJSON.h
//  OpenAR
//
//  Created by Cameron Palmer on 20.02.15.
//  Copyright (c) 2015 NTNU. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OARFramemarker.h"



@interface OARFramemarkerJSON : OARFramemarker

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
