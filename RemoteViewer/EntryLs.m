//
//  EntryLs.m
//  PhotoBrowser
//
//  Created by ukv on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EntryLs.h"

@interface EntryLs() {
    NSString *_text;
    unsigned long long _size;
    NSDate *_date;
    BOOL _isDir;
}

@end

@implementation EntryLs

@synthesize text = _text;
@synthesize size = _size;
@synthesize date = _date;
@synthesize isDir = _isDir;

- (id)initWithDictionaryEntry:(NSDictionary *)entry {
    if((self = [super init])) {
        self.text = [entry objectForKey:(id) kCFFTPResourceName];
        
        int type;
        NSNumber *typeNum;
        NSNumber *sizeNum;
        typeNum = [entry objectForKey:(id) kCFFTPResourceType];
        if(typeNum != nil) {
            assert([typeNum isKindOfClass:[NSNumber class]]);
            type = [typeNum intValue];
        } else {
            type = 0;
        }
        
        self.isDir = (type == 4) ? YES : NO;
        
        sizeNum = [entry objectForKey:(id) kCFFTPResourceSize];
        if(sizeNum != nil) {
            self.size = [sizeNum unsignedLongLongValue];
        }
        
        self.date = [entry objectForKey:(id) kCFFTPResourceModDate];
    }
    
    return self;
}

- (id)initWithText:(NSString *)text IsDirectory:(BOOL)isDir Date:(NSDate *)date Size:(unsigned long long)size {
    if ((self = [super init])) {
        self.text = text;
        self.isDir = isDir;
        self.date = date;
        self.size = size;
    }
    
    return self;
}

@end
