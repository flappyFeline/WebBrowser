//
//  AppDelegate.m
//  WebBrowser
//
//  Created by 钟武 on 16/7/29.
//  Copyright © 2016年 钟武. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "AppDelegate.h"
#import "KeyboardHelper.h"
#import "MenuHelper.h"
#import "BrowserViewController.h"
#import "WebServer.h"
#import "ErrorPageHelper.h"
#import "SessionRestoreHelper.h"
#import "TabManager.h"

static NSString * const UserAgent = @"Mozilla/5.0 (iPhone; CPU iPhone OS 10_0 like Mac OS X) AppleWebKit/602.1.38 (KHTML, like Gecko) Version/10.0 Mobile/14A300 Safari/602.1";

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)setAudioPlayInBackgroundMode{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    NSError *setCategoryError = nil;
    BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    if (!success) { /* handle the error condition */ }
    
    NSError *activationError = nil;
    success = [audioSession setActive:YES error:&activationError];
    if (!success) { /* handle the error condition */ }
}

- (void)applicationStartPrepare{
    [self setAudioPlayInBackgroundMode];
    [[KeyboardHelper sharedInstance] startObserving];
    [[MenuHelper sharedInstance] setItems];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    DDLogDebug(@"Home Path : %@", HomePath);
    
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024
                                                         diskCapacity:32 * 1024 * 1024
                                                             diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];

    BrowserViewController *browserViewController = BrowserVC;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:browserViewController];
    navigationController.restorationIdentifier = @"baseNavigationController";
    navigationController.navigationBarHidden = YES;
    navigationController.view.backgroundColor = [UIColor whiteColor];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    
    [ErrorPageHelper registerWithServer:[WebServer sharedInstance]];
    [SessionRestoreHelper registerWithServer:[WebServer sharedInstance]];
    
    [[WebServer sharedInstance] start];
    
    //解决UIWebView首次加载页面时间过长问题,设置UserAgent减少跳转和判断
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent" : UserAgent}];
    
    [TabManager sharedInstance];    //load archive data ahead
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self applicationStartPrepare];
    });
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// Enable UIWebView video landscape
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
    static NSString *kAVFullScreenViewControllerStr = @"AVFullScreenViewController";
    UIViewController *presentedViewController = [window.rootViewController presentedViewController];

    if (presentedViewController && [presentedViewController isKindOfClass:NSClassFromString(kAVFullScreenViewControllerStr)] && [presentedViewController isBeingDismissed] == NO) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Preseving and Restoring State

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder{
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder{
    return YES;
}

@end
