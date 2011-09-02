//
//  CommentDetailsViewController.h
//  appbuildr
//
//  Created by Sergey Popenko on 4/6/11.
//  Copyright 2011 pointabout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class CommentDetailsView;
@class URLDownload;
@protocol SocializeComment;

typedef URLDownload*(^LoaderFactory)(NSString* url, id sender, SEL selector, id tag);

@interface CommentDetailsViewController : UIViewController<MKReverseGeocoderDelegate> 
{
    @private
        MKReverseGeocoder*      geoCoder;
        CommentDetailsView*     commentDetailsView;
        id<SocializeComment>    comment;
        URLDownload*            profileImageDownloader;
        LoaderFactory           loaderFactory;
}

@property (nonatomic, retain) IBOutlet CommentDetailsView*     commentDetailsView;
@property (nonatomic, retain) id<SocializeComment>    comment;
@property (nonatomic, retain) URLDownload* profileImageDownloader;
@property (nonatomic, retain) LoaderFactory loaderFactory;

@end
