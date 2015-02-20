//
//  AppDelegate.m
//
//  Created by Andreas Hanft on 06/01/15.
//  Copyright (c) 2015 GameDuell GmbH. All rights reserved.
//

#import "DUELLAppDelegate.h"

#import "DUELLDelegate.h"


const char *hxRunLibrary();


@interface DUELLAppDelegate ()

@property (nonatomic, readwrite, strong) NSMutableArray *duellDelegates;

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

    for (id<DUELLDelegate> delegate in self.duellDelegates)
    {
        if ([delegate respondsToSelector:@selector(application:didFinishLaunchingWithOptions:)])
        {
            [delegate application:application didFinishLaunchingWithOptions:launchOptions];
        }
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    for (id<DUELLDelegate> delegate in self.duellDelegates)
    {
        if ([delegate respondsToSelector:@selector(applicationWillResignActive:)])
        {
            [delegate applicationWillResignActive:application];
        }
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    for (id<DUELLDelegate> delegate in self.duellDelegates)
    {
        if ([delegate respondsToSelector:@selector(applicationDidEnterBackground:)])
        {
            [delegate applicationDidEnterBackground:application];
        }
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    for (id<DUELLDelegate> delegate in self.duellDelegates)
    {
        if ([delegate respondsToSelector:@selector(applicationWillEnterForeground:)])
        {
            [delegate applicationWillEnterForeground:application];
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    for (id<DUELLDelegate> delegate in self.duellDelegates)
    {
        if ([delegate respondsToSelector:@selector(applicationDidBecomeActive:)])
        {
            [delegate applicationDidBecomeActive:application];
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    for (id<DUELLDelegate> delegate in self.duellDelegates)
    {
        if ([delegate respondsToSelector:@selector(applicationWillTerminate:)])
        {
            [delegate applicationWillTerminate:application];
        }
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    BOOL returnValue = NO;

    for (id<DUELLDelegate> delegate in self.duellDelegates)
    {
        if ([delegate respondsToSelector:@selector(application:openURL:sourceApplication:annotation:)])
        {
            returnValue |= [delegate application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
        }
    }

    return returnValue;
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    for (id<DUELLDelegate> delegate in self.duellDelegates)
    {
        if ([delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:)])
        {
            [delegate application:application didReceiveRemoteNotification:userInfo];
        }
    }
}

- (void)addDuellDelegate:(id<DUELLDelegate>)delegate
{
    if (self.duellDelegates == nil)
    {
        self.duellDelegates = [[NSMutableArray alloc] init];
    }

    if ([self.duellDelegates containsObject:delegate] == NO)
    {
        [self.duellDelegates addObject:delegate];
    }
}

- (void)removeDuellDelegate:(id<DUELLDelegate>)delegate
{
    [self.duellDelegates removeObject:delegate];
}

@end
