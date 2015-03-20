//
//  UIImage+Checkerboard.m
//  OAR
//
//  Created by Cameron Palmer on 16.11.14.
//  Copyright (c) 2014 NTNU. All rights reserved.
//

#import "UIImage+Checkerboard.h"



@implementation UIImage (Checkerboard)

+ (UIImage *)ntnu_checkerboardWithRect:(CGRect)frame
{
    UIGraphicsBeginImageContextWithOptions(frame.size, YES, [UIScreen mainScreen].scale);
    UIImage *checkerboardPattern = [[self class] ntnu_checkboardPattern];
    [[UIColor colorWithPatternImage:checkerboardPattern] setFill];
    UIRectFill(frame);

    UIImage *checkerboardImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return checkerboardImage;
}

+ (UIImage *)ntnu_checkboardPattern
{
    CGFloat lengthOfEdge = 32.0f;
    CGSize sizeOfSquare = CGSizeMake(lengthOfEdge, lengthOfEdge);
    UIGraphicsBeginImageContextWithOptions(sizeOfSquare, NO, [UIScreen mainScreen].scale);

    [[UIColor whiteColor] setFill];
    CGRect whiteSquare = CGRectZero;
    whiteSquare.size = sizeOfSquare;
    UIRectFill(whiteSquare);

    CGRect blackSquare = CGRectMake(0.0f, 0.0f, lengthOfEdge * 0.5f, lengthOfEdge * 0.5f);
    [[UIColor colorWithWhite:0.8f alpha:1] setFill];
    UIRectFill(blackSquare);
    blackSquare.origin = CGPointMake(lengthOfEdge * 0.5f, lengthOfEdge * 0.5f);
    UIRectFill(blackSquare);

    UIImage *checkerboardPattern = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return checkerboardPattern;
}

@end
