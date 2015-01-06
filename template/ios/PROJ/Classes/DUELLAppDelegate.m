//
//  AppDelegate.m
//
//  Created by Andreas Hanft on 06/01/15.
//  Copyright (c) 2015 GameDuell GmbH. All rights reserved.
//

#import "DUELLAppDelegate.h"


const char *hxRunLibrary();


@interface DUELLAppDelegate ()

@property (strong, nonatomic, readwrite) NSMutableArray *duellDelegates;

@end


@implementation DUELLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    const char *err = NULL;
    err = hxRunLibrary();
    if (err)
    {
        printf(" Error %s\n", err );
        return -1;
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{}

- (void)applicationDidEnterBackground:(UIApplication *)application
{}

- (void)applicationWillEnterForeground:(UIApplication *)application
{}

- (void)applicationDidBecomeActive:(UIApplication *)application
{}

- (void)applicationWillTerminate:(UIApplication *)application
{}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	return NO;
}

- (void)addDuellDelegate:(id<DUELLDelegate>)delegate
{
	// TODO: Implement me
}

@end
