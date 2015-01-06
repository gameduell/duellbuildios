//
//  DUELLAppDelegate.h
//
//  Created by Andreas Hanft on 06/01/15.
//  Copyright (c) 2015 GameDuell GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DUELLDelegate;


@interface DUELLAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic, readwrite) UIWindow *window;

- (void)addDuellDelegate:(id<DUELLDelegate>)delegate;

@end

