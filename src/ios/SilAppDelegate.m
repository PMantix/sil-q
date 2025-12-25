/**
 * \file ios/SilAppDelegate.m
 * \brief iOS Application Delegate for Sil-Q
 *
 * Copyright (c) 2024 Sil-Q Contributors
 *
 * This work is free software; you can redistribute it and/or modify it
 * under the terms of either:
 *
 * a) the GNU General Public License as published by the Free Software
 *    Foundation, version 2, or
 *
 * b) the "Angband licence":
 *    This software may be copied and distributed for educational, research,
 *    and not for profit purposes provided that this copyright and statement
 *    are included in all such copies.  Other copyrights may also apply.
 */

#import "SilAppDelegate.h"
#import "SilViewController.h"

// Forward declaration for the game run function
extern void ios_run_game(void);

@implementation SilAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    SilViewController *viewController = [[SilViewController alloc] init];
    self.window.rootViewController = viewController;
    
    [self.window makeKeyAndVisible];
    
    // Start the game after a short delay to let the UI finish setting up
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), 
                   dispatch_get_main_queue(), ^{
        ios_run_game();
    });
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the app is about to move from active to inactive state.
    // Pause game, save state if needed.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SilGameWillBackground" object:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Save game state when entering background.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SilGameDidBackground" object:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of transition from background to active state.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SilGameDidBecomeActive" object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Save game before termination.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SilGameWillTerminate" object:nil];
}

@end
