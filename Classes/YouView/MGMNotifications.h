//
//  MGMNotifications.h
//  YouView
//
//  Created by Mr. Gecko on 11/11/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGMNotifications : NSObject {

}
+ (void)startNotifications;
+ (void)stopNotifications;
- (void)distributedNotifications:(NSNotification *)notification;
- (void)selfNotifications:(NSNotification *)notification;
@end
