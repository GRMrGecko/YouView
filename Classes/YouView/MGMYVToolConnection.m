//
//  MGMYVToolConnection.m
//  YouView
//
//  Created by Mr. Gecko on 5/28/10.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import "MGMYVToolConnection.h"
#import "MGMYVToolProtocol.h"
#import "MGMAdminAction.h"

@implementation MGMYVToolConnection
+ (id)connectionWithAuthorization:(AuthorizationRef)theAuthorization {
	return [[[self alloc] initWithAuthorization:theAuthorization] autorelease];
}
- (id)initWithAuthorization:(AuthorizationRef)theAuthorization {
	if (self = [super init]) {
		adminAction = [MGMAdminAction new];
		if (theAuthorization!=NULL)
			[adminAction setAuthorization:theAuthorization];
		[adminAction launchCommand:[[NSBundle mainBundle] pathForResource:@"YVTool" ofType:@""] withArguments:[NSArray arrayWithObject:[NSString stringWithFormat:@"%d", [[NSProcessInfo processInfo] processIdentifier]]]];
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
		[self connectToServer];
	}
	return self;
}
- (void)dealloc {
#if releaseDebug
	NSLog(@"%s Releasing", __PRETTY_FUNCTION__);
#endif
	[self disconnectFromServer];
	[adminAction release];
	[yvToolConnection release];
	[super dealloc];
}

- (void)connectToServer {
	[yvToolConnection release];
	yvToolConnection = [[NSConnection connectionWithRegisteredName:@"MGMYVServer" host:nil] retain];
	if (yvToolConnection==nil) {
		NSLog(@"Couldn't connect to YVTool server.");
		return;
	}
	[yvTool release];
	yvTool = [[yvToolConnection rootProxy] retain];
	if (yvTool==nil) {
		NSLog(@"Couldn't set proxy with YVTool server.");
		[yvToolConnection release];
		yvToolConnection = nil;
		return;
	}
	[yvTool setProtocolForProxy:@protocol(MGMYVToolProtocol)];
}
- (void)disconnectFromServer {
	@try {
		[yvTool quit];
		[yvTool release];
		yvTool = nil;
		[yvToolConnection release];
		yvToolConnection = nil;
	}
	@catch (NSException * e) {
		NSLog(@"Couldn't disconnect.");
	}
}
- (BOOL)isServerConnected {
	return (yvToolConnection!=nil);
}

- (id<MGMYVToolProtocol>)server {
	if (![self isServerConnected]) {
		[self connectToServer];
	}
	return yvTool;
}
@end