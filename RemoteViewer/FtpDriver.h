//
//  FtpDriver.h
//  PhotoBrowser
//
//  Created by ukv on 6/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BaseDriver.h"

@interface FtpDriver : BaseDriver

- (id)initWithURL:(NSURL *)url;
- (id)clone;

- (BOOL)isDownloadable;

- (BOOL)connect;
- (void)directoryList;
- (void)downloadFile:(NSString *)filename;
- (void)downloadFileAsync:(NSString *)filename;

- (NSNumber *)directorySize;

- (void)downloadDirectory;

- (NSNumber *)lastBytesReceived;

- (void)abort;

- (NSString *)errorStr;

@end
