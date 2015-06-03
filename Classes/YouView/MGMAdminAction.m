//
//  MGMAdminAction.m
//  YouView
//
//  Created by Mr. Gecko on 3/25/08.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import "MGMAdminAction.h"
#import <Security/AuthorizationTags.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/param.h>
#include <sys/socket.h>

@implementation MGMAdminAction
- (id)init {
	if (self = [super init]) {
		authorization = NULL;
		authorizationSetByUs = YES;
	}
	return self;
}
- (void)dealloc {
	if (authorization!=NULL && authorizationSetByUs)
		AuthorizationFree(authorization, kAuthorizationFlagDestroyRights);
	[super dealloc];
}

- (void)setAuthorization:(AuthorizationRef)theAuthorization {
	if (authorization!=NULL && authorizationSetByUs)
		AuthorizationFree(authorization, kAuthorizationFlagDestroyRights);
	authorization = theAuthorization;
	authorizationSetByUs = NO;
}

+ (AuthorizationRights)rightsForCommands:(NSArray *)theCommands {
	AuthorizationItem *items = malloc(sizeof(AuthorizationItem) *[theCommands count]);
	for (int i=0; i<[theCommands count]; i++) {
		items[i].name = kAuthorizationRightExecute;
		items[i].value = (char *)[[theCommands objectAtIndex:i] UTF8String];
		items[i].valueLength = [[theCommands objectAtIndex:i] length];
		items[i].flags = 0;
	}
	AuthorizationRights rights;
	rights.count = [theCommands count];
	rights.items = items;
	return rights;
}

- (AuthorizationRights)rightsForCommands:(NSArray *)theCommands {
	return [[self class] rightsForCommands:theCommands];
}

- (BOOL)isAuthenticated:(NSArray *)theCommands {
	AuthorizationRights rights;
	AuthorizationRights *authorizedRights;
	OSStatus status;
	
	if (theCommands==nil || [theCommands count]==0)
		return NO;
	
	if (authorization==NULL) {
		rights.count=0;
		rights.items = NULL;
		status = AuthorizationCreate(&rights, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorization);
	}
	
	rights = [self rightsForCommands:theCommands];
	status = AuthorizationCopyRights(authorization, &rights, kAuthorizationEmptyEnvironment, kAuthorizationFlagExtendRights, &authorizedRights);
	free(rights.items);
	
	if (status==errAuthorizationSuccess) {
		AuthorizationFreeItemSet(authorizedRights);
	}
	
	return (status==errAuthorizationSuccess);
}

- (BOOL)fetchPassword:(NSArray *)theCommands {
	if (theCommands==nil || [theCommands count]==0)
		return NO;
	
	AuthorizationRights rights = [self rightsForCommands:theCommands];
	OSStatus status = AuthorizationCopyRights(authorization, &rights, kAuthorizationEmptyEnvironment, kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights, NULL);
	free(rights.items);
	
	return (status==errAuthorizationSuccess);
}

- (BOOL)authenticate:(NSArray *)theCommands {
	if (![self isAuthenticated:theCommands]) {
		[self fetchPassword:theCommands];
	}
	return [self isAuthenticated:theCommands];
}

- (NSString *)executeCommand:(NSString *)thePath withArguments:(NSArray *)theArguments {
	char *args[30];
	int status;
	FILE *pipe = NULL;
	NSString *output = nil;
	
	if (![self authenticate:[NSArray arrayWithObject:thePath]])
		return nil;
	
	if (theArguments==nil || [theArguments count]==0) {
		args[0] = NULL;
	} else {
		for (int i=0; i<[theArguments count]; i++) {
			args[i] = (char *)[[theArguments objectAtIndex:i] UTF8String];
			args[i+1] = NULL;
		}
	}
	status = AuthorizationExecuteWithPrivileges(authorization, [thePath UTF8String], kAuthorizationFlagDefaults, args, &pipe);
	
	NSMutableData *outputData = [NSMutableData data];
	NSMutableData *tempData = [NSMutableData dataWithLength:512];
	int len;
	if (pipe!=NULL) {
		do {
			[tempData setLength:512];
			len = fread([tempData mutableBytes], 1, 512, pipe);
			if (len>0) {
				[tempData setLength:len];
				[outputData appendData:tempData];		
			}
		} while (len==512);
	}
	if ([outputData length]!=0)
		output = [[[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] autorelease];
	
	if (status!=0) {
		NSLog(@"Error %d in AuthorizationExecuteWithPrivileges", status);
	}
	
	return output;
}

- (void)launchCommand:(NSString *)thePath withArguments:(NSArray *)theArguments {
	char *args[30];
	int status;
	
	if (![self authenticate:[NSArray arrayWithObject:thePath]])
		return;
	
	if (theArguments==nil || [theArguments count]==0) {
		args[0] = NULL;
	} else {
		for (int i=0; i<[theArguments count]; i++) {
			args[i] = (char *)[[theArguments objectAtIndex:i] UTF8String];
			args[i+1] = NULL;
		}
	}
	status = AuthorizationExecuteWithPrivileges(authorization, [thePath UTF8String], kAuthorizationFlagDefaults, args, NULL);
	
	if (status!=0) {
		NSLog(@"Error %d in AuthorizationExecuteWithPrivileges", status);
	}
}
@end