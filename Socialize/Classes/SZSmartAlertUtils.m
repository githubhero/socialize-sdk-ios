//
//  SZSmartAlertUtils.m
//  SocializeSDK
//
//  Created by Nathaniel Griswold on 6/4/12.
//  Copyright (c) 2012 Socialize, Inc. All rights reserved.
//

#import "SZSmartAlertUtils.h"
#import "_Socialize.h"

@implementation SZSmartAlertUtils

+ (BOOL)handleNotification:(NSDictionary*)userInfo {
    return [Socialize handleNotification:userInfo];
}

+ (BOOL)isSocializeNotification:(NSDictionary*)userInfo {
    return [Socialize isSocializeNotification:userInfo];
}

+ (void)registerDeviceToken:(NSData*)deviceToken {
    [Socialize registerDeviceToken:deviceToken];
}

@end
