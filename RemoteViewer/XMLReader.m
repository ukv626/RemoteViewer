//
//  XMLReader.m
//
//  Created by Troy on 9/18/10.
//  Copyright 2010 Troy Brant. All rights reserved.
//

#import "XMLReader.h"

NSString *const kXMLReaderTextNodeKey = @"text";

@interface XMLReader() {
    BOOL _isFile;
    
    NSMutableArray *_files;
    NSMutableArray *_dirs;
    NSMutableString *_currentFile;
    
    NSError **_errorPointer; 
}

- (id)initWithError:(NSError **)error;
- (NSArray *)objectWithData:(NSData *)data;

@end


@implementation XMLReader

#pragma mark -
#pragma mark Public methods

+ (NSArray *)arrayForXMLData:(NSData *)data error:(NSError **)error
{
    XMLReader *reader = [[XMLReader alloc] initWithError:error];
    NSArray *rootDictionary = [reader objectWithData:data];
    [reader release];
    return rootDictionary;
}

+ (NSArray *)arrayForXMLString:(NSString *)string error:(NSError **)error
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [XMLReader arrayForXMLData:data error:error];
}

#pragma mark -
#pragma mark Parsing

- (id)initWithError:(NSError **)error
{
    if (self = [super init])
    {
        _errorPointer = error;
    }
    return self;
}

- (void)dealloc
{
    [_files release];
    [_dirs release];
    [_currentFile release];
    
    [super dealloc];
}

- (NSArray *)objectWithData:(NSData *)data
{
    // Clear out any old data
    [_files release];
    [_dirs release];
    [_currentFile release];
    
    _files = [[NSMutableArray alloc] init];
    _dirs = [[NSMutableArray alloc] init];
    
    _currentFile = [[NSMutableString alloc] init];
    
    // Initialize the stack with a fresh dictionary
//    [dictionaryStack addObject:[NSMutableDictionary dictionary]];
    
    // Parse the XML
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    parser.delegate = self;
    BOOL success = [parser parse];
    
    // Return the stack's root dictionary on success
    if (success)
    {
        NSArray *result = [NSArray arrayWithArray:_files]; 
        return result;
    }
    
    return nil;
}

#pragma mark -
#pragma mark NSXMLParserDelegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {    
    
    _isFile = [[elementName lowercaseString] isEqualToString:@"file"];
    
    if([[elementName lowercaseString] isEqualToString:@"dir"]) {
        NSString *newDir = [NSString stringWithFormat:@"%@/",[attributeDict objectForKey:@"name"]];
        [_dirs addObject:newDir];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    if (_isFile && ([_currentFile length] > 0)) {
        
        NSMutableString *path = [[NSMutableString alloc] init];
        for (NSString *dir in _dirs) {
            [path appendString:dir];
        }
        
        [_currentFile insertString:path  atIndex:0];
        [_files addObject:_currentFile];
        
        [_currentFile release];
        _currentFile = [[NSMutableString alloc] init];
    }
    
    if ([[elementName lowercaseString] isEqualToString:@"dir"]) {
        [_dirs removeObjectAtIndex:(_dirs.count - 1)];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    NSString *newStr = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (_isFile && ([newStr length] > 0)) {
        // Build the text value
        [_currentFile appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    // Set the error pointer to the parser's error object
    *_errorPointer = parseError;
}

@end
