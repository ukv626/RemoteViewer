//
//  XMLReader.h
//
//  Created by Troy on 9/18/10.
//  Copyright 2010 Troy Brant. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface XMLReader : NSObject <NSXMLParserDelegate>

+ (NSArray *)arrayForXMLData:(NSData *)data error:(NSError **)error;
+ (NSArray *)arrayForXMLString:(NSString *)string error:(NSError **)errorPointer;

@end
