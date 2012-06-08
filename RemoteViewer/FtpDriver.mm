//
//  FtpDriver.m
//  PhotoBrowser
//
//  Created by ukv on 6/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FtpDriver.h"
#import "LoadingDelegate.h"
#import "EntryLs.h"

#import "CkoFtp2.h"
#import "XMLReader.h"

@interface FtpDriver() {
    CkoFtp2 *_driver;
    unsigned long long _bytesReceived;
    BOOL _aborted;
}

@end

@implementation FtpDriver

- (id)initWithURL:(NSURL *)url {
    if ((self = [super initWithURL:url])) {
        _driver = [[CkoFtp2 alloc] init];
    }
    
    return self;
}

- (id)clone {
    FtpDriver *copy = [[[FtpDriver alloc] initWithURL:self.url] autorelease];
    copy.username = self.username;
    copy.password = self.password;
    return copy;
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [_driver Disconnect];
    [_driver release];
    
    [super dealloc];
}

- (BOOL)changeDir:(NSString *)relativeDirPath {
    if (!_driver.IsConnected) {
        return NO;
    }

    BOOL success = [_driver ChangeRemoteDir:relativeDirPath]; 
    return success;
}

 
- (BOOL)isDownloadable {
    return YES;
}

- (BOOL)connect {
    BOOL success = [_driver UnlockComponent:@"qwe"];
    if (!success) {
        return NO;
    }
    
    _driver.Hostname = [self.url host];
    _driver.Username = self.username;
    _driver.Password = self.password;
    
     if ([self.url.scheme isEqualToString:@"ftps"]) {
         _driver.AuthTls = YES;
         _driver.Ssl = NO;
     }
    
    if((success = [_driver Connect])) {
        if (![[self.url path] isEqualToString:@"/"]) {
            success = [_driver ChangeRemoteDir:[[self.url path] substringFromIndex:1]];
        }
    }
    
    return success;
}

- (void)directoryList {
    [self.listEntries removeAllObjects];
    
    BOOL success = _driver.IsConnected;
    if (!success) {
        success = [self connect];
    }

    if (success) {
        [_driver setListPattern:@"*"];
        int n = [_driver.NumFilesAndDirs intValue];
        if (n > 0) {
            for (int i = 0; i < n; i++) {
                NSNumber *fileNum = [NSNumber numberWithInt:i];
            
                NSString *filename = [_driver GetFilename:fileNum];
                NSNumber *fileSize = [_driver GetSize:fileNum];
                BOOL isDir = [_driver GetIsDirectory:fileNum];
                NSDate *fileModDate = [_driver GetLastModifiedTime:fileNum];
                                  
                EntryLs *entry = [[EntryLs alloc] initWithText:filename IsDirectory:isDir 
                                                          Date:fileModDate Size:[fileSize unsignedLongLongValue]];
            
                [self.listEntries addObject:entry];
                [entry release];
            }
        }
        [self sortByName];
        
        // notificate delgate
        if ([self.delegate respondsToSelector:@selector(driver:loadingDidEndNotification:)]) {
            [self.delegate driver:self loadingDidEndNotification:@"DirectoryListReceived"];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(handleErrorNotification:)]) {
            [self.delegate handleErrorNotification:self];
        }
    }

}

- (void)downloadFile:(NSString *)filename {
    BOOL success = _driver.IsConnected;
    if (!success) {
        success = [self connect];
    }
    
    if (success) {
        [_driver GetFile:filename localFilename:[[self pathToDownload] stringByAppendingPathComponent:filename]];
    } else {
        if ([self.delegate respondsToSelector:@selector(handleErrorNotification:)]) {
            [self.delegate handleErrorNotification:self];
        }
    }
}


- (NSNumber *)lastBytesReceived {
    return [NSNumber numberWithUnsignedLongLong:_bytesReceived];
}

- (void)downloadFileAsync:(NSString *)filename {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    BOOL success =_driver.IsConnected;
    
    if (!success) {
        success = [self connect];
    }
    
    if (!success) {
        if ([self.delegate respondsToSelector:@selector(handleErrorNotification:)]) {
            [self.delegate handleErrorNotification:self];
        }
        return;
    }
    
    _aborted = NO;
    NSString *localFilename = [[self pathToDownload] stringByAppendingPathComponent:filename];
    success = [_driver AsyncGetFileStart:filename localFilename:localFilename];
    if (success) {
        while (_driver.AsyncFinished != YES) {
            _bytesReceived = [_driver.AsyncBytesReceived64 unsignedLongLongValue];
            [_driver SleepMs:[NSNumber numberWithInt:1000]];
            
            [self performSelectorOnMainThread:@selector(notifyAboutProgress:) withObject:self waitUntilDone:NO];
        }
        if (!_aborted) {
            if ([self.delegate respondsToSelector:@selector(driver:loadingDidEndNotification:)]) {
                [self.delegate driver:self loadingDidEndNotification:filename];
            }
        } else {
            [[NSFileManager defaultManager] removeItemAtPath:localFilename error:nil];
            
            if ([self.delegate respondsToSelector:@selector(handleAbortedNotification:)]) {
                [self.delegate handleAbortedNotification:self];
            }
        }
    }
}


- (NSNumber *)directorySize {
    BOOL success = _driver.IsConnected;
    if (!success) {
        success = [self connect];
    }
    
    unsigned long long totalDirectorySize = 0;
    
    if (!success) {
        if ([self.delegate respondsToSelector:@selector(handleErrorNotification:)]) {
            [self.delegate handleErrorNotification:self];
        }
    } else {
        [self.listEntries removeAllObjects];
        
        [_driver setDirListingCharset:@"utf-8"];
        NSString *xmlStr = [_driver DirTreeXml];
        
        NSError *parseError = nil;
        NSArray *files = [XMLReader arrayForXMLString:xmlStr error:&parseError];
        
        // calculate total directory size
        NSString *currentDir = [_driver GetCurrentRemoteDir];
        NSString *originalCurrentDir = currentDir;
        
        
        for (NSString *filepath in files) {
            NSString *newDir = [originalCurrentDir stringByAppendingPathComponent:[filepath stringByDeletingLastPathComponent]];
            if (![currentDir isEqualToString:newDir]) {
                [_driver ChangeRemoteDir:newDir];
                currentDir = newDir;
            }
            NSNumber *fileSize = [_driver GetSizeByName64:[filepath lastPathComponent]];
            totalDirectorySize += [fileSize unsignedLongLongValue];
        }
        // restore current dir
        [_driver ChangeRemoteDir:originalCurrentDir];
        [self.listEntries addObjectsFromArray:files];
    }
    
    return [NSNumber numberWithUnsignedLongLong:totalDirectorySize];
}

- (void)downloadDirectory {
    BOOL success = _driver.IsConnected;
    
    if (!success) {
        success = [self connect];
    }
    
    if (!success) {
        if ([self.delegate respondsToSelector:@selector(handleErrorNotification:)]) {
            [self.delegate handleErrorNotification:self];
        }
    } else {
        _aborted = NO;

        [self createDirectory:@""];
        NSString *currentDir = [_driver GetCurrentRemoteDir];
        NSString *originalCurrentDir = currentDir;
        
        unsigned long long totalBytesReceived = 0;
        
        for (NSString *filepath in self.listEntries) {
            NSString *newDir = [originalCurrentDir stringByAppendingPathComponent:[filepath stringByDeletingLastPathComponent]];
            if (![currentDir isEqualToString:newDir]) {
                [_driver ChangeRemoteDir:newDir];
                
                [self createDirectory:[filepath stringByDeletingLastPathComponent]];
                currentDir = newDir;
            }

            NSString *filename = [filepath lastPathComponent];
            NSString *localFilename = [[self pathToDownload] stringByAppendingPathComponent:filepath];

            BOOL success = [_driver AsyncGetFileStart:filename localFilename:localFilename];
            if (success) {
                while (_driver.AsyncFinished != YES) {
                    _bytesReceived = [_driver.AsyncBytesReceived64 unsignedLongLongValue] + totalBytesReceived;
                    [_driver SleepMs:[NSNumber numberWithInt:1000]];
                    
                    [self performSelectorOnMainThread:@selector(notifyAboutProgress:) withObject:self waitUntilDone:NO];
                }
                totalBytesReceived += [_driver.AsyncBytesReceived64 unsignedLongLongValue];
            } else {
                _aborted = true;
                break;
            }
            
            if (_aborted) {
                // remove aborted file
                [[NSFileManager defaultManager] removeItemAtPath:localFilename error:nil];
                break;
            };
        }
        
        if (!_aborted) {
            if ([self.delegate respondsToSelector:@selector(driver:loadingDidEndNotification:)]) {
                [self.delegate driver:self loadingDidEndNotification:@"DirectoryDownloaded"];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(handleAbortedNotification:)]) {
                [self.delegate handleAbortedNotification:self];
            }
        }

    }
}

- (void)notifyAboutProgress:(id)sender {
    if ([self.delegate respondsToSelector:@selector(handleLoadingProgressNotification:)]) {
        [self.delegate handleLoadingProgressNotification:sender];
    }
}



- (void)abort {
    [_driver AsyncAbort];
    _aborted = YES;
}

- (NSString *)errorStr {
    NSString *result;
    int errorCode = [[_driver ConnectFailReason] intValue];
    switch (errorCode) {
        case 1:
            result = @"Empty hostname";
            break;
        case 2:
            result = @"DNS lookup failed";
            break;
        case 3:
            result = @"DNS timeout";
            break;
        case 4:
            result = @"Aborted by application";
            break;
        case 5:
            result = @"Internal failure";
            break;
        case 6:
            result = @"Connect Timed Out";
            break;
        case 7:
            result = @"Connect Rejected";
            break;
            // SSL
        case 100:
            result = @"Internal schannel error";
            break;
        case 101:
            result = @"Failed to create credentials";
            break;
        case 102:
            result = @"Failed to send initial message to proxy";
            break;
        case 103:
            result = @"Handshake failed";
            break;
        case 104:
            result = @"Failed to obtain remote certificate";
            break;
        case 105:
            result = @"Failed to verify server certificate";
            break;
            // FTP
        case 200:
            result = @"Connected, but failed to receive greeting from FTP server";
            break;
        case 201:
            result = @"Failed to do AUTH TLS or AUTH SSL";
            break;
            // Protocol/Component
        case 300:
            result = @"Asynch op in progress";
            break;
        case 301:
            result = @"Login failure";
            break;
        default:
            result = @"Unknow error!!";
            break;
    }
    return result;
}


@end
