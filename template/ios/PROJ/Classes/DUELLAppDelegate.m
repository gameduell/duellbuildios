/*
 * Copyright (c) 2003-2015, GameDuell GmbH
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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

	UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];

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

- (void)application:(UIApplication*)application didReceiveLocalNotification:(UILocalNotification*)notification
{
    for (id<DUELLDelegate> delegate in self.duellDelegates)
    {
        if ([delegate respondsToSelector:@selector(application:didReceiveLocalNotification:)])
        {
            [delegate application:application didReceiveLocalNotification:notification];
        }
    }

	[UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    for (id<DUELLDelegate> delegate in self.duellDelegates)
    {
        if ([delegate respondsToSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)])
        {
            [delegate application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
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

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    for (id<DUELLDelegate> delegate in self.duellDelegates)
    {
        if ([delegate respondsToSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)])
        {
            [delegate application:application didFailToRegisterForRemoteNotificationsWithError:error];
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
