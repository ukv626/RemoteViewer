//
//  LoginView.m
//  PhotoBrowser
//
//  Created by ukv on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginView.h"
//#import "Photo.h"
#import "DirectoryList.h"
#import "FtpDriver.h"
#import "ConnectionsList.h"


@interface LoginView () {
    // Toolbar
    NSMutableArray *_buttons;
}

// Private methods
//- (CGRect)frameForMainView;
@end

@implementation LoginView

@synthesize urlLabel = _urlLabel;
@synthesize loginLabel = _loginLabel;

@synthesize urlText = _urlText;
@synthesize usernameText = _usernameText;
@synthesize passwordText = _passwordText;
@synthesize activityIndicator = _activityIndicator;
@synthesize localButton = _localButton;
@synthesize connectButton = _connectButton;


#pragma mark * View controller boilerplate

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [_buttons release];
    
    [_urlLabel release];
    [_loginLabel release];
    [_urlText release];
    [_usernameText release];
    [_passwordText release];
    [_activityIndicator release];
    [_localButton release];
    [_connectButton release];
    
    [super dealloc];
}

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor blueColor];
    
    self.title = @"FTPhoto";
    
    CGRect bounds = self.view.bounds;
    float offsetX = 20;
    float offsetY = 20;

    self.urlLabel = [[UILabel alloc] initWithFrame:CGRectMake(offsetX, offsetY, bounds.size.width - 2*offsetX, 30)];
    offsetY += self.urlLabel.frame.size.height;
    
    _urlLabel.backgroundColor = [UIColor blueColor];
    _urlLabel.text = @"Connect to FTP Server";
    
    _urlText = [[UITextField alloc] initWithFrame:CGRectMake(offsetX, offsetY, bounds.size.width - 2*offsetX, 30)];
    _urlText.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _urlText.delegate = self;
    _urlText.borderStyle = UITextBorderStyleRoundedRect;
    _urlText.clearButtonMode = UITextFieldViewModeWhileEditing;
    _urlText.text = @"ftp://127.0.0.1/Downloads/";
    //    self.urlText.text = @"ftp://ftp.itandem.ru";
    _urlText.keyboardType = UIKeyboardTypeURL;
    _urlText.returnKeyType = UIReturnKeyDone;
    _urlText.placeholder = @"ftp://127.0.0.1/Downloads/";
   
    offsetY += self.urlText.frame.size.height + 20;
    _loginLabel = [[UILabel alloc] initWithFrame:CGRectMake(offsetX, offsetY, bounds.size.width - 2*offsetX, 30)];
    _loginLabel.backgroundColor = [UIColor blueColor];
    _loginLabel.text = @"Login Details";
    
    offsetY += self.loginLabel.frame.size.height;
    _usernameText = [[UITextField alloc] initWithFrame:CGRectMake(offsetX, offsetY, bounds.size.width - 2*offsetX, 30)];
    _usernameText.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _usernameText.delegate = self;
    _usernameText.borderStyle = UITextBorderStyleRoundedRect;
    _usernameText.placeholder = @"Username";
    _usernameText.clearButtonMode = UITextFieldViewModeWhileEditing;
    _usernameText.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _usernameText.text = @"ukv";
    
    offsetY += self.usernameText.frame.size.height + 5;
    _passwordText = [[UITextField alloc] initWithFrame:CGRectMake(offsetX, offsetY, bounds.size.width - 2*offsetX, 30)];
    _passwordText.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _passwordText.delegate = self;
    _passwordText.borderStyle = UITextBorderStyleRoundedRect;
    _passwordText.placeholder = @"Password";
    _passwordText.clearButtonMode = UITextFieldViewModeWhileEditing;
    _passwordText.secureTextEntry = YES;
    _passwordText.text = @"njgktcc";
    
    [self.view addSubview:_urlLabel];
    [self.view addSubview:_urlText];
    
    [self.view addSubview:_loginLabel];
    [self.view addSubview:_usernameText];
    [self.view addSubview:_passwordText];
    
    _localButton = [[UIBarButtonItem alloc] initWithTitle:@"Local" style:UIBarButtonItemStylePlain target:self action:@selector(localButton_Clicked:)];
    self.navigationItem.leftBarButtonItem = _localButton;
    
    _connectButton = [[UIBarButtonItem alloc] initWithTitle:@"Connect" style:UIBarButtonItemStylePlain target:self action:@selector(connectButton_Clicked:)];
    self.navigationItem.rightBarButtonItem = _connectButton;

    self.activityIndicator.hidden = YES;
    
    // Toolbar
    _buttons = [[NSMutableArray alloc] init];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleBordered
                                                                 target:self action:@selector(addButton_Clicked:)];
    UIBarButtonItem *listButton = [[UIBarButtonItem alloc] initWithTitle:@"List" style:UIBarButtonItemStyleBordered 
                                                                  target:self action:@selector(listButton_Clicked:)];
    [_buttons addObject:addButton];
    [_buttons addObject:listButton];
    [addButton release];
    [listButton release];
    
    self.toolbarItems = _buttons;
    self.navigationController.toolbarHidden = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.navigationController setToolbarHidden:NO animated:YES];
    
//    self.usernameText.text = @"usename"; //[[NSUserDefaults standardUserDefaults] stringForKey:@"Username"];
//    self.passwordText.text = @"password"; //[[NSUserDefaults standardUserDefaults] stringForKey:@"Password"];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
    self.urlText = nil;
    self.usernameText = nil;
    self.passwordText = nil;
    self.activityIndicator = nil;
    self.localButton = nil;
    self.connectButton = nil;
    
}

/*
- (void)viewWillLayoutSubviews {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // Super
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5")) [super viewWillLayoutSubviews];
    
    CGRect bounds = self.view.bounds;
    float offsetX = 20;
    float offsetY = 20;
    self.urlLabel.frame = CGRectMake(offsetX, offsetY, bounds.size.width - 2*offsetX, 30);
    offsetY += self.urlLabel.frame.size.height;

    self.urlText.frame = CGRectMake(offsetX, offsetY, bounds.size.width - 2*offsetX, 30);
    offsetY += self.urlText.frame.size.height + 20;

    self.loginLabel.frame = CGRectMake(offsetX, offsetY, bounds.size.width - 2*offsetX, 30);
    offsetY += self.loginLabel.frame.size.height;

    self.usernameText.frame = CGRectMake(offsetX, offsetY, bounds.size.width - 2*offsetX, 30);
    offsetY += self.usernameText.frame.size.height + 5;

    self.passwordText.frame = CGRectMake(offsetX, offsetY, bounds.size.width - 2*offsetX, 30);

    
    //    CGRect frame = self.view.frame;
    //    NSLog(@"view.bounds: %.0f x %.0f", frame.size.width, frame.size.height);
    
    //self.view.frame = [self frameForMainView];
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES; //(interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Frame Calculations

/*
- (CGRect)frameForMainView {
    CGRect bounds = [[UIScreen mainScreen] bounds];

    NSLog(@"%.0f x %.0f", bounds.size.width, bounds.size.height);
    return bounds;
}
 */

// --------------
- (NSString *)connectionsFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *result = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"connections.plist"]; 
    
    return result;
}

- (void)setTextFields:(NSString *)url username:(NSString *)username password:(NSString *)password {
    _urlText.text = url;
    _usernameText.text = username;
    _passwordText.text = password;
}

- (void)addButton_Clicked:(id)sender {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:[self connectionsFilePath]];

    NSDictionary *innerDict = [dictionary objectForKey:_urlText.text];
    if (innerDict) {
        [innerDict setValue:_usernameText.text forKey:@"username"];
        [innerDict setValue:_passwordText.text forKey:@"password"];
    } else {
        innerDict = [NSDictionary dictionaryWithObjects:
                     [NSArray arrayWithObjects:_usernameText.text, _passwordText.text, nil] 
                                                forKeys:[NSArray arrayWithObjects:@"username", @"password", nil]];
    }
    [dictionary setObject:innerDict forKey:_urlText.text];
    [dictionary writeToFile:[self connectionsFilePath] atomically:YES];
    [dictionary release];
}

- (void)listButton_Clicked:(id)sender {
    ConnectionsList *list = [[ConnectionsList alloc] initWithStyle:UITableViewStylePlain];
    list.delegate = self;
    
    [self.navigationController pushViewController:list animated:YES];
    
    // Release
    [list release];
}

- (IBAction)localButton_Clicked:(id)sender {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Downloads"];
    // stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; //[NSString stringWithFormat:@"/Downloads/ukv"];
    
    BaseDriver *localDriver = [[BaseDriver alloc] initWithURL:[NSURL fileURLWithPath:dir]];
    
    DirectoryList *dirList = [[DirectoryList alloc] initWithDriver:localDriver];
    
    [localDriver release];
    [self.navigationController pushViewController:dirList animated:YES];
    
    // Release
    [dirList release];
}


- (IBAction)connectButton_Clicked:(id)sender {
    BOOL success = NO;
    NSString *errorStr;
    NSURL *url = [NSURL URLWithString:self.urlText.text];
    // check url
    if (url && url.scheme && url.host) {
        if ([url.scheme isEqualToString:@"ftp"] || [url.scheme isEqualToString:@"ftps"]) {
            success = YES;
            FtpDriver *ftpDriver = [[FtpDriver alloc] initWithURL:url];
            ftpDriver.username = self.usernameText.text;
            ftpDriver.password = self.passwordText.text;
    
            DirectoryList *dirList = [[DirectoryList alloc] initWithDriver:ftpDriver];
    
            [ftpDriver release];
            [self.navigationController pushViewController:dirList animated:YES];
    
            // Release
            [dirList release];
        } else {
            errorStr = [NSString stringWithFormat:@"Unknown protocol: %@", url.scheme];
        }
    } else {
        errorStr = @"Invalid URL";
    }
    
    if (!success) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorStr delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

/*
 - (void)textFieldDidEndEditing:(UITextField *)textField {
 NSString *defaultsKey;
 NSString *newValue;
 NSString *oldValue;
 
 if(textField == self.urlText) {
 defaultsKey =@"URLText";
 } else if(textField == self.usernameText) {
 defaultsKey = @"Username";
 } else if(textField == self.passwordText) {
 defaultsKey = @"Password";
 } else {
 assert(NO);
 defaultsKey = nil;
 }
 
 newValue = textField.text;
 oldValue = [[NSUserDefaults standardUserDefaults] stringForKey:defaultsKey];
 
 // Save the value if it's changed
 assert(newValue != nil);
 assert(oldValue != nil);
 
 if(![newValue isEqual:oldValue]) {
 [[NSUserDefaults standardUserDefaults] setObject:newValue forKey:defaultsKey];
 }
 }
 */


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
#pragma unused(textField)
    
    assert( (textField == self.urlText) || (textField == self.usernameText) || (textField == self.passwordText) );
    [textField resignFirstResponder];
    
    return NO;
}

// UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [alertView release];
}

@end
