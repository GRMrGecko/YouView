//
//  main.m
//  YouView
//
//  Created by Mr. Gecko on 7/29/10.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGMYVTool.h"

MGMYVTool *yvServer;

int main(int argc, char *argv[]) {
	NSAutoreleasePool * pool = [NSAutoreleasePool new];
	yvServer = [[MGMYVTool alloc] initWithPid:atoi(argv[1])];
	
	NSConnection *theYVServer = [NSConnection new];
	
	if(theYVServer==nil) {
		NSLog(@"Server couldn't start");
		exit(1);
	}
	
	[theYVServer setRootObject:yvServer];
	[theYVServer registerName:@"MGMYVServer"];
	[theYVServer setDelegate:yvServer];
	
	NSLog(@"Server Started");
	
	[[NSRunLoop currentRunLoop] run];
	[yvServer release];
	[theYVServer release];
	[pool release];
	return 0;
}