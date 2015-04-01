//
//  DUELLDelegate.h
//
//  Created by Andreas Hanft on 07/01/15.
//  Copyright (c) 2015 GameDuell GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol DUELLDelegate <NSObject>

@optional
  - (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
  - (void)applicationWillResignActive:(UIApplication *)application;
  - (void)applicationDidEnterBackground:(UIApplication *)application;
  - (void)applicationWillEnterForeground:(UIApplication *)application;
  - (void)applicationDidBecomeActive:(UIApplication *)application;
  - (void)applicationWillTerminate:(UIApplication *)application;
  - (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary *)userInfo;
  - (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

@end