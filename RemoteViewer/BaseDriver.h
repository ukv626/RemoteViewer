//
//  BaseDriver.h
//  PhotoBrowser
//
//  Created by ukv on 6/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LoadingDelegate;

@interface BaseDriver : NSObject

@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;

@property (assign) id<LoadingDelegate> delegate;
@property (nonatomic, readonly) NSMutableArray *listEntries;

- (id)initWithURL:(NSURL *)url;
- (id)clone;

- (BOOL)isDownloadable;
- (NSString *)pathToDownload;
- (BOOL)fileExist:(NSString *)filePath;
- (BOOL)isImageFile:(NSString *)filename;
- (void)createDirectory:(NSString *)directory;

- (BOOL)connect;
- (BOOL)changeDir:(NSString *)relativeDirPath;
- (void)sortByName;
- (void)directoryList;
- (void)downloadFile:(NSString *)filename;
- (void)downloadFileAsync:(NSString *)filename;

- (NSNumber *)directorySize;

- (void)downloadDirectory;

- (NSNumber *)lastBytesReceived;

- (void)abort;

- (NSString *)errorStr;

@end
