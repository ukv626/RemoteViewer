//
//  DirectoryList.h
//  PhotoBrowser
//
//  Created by ukv on 5/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LoadingDelegate.h"
#import "KTPhotoBrowserDataSource.h"

@class BaseDriver;

@interface DirectoryList : UITableViewController <LoadingDelegate, KTPhotoBrowserDataSource,
UISearchBarDelegate, UIActionSheetDelegate, UIDocumentInteractionControllerDelegate,UIAlertViewDelegate> {
    NSMutableArray *_photos;
}

// Init
- (id)initWithDriver:(BaseDriver *)driver;

//
- (void)driver:(BaseDriver *)driver loadingDidEndNotification:(NSString *)filename;
- (void)handleLoadingProgressNotification:(id)sender;
- (void)handleAbortedNotification:(id)sender;
- (void)handleErrorNotification:(id)sender;
//- (void)handleLoadingDidEndNotification:(id)sender;
@end
