//
//  DUELLAppDelegate.h
//
//  Created by Andreas Hanft on 06/01/15.
//  Copyright (c) 2015 GameDuell GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DUELLDelegate;


@interface DUELLAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, readwrite, strong) UIWindow *window;

- (void)addDuellDelegate:(id<DUELLDelegate>)delegate; // Keeps a strong refernce
- (void)removeDuellDelegate:(id<DUELLDelegate>)delegate;

@end

