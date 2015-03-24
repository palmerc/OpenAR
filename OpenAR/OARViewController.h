//
//  OARViewController.h
//  OpenAR
//
//  Created by Cameron Palmer on 20.03.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OARIntrinsicView.h"



@interface OARViewController : UIViewController
@property (weak, nonatomic) IBOutlet OARIntrinsicView *intrinsicView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraSwitchButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backgroundFillScreenButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraResolutionButtonItem;

- (IBAction)didPressCameraSwitchButton:(id)sender;
- (IBAction)didPressBackgroundFillScreenButton:(id)sender;
- (IBAction)didPressCameraResolutionButton:(id)sender;

@end

