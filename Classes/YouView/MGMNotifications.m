//
//  MGMNotifications.m
//  YouView
//
//  Created by Mr. Gecko on 11/11/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import "MGMNotifications.h"

static MGMNotifications *MGMNotificationsSingleton = nil;

@implementation MGMNotifications
+ (void)startNotifications {
	@synchronized(self) {
        if (MGMNotificationsSingleton == nil) {
			MGMNotificationsSingleton = [[self alloc] init]; 
		}
    }
}
+ (void)stopNotifications {
	@synchronized(self) {
        if (MGMNotificationsSingleton != nil) {
			[MGMNotificationsSingleton release];
		}
    }
}

- (id)init {
	if (self = [super init]) {
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(distributedNotifications:) name:nil object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selfNotifications:) name:nil object:nil];
	}
	return self;
}
- (void)dealloc {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}
- (void)distributedNotifications:(NSNotification *)notification {
	NSLog(@"Distributed Notification: %@\n%@", [notification name], [notification userInfo]);
}
- (void)selfNotifications:(NSNotification *)notification {
	NSLog(@"Notification: %@\n%@", [notification name], [notification userInfo]);
}
@end
