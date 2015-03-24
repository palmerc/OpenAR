//
//  OARIntrinsicView.m
//  OpenAR
//
//  Created by Cameron Palmer on 20.03.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#import "OARIntrinsicView.h"



@implementation OARIntrinsicView

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentSize = CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric);
}

- (void)setContentSize:(CGSize)contentSize
{
    _contentSize = contentSize;

    [self invalidateIntrinsicContentSize];
}

- (CGSize)intrinsicContentSize
{
    return self.contentSize;
}

@end
