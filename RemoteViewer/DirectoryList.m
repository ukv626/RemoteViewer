//
//  DirectoryList.m
//  PhotoBrowser
//
//  Created by ukv on 5/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DirectoryList.h"
#include <sys/dirent.h>

//#import "Browser.h"
#import "BaseDriver.h"
#import "EntryLs.h"

#import "KTPhotoView.h"
#import "KTPhotoScrollViewController.h"

#define REFRESH_HEADER_HEIGHT 52.0f

@interface DirectoryList () {
    BaseDriver *_driver;
    BaseDriver *_directoryDownloader;
    BaseDriver *_fileDownloader;
    
    // ProgressView 
    UIProgressView *_progressView;

    unsigned long long _totalBytesToReceive;
    unsigned long long _bytesReceived;
    unsigned long long _bytesReceivedFromDir;
    
    // Toolbar
    UIBarButtonItem *_actionButton;
    UIBarButtonItem *_abortButton;
    UIActionSheet *_actionsSheet;
    
    // Confirmation
    UIAlertView *_downloadDirectoryConfirmation;
    
    // URLs Stack
    NSMutableArray *_urls;
    
    NSMutableArray *_filteredListEntries;
    IBOutlet UISearchBar *_searchBar;
    BOOL _searching;
    BOOL _letUserSelectRow;
        
    UIActivityIndicatorView *_activityIndicator;
    
    BOOL _directoryListReceiving;
    BOOL _directoryDownloading;
    BOOL _fileDownloading;
}

- (void)searchTableView;
- (void)doneSearching_Clicked:(id)sender;

- (void)showBrowser:(NSString *)currentFilename;
- (void)showWebViewer:(NSString *)filepath;

@end

@implementation DirectoryList

- (id)initWithDriver:(BaseDriver *)driver {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // Custom initialization
        _driver = [driver retain];
        _driver.delegate = self;
        
        _urls = [[NSMutableArray alloc] init];
        _photos = [[NSMutableArray alloc] init];
        
        // Push url
        [_urls addObject:_driver.url];
        _totalBytesToReceive = 0;
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    _directoryListReceiving = NO;
    _directoryDownloading = NO;
    _fileDownloading = NO;
    [self _receiveDidStopWithActivityIndicator:YES];
    
    [_urls release];
    [_photos release];
    [_driver release];
//    [_buttons release];
    [_actionButton release];
    [_abortButton release];
    [_searchBar release];
    [_filteredListEntries release];
    [_activityIndicator release];
    [_progressView release];
    
    [super dealloc];
}


#pragma mark * View controller boilerplate
- (void)loadView {
    [super loadView];
    
    _activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:_activityIndicator];
    
    CGRect frame = self.view.bounds;
    CGRect indFrame = _activityIndicator.bounds;
    
    // Position the indicator
    indFrame.origin.x = floorf((frame.size.width - indFrame.size.width) / 2);
    indFrame.origin.y = floorf((frame.size.height - indFrame.size.height) / 2);
    _activityIndicator.frame = indFrame;  
    
    assert(_activityIndicator != nil);
    
    // Toolbar
//    _buttons = [[NSMutableArray alloc] init];
    _abortButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                  target:self action:@selector(abortButtonPressed:)];
    
    _actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
                                                      target:self action:@selector(actionButtonPressed:)];
    self.navigationItem.rightBarButtonItem =_actionButton;
//    _downloadButton.enabled = NO;
    
//    [_buttons addObject:sortButton];
//    [_buttons addObject:_downloadButton];
//    [sortButton release];
    
//    self.toolbarItems = _buttons;
    
    
    // SearchBar
    _filteredListEntries = [[NSMutableArray alloc] init];
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    _searchBar.delegate = self;
    [self.view addSubview:_searchBar];
    
    self.tableView.tableHeaderView = _searchBar;
    _searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    
    _searching = NO;
    _letUserSelectRow = YES;
    
    // ProgressView
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 20.0)];
    _progressView.progressViewStyle = UIProgressViewStyleBar;
}


- (void)viewDidLoad {
    [super viewDidLoad];
            
    [self getDirectoryList];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [_activityIndicator release], _activityIndicator = nil;
    [_searchBar release], _searchBar = nil;   
    [_progressView release], _progressView = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark * Status management
// These methods are used by the core transfer to update the UI.

- (void)_receiveDidStartWithActivityIndicator:(BOOL)flag {
    if (flag) {
        [_activityIndicator startAnimating];
    }
    
    if (_driver.isDownloadable) {
        UIApplication *app = [UIApplication sharedApplication];
        app.networkActivityIndicatorVisible = YES;
    }
}

- (void)_receiveDidStopWithActivityIndicator:(BOOL)flag {
    if (flag) {
        [_activityIndicator stopAnimating];
    } 

    if (!_directoryDownloading && !_fileDownloading) {
        _progressView.progress = 0;
        _totalBytesToReceive = 0;
    }
    
    if (_driver.isDownloadable && !_directoryListReceiving && !_directoryDownloading && !_fileDownloading) {
        UIApplication *app = [UIApplication sharedApplication];
        app.networkActivityIndicatorVisible = NO;
    }
}

// =====================================================================================================
// --- directoryList -----------------------------------------------------------------------------------

- (void)getDirectoryList {
    _directoryListReceiving = YES;
    [self _receiveDidStartWithActivityIndicator:YES];
    
    [self performSelectorInBackground:@selector(_getDirectoryList) withObject:nil];
}

- (void)_getDirectoryList {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @try {
        [_driver directoryList];
    }
    @catch (NSException *exception) {        
    }
    @finally {
        [pool drain];        
    }
}

- (void)directoryListReceived {
    self.title = [_driver.url lastPathComponent];
    if(([self.title length] == 0) || ([self.title isEqualToString:@"/"]))  {
        self.title = [_driver.url host];
    }
    
    if ([_driver isDownloadable]) {
        _actionButton.enabled = YES;
    }
    
    if ([_urls count] > 1) {
        // Enable the Back button
        EntryLs *back = [[EntryLs alloc] initWithText:@".." IsDirectory:YES Date:nil Size:0];
        [_driver.listEntries insertObject:back atIndex:0];
        [back release];
    }
    
    [self.tableView reloadData];   
    _directoryListReceiving = NO;
    
    [self _receiveDidStopWithActivityIndicator:YES];
}


// =====================================================================================================
// --- directorySize ------------------------------------------------------------------------------------

- (void)getDirectorySize {
    _directoryDownloading = YES;
    [self _receiveDidStartWithActivityIndicator:NO];
    
    [self performSelectorInBackground:@selector(_getDirectorySize) withObject:nil];
}

- (void)_getDirectorySize {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSNumber *result = [NSNumber numberWithInteger:0];
    @try {
        _directoryDownloader = [[_driver clone] retain];
        _directoryDownloader.delegate = self;
        result = [_directoryDownloader directorySize];
    }
    @catch (NSException *exception) {        
    }
    @finally {
        [self performSelectorOnMainThread:@selector(directorySizeReceived:) withObject:result waitUntilDone:NO]; 
        [pool drain];        
    }
}

- (void)directorySizeReceived:(NSNumber *)value {
    _directoryDownloading = NO;
    [self _receiveDidStopWithActivityIndicator:NO];
    
    _totalBytesToReceive += [value unsignedLongLongValue];
    
    NSString *str = [NSString stringWithFormat:@"Are you about to download %.2fMb?", [value doubleValue]/(1024*1024)];
    
    _downloadDirectoryConfirmation = [[UIAlertView alloc] initWithTitle:@"Confirmation" message:str delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    
    [_downloadDirectoryConfirmation show];
}

// =====================================================================================================
// --- downloadDirectory -------------------------------------------------------------------------------

- (void)downloadDirectory {
    [self _receiveDidStartWithActivityIndicator:NO];
    self.navigationItem.titleView = _progressView;
    _directoryDownloading = YES;
    
    [self performSelectorInBackground:@selector(_downloadDirectory) withObject:nil];
}

- (void)_downloadDirectory {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @try {
        if (_directoryDownloader) {
            [_directoryDownloader downloadDirectory];
        }
    }
    @catch (NSException *exception) {        
    }
    @finally {
        [pool drain];        
    }
}

- (void)directoryDownloaded {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // release _directoryDownloader
    [_directoryDownloader release];
    _directoryDownloader = nil;
    
    _actionButton.enabled = YES;
    
    _directoryDownloading = NO; 
    self.navigationItem.titleView = nil;
    [self _receiveDidStopWithActivityIndicator:NO];
    _bytesReceivedFromDir = 0;
}

- (void)stopDirectoryDownloading {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @try {
        if (_directoryDownloader) {
            [_directoryDownloader abort];
        }
    }
    @catch (NSException *exception) {        
        //
    }
    @finally { 
        [pool drain];        
    }
}


// =====================================================================================================
// --- downloadFile ------------------------------------------------------------------------------------

- (void)downloadFile:(NSString *)filename WithSize:(NSNumber *)size {
    [self _receiveDidStartWithActivityIndicator:NO];
    _totalBytesToReceive += [size unsignedLongLongValue];
    self.navigationItem.rightBarButtonItem =_abortButton;
    self.navigationItem.titleView = _progressView;
    _fileDownloading = YES;
    
    [self performSelectorInBackground:@selector(_downloadFile:) withObject:filename];
}

- (void)_downloadFile:(NSString *)filename {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @try {
        _fileDownloader = [[_driver clone] retain];
        _fileDownloader.delegate = self;
        [_fileDownloader downloadFileAsync:filename];
    }
    @catch (NSException *exception) {        
    }
    @finally { 
        [pool drain];        
    }
}


- (void)fileDownloaded:(NSString *)filename {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if([_driver isImageFile:filename]) {
        [self showBrowser:filename];
    } else {
        NSString *localFilename = [[_driver pathToDownload] stringByAppendingPathComponent:filename];
        [self performSelectorOnMainThread:@selector(showWebViewer:) withObject:localFilename waitUntilDone:NO];
    }
    
    [_fileDownloader release];
    _fileDownloader = nil;
    
    _fileDownloading = NO;
    self.navigationItem.titleView = nil;
    [self _receiveDidStopWithActivityIndicator:NO];
    self.navigationItem.rightBarButtonItem =_actionButton;
    _bytesReceived = 0;
}

- (void)stopFileDownloading {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @try {
        if (_fileDownloader) {
            [_fileDownloader abort];
        }
    }
    @catch (NSException *exception) {        
        //
    }
    @finally { 
        [pool drain];        
    }
}

// -----------------------------------------------------------------------------------------------------

- (void)driver:(BaseDriver *)driver loadingDidEndNotification:(NSString *)filename {
    NSLog(@"%s [%@]", __PRETTY_FUNCTION__, driver);
    if (driver == _driver) {
        if ([filename isEqualToString:@"DirectoryListReceived"]) {
            [self directoryListReceived];
        } else {
            NSLog(@"QWE");
        }
    } else if (driver == _directoryDownloader) {
        [self directoryDownloaded];
    } else if (driver == _fileDownloader) {
        [self fileDownloaded:filename];
    }
}

- (void)handleLoadingProgressNotification:(id)sender {
    assert([[NSThread currentThread] isMainThread]);
    
    // Notification from _directoryDownloader
    if (sender == _directoryDownloader) {
        _bytesReceivedFromDir = [[_directoryDownloader lastBytesReceived] unsignedLongLongValue];
    } else if (sender == _fileDownloader) {
        _bytesReceived = [[_fileDownloader lastBytesReceived] unsignedLongLongValue];
    }
    
    _progressView.progress = (double)(_bytesReceived + _bytesReceivedFromDir) / (double)_totalBytesToReceive;
}

- (void)handleAbortedNotification:(id)sender {
    if (sender == _directoryDownloader) {
        // release
        [_directoryDownloader release];
        _directoryDownloader = nil;
        
        _directoryDownloading = NO;
        self.navigationItem.titleView = nil;
        [self _receiveDidStopWithActivityIndicator:NO];
    } else if (sender == _fileDownloader) {
        // release
        [_fileDownloader release];
        _fileDownloader = nil;
        
        _fileDownloading = NO;
        self.navigationItem.titleView = nil;
        [self _receiveDidStopWithActivityIndicator:NO];
        self.navigationItem.rightBarButtonItem =_actionButton;
    }
}

- (void)handleErrorNotification:(id)sender {
    NSString *errorMessage = @"";
    if (sender == _driver) {
        [self _receiveDidStopWithActivityIndicator:YES];
        errorMessage = [_driver errorStr];
    } else if (sender == _directoryDownloader) {
        errorMessage = [_directoryDownloader errorStr];
        _directoryDownloading = NO;
        [self _receiveDidStopWithActivityIndicator:NO];
        
        [_directoryDownloader release];
        _directoryDownloader = nil;
    } else if (sender == _fileDownloader) {
        errorMessage = [_fileDownloader errorStr];
        _fileDownloading = NO;
        [self _receiveDidStopWithActivityIndicator:NO];
        
        [_fileDownloader release];
        _fileDownloader = nil;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
}


// -----------------------------------------------------------------------------------------------------
- (void)showBrowser:(NSString *)currentFilename {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [_photos removeAllObjects];
    NSUInteger photoIndex = 0;
    NSUInteger i = 0;
    for (EntryLs *entry in _driver.listEntries) { 
        NSString *filename = [entry text];
        if([_driver isImageFile:filename]) {
            if ([filename isEqualToString:currentFilename]) photoIndex = i; 

            [_photos addObject:filename];
            ++i;
        }
    }
    
    KTPhotoScrollViewController *browser = [[KTPhotoScrollViewController alloc] 
                                            initWithDataSource:self andStartWithPhotoAtIndex:photoIndex];

    [self.navigationController pushViewController:browser animated:YES];
    // Release
    [browser release];
}

- (void)showWebViewer:(NSString *)filepath {
    assert([[NSThread currentThread] isMainThread]);

    UIDocumentInteractionController *viewer = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:filepath]];
    
    if (viewer) {
        viewer.delegate = self;
        [viewer retain];
        
        BOOL success = [viewer presentPreviewAnimated:YES];
        if(!success) {
            NSLog(@"VIEWER: FALSE");
            [viewer release];
        }
    }
}

#pragma mark - Table view data source and delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if(_searching) {
        return _filteredListEntries.count;
    } else {
        return _driver.listEntries.count;
    }
}

- (NSString *)_stringForNumber:(double)num asUnits:(NSString *)units {
    NSString *result;
    double fractional;
    double integral;
    
    fractional = modf(num, &integral);
    if((fractional < 0.1) || (fractional > 0.9)) {
        result = [NSString stringWithFormat:@"%.0f %@", round(num), units];
    } else {
        result = [NSString stringWithFormat:@"%.1f %@", num, units];
    }
    
    return  result;
}

- (NSString *)_stringForFileSize:(unsigned long long)fileSizeExact {
    double  fileSize;
    NSString *  result;
    
    fileSize = (double) fileSizeExact;
    if (fileSizeExact == 1) {
        result = @"1 byte";
    } else if (fileSizeExact < 1024) {
        result = [NSString stringWithFormat:@"%llu bytes", fileSizeExact];
    } else if (fileSize < (1024.0 * 1024.0 * 0.1)) {
        result = [self _stringForNumber:fileSize / 1024.0 asUnits:@"KB"];
    } else if (fileSize < (1024.0 * 1024.0 * 1024.0 * 0.1)) {
        result = [self _stringForNumber:fileSize / (1024.0 * 1024.0) asUnits:@"MB"];
    } else {
        result = [self _stringForNumber:fileSize / (1024.0 * 1024.0 * 1024.0) asUnits:@"GB"];
    }
    
    return result;
}

static NSDateFormatter *sDateFormatter;

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if(cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if (_directoryListReceiving) {
        return cell;
    }
    
    EntryLs *listEntry;
    if(_searching) {
        listEntry = [_filteredListEntries objectAtIndex:indexPath.row];
    } else {
        listEntry = [_driver.listEntries objectAtIndex:indexPath.row];
    }

    assert([listEntry isKindOfClass:[EntryLs class]]);
                
    // Use the second line of the cell to show various attributes    
    // File Size
    NSString *sizeStr = [listEntry isDir] ? @"" : [self _stringForFileSize:[listEntry size]];
    
    // Modification date
    if (sDateFormatter == nil) {
        sDateFormatter = [[NSDateFormatter alloc] init];
        assert(sDateFormatter != nil);
        
        [sDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    }
    NSString *dateStr = [sDateFormatter stringFromDate:[listEntry date]];
    
    cell.textLabel.text = [listEntry text];
    
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(cell.frame.size.width-90, cell.frame.size.height-20, 88, 18)];
    
    if([listEntry isDir]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (dateStr.length > 0) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Modified: %@", dateStr];
        } else {
            cell.detailTextLabel.text = @"";
        }
//        label.text = @"";
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        if (dateStr.length > 0) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Modified: %@ Size: %@", dateStr, sizeStr];
        } else {
            cell.detailTextLabel.text = @"";
        }
//        label.text = sizeStr;
    }
//    [cell addSubview:label];

    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_letUserSelectRow) {
        return indexPath;
    } else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    
    if (_directoryListReceiving) {
        return;
    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    
    if(cell.accessoryType == UITableViewCellAccessoryDisclosureIndicator) {
        if ([cell.textLabel.text isEqualToString:@".."]) {
            // pop url
            [_urls removeObject:_driver.url];
            
            assert([_urls count] >= 1);
            _driver.url = [_urls objectAtIndex:[_urls count] - 1];
            [_driver changeDir:@".."];
        } else {
            _driver.url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/", [_driver.url absoluteString], 
                                           [cell.textLabel.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            [_driver changeDir:cell.textLabel.text];

            // Push url
            [_urls addObject:_driver.url];              
        }
        
        // move to new dir
        [self getDirectoryList];
    } else {
        NSString *filePath = [[_driver pathToDownload] stringByAppendingPathComponent:cell.textLabel.text];
        // file already downloaded
        if ([_driver fileExist:filePath]) {
            NSLog(@"ALREADY DOWNLOADED");
            if([_driver isImageFile:filePath]) {
                [self showBrowser:cell.textLabel.text];
            } else {
                [self showWebViewer:filePath];
            }
        } else {
            // create dir for download files
            if ([_driver isDownloadable]) {
                [_driver createDirectory:@""];
            }
            
            if (!_directoryDownloading) {
                _totalBytesToReceive = 0;
            }
            
            //[self showBrowser:cell.textLabel.text];
            EntryLs *entry = [_driver.listEntries objectAtIndex:indexPath.row];

            
            [self downloadFile:cell.textLabel.text WithSize:[NSNumber numberWithLongLong:[entry size]]];
        
            /*
            NSString *fileURL = [[_driver.url absoluteString] stringByAppendingString:[cell.textLabel.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            _fileDownloader = [[_driver createDownloaderDriverWithURL:[NSURL URLWithString:fileURL]] retain];
            _fileDownloader.delegate = self;
            
            EntryLs *entry = [_driver.listEntries objectAtIndex:indexPath.row];
            _fileDownloader.totalFileSize = [entry size];
                
            self.navigationItem.titleView = _progressView;
            [self.navigationItem setHidesBackButton:YES animated:YES];
        
            [_fileDownloader startReceive];
             */
        }            
    }
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:YES];
}

// UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    _searching = YES;
    _letUserSelectRow = NO;
    self.tableView.scrollEnabled = NO;
    
    // Add the done button
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneSearching_Clicked:)] autorelease];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    // Remove all objects first
    [_filteredListEntries removeAllObjects];
    
    if ([searchText length] > 0) {
        _searching = YES;
        _letUserSelectRow = YES;
        self.tableView.scrollEnabled = YES;
        [self searchTableView];
    } else {
        _searching = NO;
        _letUserSelectRow = NO;
        self.tableView.scrollEnabled = NO;
    }
    
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self searchTableView];
}

- (void)searchTableView {
    NSString *searchText = _searchBar.text;
    
    for(EntryLs *entry in _driver.listEntries) {
        if([[entry text] rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [_filteredListEntries addObject:entry];
        }
    }
}

- (void)doneSearching_Clicked:(id)sender {
    _searchBar.text = @"";
    [_searchBar resignFirstResponder];
    
    _letUserSelectRow = YES;
    _searching = NO;
    self.navigationItem.rightBarButtonItem = _actionButton;
    self.tableView.scrollEnabled = YES;
    
    [self.tableView reloadData];
}


// Pull To Refresh
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView.contentOffset.y <= -REFRESH_HEADER_HEIGHT) {
        NSLog(@"pull to refresh");
        [self getDirectoryList];
    }
}


// UIDocumentInteractionControllerDelegate
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return self;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    [controller release];
}


// UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == _downloadDirectoryConfirmation) {
        if (buttonIndex == 0) {
            // release _directoryDownloader
            if (_directoryDownloader) {
                [_directoryDownloader release];
                _directoryDownloader = nil;
            }
        } else if (buttonIndex == 1) {
            [self downloadDirectory];
        }
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
    [alertView release];
}


#pragma mark - Action Sheet Delegate

- (void)abortButtonPressed:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self performSelectorInBackground:@selector(stopFileDownloading) withObject:nil];
}

- (void)actionButtonPressed:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (_actionsSheet) {
        // Dismiss
        [_actionsSheet dismissWithClickedButtonIndex:_actionsSheet.cancelButtonIndex animated:YES];
    } else {
        // Sheet
        if ([_driver isDownloadable]) {
            if (!_directoryDownloading) {
                _actionsSheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"Download directory", nil), 
                                  NSLocalizedString(@"Delete directory", nil), nil] autorelease];
            } else {
                _actionsSheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"Abort downloading directory", nil), 
                                  NSLocalizedString(@"Delete directory", nil), nil] autorelease];
            }
        } else {
            _actionsSheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
                                           destructiveButtonTitle:NSLocalizedString(@"Delete directory", nil)
                                                otherButtonTitles:nil] autorelease];
            _actionsSheet.destructiveButtonIndex = 0;
        }
        
        _actionsSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [_actionsSheet showFromBarButtonItem:sender animated:YES];
        } else {
            [_actionsSheet showInView:self.view];
        }            
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet == _actionsSheet) {           
        // Actions 
        _actionsSheet = nil;
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                [[NSFileManager defaultManager] removeItemAtPath:[_driver pathToDownload] error:nil];
                [self getDirectoryList];
            }
            
            if (buttonIndex == actionSheet.firstOtherButtonIndex) { 
                // Start/Stop direcory downloading
                
                if (!_directoryDownloading) {
                    [self getDirectorySize];
                } else {
                    [self performSelectorInBackground:@selector(stopDirectoryDownloading) withObject:nil];
                }
                return;
            } else if (buttonIndex == (actionSheet.firstOtherButtonIndex + 1)) {
                return;	
            }
        }
    }
}

#pragma mark -
#pragma mark KTPhotoBrowserDataSource

- (NSInteger)numberOfPhotos {
    return _photos.count;
}

- (void)imageAtIndex:(NSInteger)index photoView:(KTPhotoView *)photoView {
//    NSLog(@"%s [index=%d]", __PRETTY_FUNCTION__, index);
    NSString *filename = [_photos objectAtIndex:index];
    if (![_driver fileExist:filename]) {
        [_driver downloadFile:filename];
    }
    
    NSString *localFilename = [[_driver pathToDownload] stringByAppendingPathComponent:filename];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:localFilename];
    
    [photoView setImage:image];
    [image release];
}

@end
