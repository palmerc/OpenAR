//
//  OARViewController.m
//  OpenAR
//
//  Created by Cameron Palmer on 20.03.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#import "OARViewController.h"

#import "OARVideoSource.h"



@interface OARViewController ()
@property (strong, nonatomic) OARVideoSource *videoSource;

@end



@implementation OARViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.videoSource = [[OARVideoSource alloc] init];
    [self.videoSource startVideoSource];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
