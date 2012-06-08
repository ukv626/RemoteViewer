//
//  LoadingDelegate.h
//  PhotoBrowser
//
//  Created by ukv on 5/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BaseDriver;
@protocol LoadingDelegate <NSObject>

@optional
- (void)driver:(BaseDriver *)driver loadingDidEndNotification:(NSString *)filename;
- (void)handleErrorNotification:(id)sender;
- (void)handleLoadingProgressNotification:(id)sender;
- (void)handleAbortedNotification:(id)sender;
@end
