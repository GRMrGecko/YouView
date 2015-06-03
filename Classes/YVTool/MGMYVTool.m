//
//  MGMYVTool.m
//  YouView
//
//  Created by Mr. Gecko on 7/29/10.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import "MGMYVTool.h"

@implementation MGMYVTool
- (id)initWithPid:(pid_t)thePid {
	if (self = [super init]) {
		parentProcessId = thePid;
		shutdownCheck = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkProcess) userInfo:nil repeats:YES] retain];
	}
	return self;
}
- (void)dealloc {
	[shutdownCheck invalidate];
	[shutdownCheck release];
	[super dealloc];
}
- (void)checkProcess {
	ProcessSerialNumber psn;
	if (GetProcessForPID(parentProcessId, &psn) == procNotFound) {
		exit(0);
	}
}
- (void)shouldQuit {
	exit(0);
}

- (void)changePremissionsForPath:(NSString *)thePath to:(NSString *)thePermissions {
	NSTask *task = [[NSTask new] autorelease];
	[task setLaunchPath:@"/bin/chmod"];
	[task setArguments:[NSArray arrayWithObjects:thePermissions, thePath, nil]];
	[task launch];
	[task waitUntilExit];
}
- (void)changeOwnerForPath:(NSString *)thePath to:(NSString *)theOwner {
	NSTask *task = [[NSTask new] autorelease];
	[task setLaunchPath:@"/usr/sbin/chown"];
	[task setArguments:[NSArray arrayWithObjects:theOwner, thePath, nil]];
	[task launch];
	[task waitUntilExit];
}

- (void)quit {
	[shutdownCheck invalidate];
	[shutdownCheck release];
	shutdownCheck = [[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(shouldQuit) userInfo:nil repeats:NO] retain];
}
@end
