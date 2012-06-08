//
//  BaseDriver.m
//  PhotoBrowser
//
//  Created by ukv on 6/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BaseDriver.h"
#import "EntryLs.h"
#import "LoadingDelegate.h"

@interface BaseDriver() {
    NSURL *_url;
    NSString *_username;
    NSString *_password;
    
    id<LoadingDelegate> _delegate;
    NSMutableArray *_listEntries;
}

@end

@implementation BaseDriver

@synthesize url = _url;
@synthesize username = _username;
@synthesize password = _password;
@synthesize delegate = _delegate;
@synthesize listEntries = _listEntries;

- (id)initWithURL:(NSURL *)url {
    if((self = [super init])) {
        self.url = url;
        _listEntries = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (id)clone {
    return nil;
}

- (void)dealloc {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    [_username release];
    [_password release];
    [_listEntries release];
    
    [super dealloc];
}

- (BOOL)isDownloadable {
    return  NO;
}

- (NSString *)pathToDownload {
    NSString *result;
    if ([_url.host isEqualToString:@"localhost"]) { 
        result = [_url path];
    }
    else {
        NSString *path = [NSString stringWithFormat:@"Downloads/%@/%@", _url.host,_url.path];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        result = [[paths objectAtIndex:0] stringByAppendingPathComponent:path];
    }
    return result;
}

- (BOOL)fileExist:(NSString *)filePath {
    BOOL result = NO;
    
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        result = YES;
    }
    
    return result;
}

- (BOOL)isImageFile:(NSString *)filename {
    BOOL result = NO;
    
    NSString *extension;    
    
    if (filename != nil) {
        extension = [filename pathExtension];
        if (extension != nil) {
            result = ([extension caseInsensitiveCompare:@"gif"] == NSOrderedSame)
            || ([extension caseInsensitiveCompare:@"png"] == NSOrderedSame)
            || ([extension caseInsensitiveCompare:@"jpg"] == NSOrderedSame)
            || ([extension caseInsensitiveCompare:@"jpeg"] == NSOrderedSame);
        }
    }
    
    return result;
}

- (void)createDirectory:(NSString *)directory {
    NSString *path = [[self pathToDownload] stringByAppendingPathComponent:directory];
    NSError *error;
    
    //    NSLog(@"%@", path);
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:path 
                                      withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Create directory error: %@", error);
            
        }
    }
    
}

- (void)sortByName {
    NSMutableArray *files = [[NSMutableArray alloc] init];
    NSMutableArray *dirs = [[NSMutableArray alloc] init];
    
    for (EntryLs *entry in self.listEntries) {
        if (entry.isDir) {
            [dirs addObject:entry];
        } else {
            [files addObject:entry];
        }
    }
    
    NSArray *sortedFiles = [files sortedArrayUsingComparator:^NSComparisonResult(EntryLs *obj1, EntryLs *obj2) {
        return [obj1.text compare:obj2.text];
    }];
    
    NSArray *sortedDirs = [dirs sortedArrayUsingComparator:^NSComparisonResult(EntryLs *obj1, EntryLs *obj2) {
        return [obj1.text compare:obj2.text];
    }];
    
    [files release];
    [dirs release];
    
    [self.listEntries removeAllObjects];
    [self.listEntries addObjectsFromArray:sortedDirs];
    [self.listEntries addObjectsFromArray:sortedFiles];
}


// ---------
- (BOOL)connect {
    return NO;
}

- (BOOL)changeDir:(NSString *)relativeDirPath {
    return NO;
}

- (void)directoryList {
    [self.listEntries removeAllObjects];
    
    NSArray *properties = [NSArray arrayWithObjects: NSURLLocalizedNameKey,
                           NSURLCreationDateKey, NSURLLocalizedTypeDescriptionKey, nil];
    
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.url includingPropertiesForKeys:properties options:(NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles) error:nil];
    
    
    NSDictionary *attribs;
    
    for (NSURL *entry in dirContents) {
        EntryLs *entryToAdd = [[EntryLs alloc] init];
        entryToAdd.text = [entry lastPathComponent];
        
        attribs = [[NSFileManager defaultManager] attributesOfItemAtPath:[entry path]  error:nil];
        if ([attribs objectForKey:(id)NSFileType] == NSFileTypeDirectory) {
            entryToAdd.isDir = YES;
        } else {
            entryToAdd.isDir = NO;
        }
        
        entryToAdd.date = [attribs objectForKey:(id)NSFileModificationDate];        
        NSNumber *size;
        size = [attribs objectForKey:(id)NSFileSize];
        if(size != nil) {
            entryToAdd.size = [size unsignedLongLongValue];
            
        }
        
        [self.listEntries addObject:entryToAdd];
        [entryToAdd release];
    }
    //[properties release];
    //[dirContents release];
    [self sortByName];
    
    [self performSelectorOnMainThread:@selector(notifyAboutFinished:) withObject:self waitUntilDone:NO];
}

- (void)downloadFile:(NSString *)filename {
    //
}

- (void)downloadFileAsync:(NSString *)filename {
    //
}


- (NSNumber *)directorySize {
    return [NSNumber numberWithInteger:0];
}

- (void)downloadDirectory {
    //
}

- (NSNumber *)lastBytesReceived {
    return [NSNumber numberWithInteger:0];
}

- (void)abort {
    //
}

- (NSString *)errorStr {
    return @"";
}

- (void)notifyAboutFinished:(id)sender {
    if ([self.delegate respondsToSelector:@selector(driver:loadingDidEndNotification:)]) {
        [self.delegate driver:sender loadingDidEndNotification:@""];
    }
}

@end
