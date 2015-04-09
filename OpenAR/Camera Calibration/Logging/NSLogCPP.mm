//
//  NSLogCPP.m
//  OpenAR
//
//  Created by Cameron Palmer on 27.03.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#import "NSLogCPP.h"

#import <Foundation/Foundation.h>



void NSLogCPP(const char *format, ...)
{
    va_list(arguments);
    va_start(arguments, format);
    NSString *formatString = [[NSString alloc] initWithCString:format encoding:NSUTF8StringEncoding];
    NSString *message = [[NSString alloc] initWithFormat:formatString arguments:arguments];
    va_end(arguments);
    NSLog(@"%@", message);
}