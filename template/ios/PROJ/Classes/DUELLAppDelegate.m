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

    for (int i = 0; i < [self.duellDelegates count]; ++i)
    {
        if ([self.duellDelegates[i] respondsToSelector:@selector(application:didFinishLaunchingWithOptions:)])
        {
            [self.duellDelegates[i] application:application didFinishLaunchingWithOptions:launchOptions];
        }
    }

    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
    {
        UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
    else
    {
        // iOS < 8 Notifications
        [application registerForRemoteNotificationTypes:
        (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert)];
    }

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    for (int i = 0; i < [self.duellDelegates count]; ++i)
    {
        if ([self.duellDelegates[i] respondsToSelector:@selector(applicationWillResignActive:)])
        {
            [self.duellDelegates[i] applicationWillResignActive:application];
        }
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    for (int i = 0; i < [self.duellDelegates count]; ++i)
    {
        if ([self.duellDelegates[i] respondsToSelector:@selector(applicationDidEnterBackground:)])
        {
            [self.duellDelegates[i] applicationDidEnterBackground:application];
        }
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    for (int i = 0; i < [self.duellDelegates count]; ++i)
    {
        if ([self.duellDelegates[i] respondsToSelector:@selector(applicationWillEnterForeground:)])
        {
            [self.duellDelegates[i] applicationWillEnterForeground:application];
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    for (int i = 0; i < [self.duellDelegates count]; ++i)
    {
        if ([self.duellDelegates[i] respondsToSelector:@selector(applicationDidBecomeActive:)])
        {
            [self.duellDelegates[i] applicationDidBecomeActive:application];
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    for (int i = 0; i < [self.duellDelegates count]; ++i)
    {
        if ([self.duellDelegates[i] respondsToSelector:@selector(applicationWillTerminate:)])
        {
            [self.duellDelegates[i] applicationWillTerminate:application];
        }
    }
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    for (int i = 0; i < [self.duellDelegates count]; ++i)
    {
        if ([self.duellDelegates[i] respondsToSelector:@selector(application:didReceiveRemoteNotification:)])
        {
            [self.duellDelegates[i] application:application didReceiveRemoteNotification:userInfo];
        }
    }
}

- (void)application:(UIApplication*)application didReceiveLocalNotification:(UILocalNotification*)notification
{
    for (int i = 0; i < [self.duellDelegates count]; ++i)
    {
        if ([self.duellDelegates[i] respondsToSelector:@selector(application:didReceiveLocalNotification:)])
        {
            [self.duellDelegates[i] application:application didReceiveLocalNotification:notification];
        }
    }

	[UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    for (int i = 0; i < [self.duellDelegates count]; ++i)
    {
        if ([self.duellDelegates[i] respondsToSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)])
        {
            [self.duellDelegates[i] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
        }
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    BOOL returnValue = NO;

    for (int i = 0; i < [self.duellDelegates count]; ++i)
    {
        if ([self.duellDelegates[i] respondsToSelector:@selector(application:openURL:sourceApplication:annotation:)])
        {
            returnValue |= [self.duellDelegates[i] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
        }
    }

    return returnValue;
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    for (int i = 0; i < [self.duellDelegates count]; ++i)
    {
        if ([self.duellDelegates[i] respondsToSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)])
        {
            [self.duellDelegates[i] application:application didFailToRegisterForRemoteNotificationsWithError:error];
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
