//
//  OARAppDelegate.m
//  OpenAR
//
//  Created by Cameron Palmer on 20.03.15.
//  Copyright (c) 2015 OAR. All rights reserved.
//

#import "OARAppDelegate.h"

#import <CocoaLumberjack/DDFileLogger.h>
#import <CocoaLumberjack/DDASLLogger.h>
#import <CocoaLumberjack/DDTTYLogger.h>

#import "OARLogger.h"



@interface OARAppDelegate ()
@property (strong, nonatomic) DDFileLogger *fileLogger;

@end



@implementation OARAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];

    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;

    [DDLog addLogger:fileLogger];
    self.fileLogger = fileLogger;

    DDLogDebug(@"%s", __PRETTY_FUNCTION__);

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    DDLogDebug(@"%s", __PRETTY_FUNCTION__);

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    DDLogDebug(@"%s", __PRETTY_FUNCTION__);

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    DDLogDebug(@"%s", __PRETTY_FUNCTION__);

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    DDLogDebug(@"%s", __PRETTY_FUNCTION__);

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    DDLogDebug(@"%s", __PRETTY_FUNCTION__);

}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    NSUInteger deviceOrientation;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        deviceOrientation = UIInterfaceOrientationMaskLandscapeRight;
    } else {
        deviceOrientation = UIInterfaceOrientationMaskLandscapeLeft;
    }

    return deviceOrientation;
}

+ (NSURL *)applicationDocumentURL
{
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSURL *libraryURL = [NSURL fileURLWithPath:libraryPath isDirectory:YES];

    return libraryURL;
}

+ (NSURL *)applicationLibraryURL
{
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSURL *libraryURL = [NSURL fileURLWithPath:libraryPath isDirectory:YES];
    
    return libraryURL;
}

@end
