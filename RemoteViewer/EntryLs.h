//
//  EntryLs.h
//  PhotoBrowser
//
//  Created by ukv on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EntryLs : NSObject

@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) unsigned long long size;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, assign) BOOL isDir;

- (id)initWithDictionaryEntry:(NSDictionary *)entry;
- (id)initWithText:(NSString *)text IsDirectory:(BOOL)isDir Date:(NSDate *)date Size:(unsigned long long)size;

@end
