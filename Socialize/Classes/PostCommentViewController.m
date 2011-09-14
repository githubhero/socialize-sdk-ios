//
//  PostCommentViewController.m
//  appbuildr
//
//  Created by William M. Johnson on 4/5/11.
//  Copyright 2011 pointabout. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "PostCommentViewController.h"
#import "UIButton+Socialize.h"
#import "CommentMapView.h"
#import "AppMakrLocation.h"
#import "Socialize.h"
#import "LoadingView.h"
#import "NSString+PlaceMark.h"
#import "UIKeyboardListener.h"

@interface PostCommentViewController ()

-(void)setShareLocation:(BOOL)enableLocation;
-(void)setUserLocationTextLabel:(NSString*) userLoaction;
-(void)sendButtonPressed:(id)button;
-(void)closeButtonPressed:(id)button;
-(void)configureDoNotShareLocationButton;
-(void)updateViewWithNewLocation: (MKUserLocation*)userLocation;
-(BOOL)shouldShareLocationOnStart;

@end 

@implementation PostCommentViewController

@synthesize commentTextView;
@synthesize locationText;
@synthesize doNotShareLocationButton;
@synthesize activateLocationButton;
@synthesize mapOfUserLocation;
@synthesize socialize = _socialize;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil entityUrlString:(NSString*)entityUrlString
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _socialize = [[Socialize alloc ] initWithDelegate:self];
        _entityUrlString = [entityUrlString retain];
        kbListener = [[UIKeyboardListener alloc] initWithVisibleKeyboard:NO];
    }
    return self;
}

- (void)dealloc
{
    [commentTextView release];
    [doNotShareLocationButton release];
    [activateLocationButton release];
    [mapOfUserLocation release];
    [locationText release];
    [_loadingIndicatorView release];
    [_socialize release];
    [_entityUrlString release];
    [kbListener release];
    [super dealloc];
}

#pragma Location enable/disable button callbacks

-(BOOL)shouldShareLocationOnStart
{
    if ([AppMakrLocation applicationIsAuthorizedToUseLocationServices])
    {
        NSNumber * shareLocationBoolean = (NSNumber *)[[NSUserDefaults standardUserDefaults]valueForKey:@"post_comment_share_location"];
        return  (shareLocationBoolean !=nil)?[shareLocationBoolean boolValue]:YES;
    }
    else
    {
        return NO;
    }
}

-(void)updateViewWithNewLocation: (MKUserLocation*)userLocation
{
    CLLocation * newLocation = userLocation.location;
    
    if (newLocation) {
        
        [mapOfUserLocation setFitLocation: newLocation.coordinate withSpan: [CommentMapView coordinateSpan]];    
        
        // this creates a MKReverseGeocoder to find a placemark using the found coordinates
        MKReverseGeocoder *geoCoder = [[MKReverseGeocoder alloc] initWithCoordinate:newLocation.coordinate];
        geoCoder.delegate = self;
        [geoCoder start];
    }
}

-(void)setUserLocationTextLabel:(NSString*) userLoaction
{
    if (shareLocation) {
        
        self.locationText.text = userLoaction;
        self.locationText.font = [UIFont fontWithName:@"Helvetica" size:12.0];
        self.locationText.textColor = [UIColor colorWithRed:(35.0/255) green:(130.0/255) blue:(210.0/255) alpha:1];
        
    }
    else {

        self.locationText.text = @"Location will not be shared.";
        self.locationText.font = [UIFont fontWithName:@"Helvetica-Oblique" size:12.0];
        self.locationText.textColor = [UIColor colorWithRed:(167.0/255) green:(167.0/255) blue:(167.0/255) alpha:1];

    }
}

-(void)configureDoNotShareLocationButton
{   
    UIImage * normalImage = [[UIImage imageNamed:@"socialize-comment-button.png"]stretchableImageWithLeftCapWidth:14 topCapHeight:0] ;
    UIImage * highlightImage = [[UIImage imageNamed:@"socialize-comment-button-active.png"]stretchableImageWithLeftCapWidth:14 topCapHeight:0];
    
    [self.doNotShareLocationButton setBackgroundImage:normalImage forState:UIControlStateNormal];
	[self.doNotShareLocationButton setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
    
}

-(void)setShareLocation:(BOOL)enableLocation {
    
    shareLocation = enableLocation;
    if (shareLocation) {
        
        //TODO:: move this in separate method due to unit testing.
        if (![AppMakrLocation applicationIsAuthorizedToUseLocationServices])
        {
            UIAlertView * locationNotEnabledAlert = [[[UIAlertView alloc] initWithTitle:nil 
                                                      message:@"Please Turn On Location Services in Settings to Allow This Application to Share Your Location." 
                                                                             delegate:nil 
                                                                    cancelButtonTitle:@"OK" 
                                                                    otherButtonTitles:nil] autorelease];
            
            [locationNotEnabledAlert show];
            
            return;
        }
       
        [activateLocationButton setImage:[UIImage imageNamed:@"socialize-comment-location-enabled.png"] forState:UIControlStateNormal];
        [activateLocationButton setImage:[UIImage imageNamed:@"socialize-comment-location-enabled.png"] forState:UIControlStateHighlighted];
        
    }
    else
    {
                
        [activateLocationButton setImage:[UIImage imageNamed:@"socialize-comment-location-disabled.png"] forState:UIControlStateNormal];
        [activateLocationButton setImage:[UIImage imageNamed:@"socialize-comment-location-disabled.png"] forState:UIControlStateHighlighted];
        
    }
    


    [self setUserLocationTextLabel: nil];
}

#pragma mark - Buttons actions

-(IBAction)activateLocationButtonPressed:(id)sender
{
    if (shareLocation)
    {
        if (kbListener.isVisible) 
        {
            
            [commentTextView resignFirstResponder];          
        }
        else
        {
            [commentTextView becomeFirstResponder];
        }            
    }
    else
    {
        [self setShareLocation:YES];
    }
}

-(IBAction)doNotShareLocationButtonPressed:(id)sender
{  
    [self setShareLocation:NO];
    [commentTextView becomeFirstResponder];
}

#pragma mark - navigation bar button actions
-(void)sendButtonPressed:(id)button {

    NSNumber* latitude = [NSNumber numberWithFloat:mapOfUserLocation.userLocation.location.coordinate.latitude];
    NSNumber* longitude = [NSNumber numberWithFloat:mapOfUserLocation.userLocation.location.coordinate.longitude];
    
    _loadingIndicatorView = [LoadingView loadingViewInView:commentTextView]; //TODO:: probably it should be pushed in separate method
    [_socialize createCommentForEntityWithKey:_entityUrlString comment:commentTextView.text longitude:longitude latitude:latitude];
}

-(void)closeButtonPressed:(id)button {
    [_loadingIndicatorView removeView];_loadingIndicatorView = nil;
    [self dismissModalViewControllerAnimated:YES];
    
}

#pragma mark - SocializeServiceDelegate

-(void)service:(SocializeService *)service didFail:(NSError *)error{

    [_loadingIndicatorView removeView]; _loadingIndicatorView = nil;
    //TODO:: decide what to do with allert.
    UIAlertView *msg = [[UIAlertView alloc] initWithTitle:@"Error occurred" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [msg show];
    [msg release];
    
}

-(void)service:(SocializeService *)service didCreate:(id<SocializeObject>)object{
    
    [_loadingIndicatorView removeView];_loadingIndicatorView = nil;
    [self dismissModalViewControllerAnimated:YES];
    
}

#pragma mark - UITextViewDelegate callbacks

-(void)textViewDidChange:(UITextView *)textView {
    if ([commentTextView.text length] > 0) 
      self.navigationItem.rightBarButtonItem.enabled = YES;     
    else
      self.navigationItem.rightBarButtonItem.enabled = NO;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"New Comment";
    
    UIButton * closeButton = [UIButton blackSocializeNavBarButtonWithTitle:@"Cancel"];
    [closeButton addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem * leftButtonItem = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
    
    self.navigationItem.leftBarButtonItem = leftButtonItem;
    [leftButtonItem release];
    
    UIButton * sendButton = [UIButton blueSocializeNavBarButtonWithTitle:@"Send"];
    [sendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem * rightButtonItem = [[UIBarButtonItem alloc] initWithCustomView:sendButton];
    rightButtonItem.enabled = NO;
    
    self.navigationItem.rightBarButtonItem = rightButtonItem;
    [rightButtonItem release];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.commentTextView becomeFirstResponder];    
    [self setShareLocation:[self shouldShareLocationOnStart]];
    
    [mapOfUserLocation configurate];
    [self configureDoNotShareLocationButton];       
    [self updateViewWithNewLocation: mapOfUserLocation.userLocation];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSUserDefaults standardUserDefaults]setValue:[NSNumber numberWithBool:shareLocation] forKey:@"post_comment_share_location"];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    self.commentTextView = nil;
    self.locationText = nil;
    self.doNotShareLocationButton = nil;
    self.activateLocationButton = nil;
    self.mapOfUserLocation = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Map View Delegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    [self updateViewWithNewLocation:userLocation];
}

#pragma mark - Reverse geo coder delegate
- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark 
{   
    [self setUserLocationTextLabel: [NSString stringWithPlacemark:placemark]];
  
    geocoder.delegate = nil;
    [geocoder autorelease];
}

// this delegate is called when the reversegeocoder fails to find a placemark
- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error {
    NSLog(@"reverseGeocoder:%@ didFailWithError:%@", geocoder, error);
    geocoder.delegate = nil;
    [geocoder autorelease];
}

@end
