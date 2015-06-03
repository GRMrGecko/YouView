//
//  MGMAdminAction.h
//  YouView
//
//  Created by Mr. Gecko on 3/25/08.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Security/Authorization.h>
#import <Security/AuthorizationTags.h>

@interface MGMAdminAction : NSObject {
	AuthorizationRef authorization;
	BOOL authorizationSetByUs;
}
- (void)setAuthorization:(AuthorizationRef)theAuthorization;
+ (AuthorizationRights)rightsForCommands:(NSArray *)theCommands;
- (BOOL)isAuthenticated:(NSArray *)theCommands;
- (BOOL)fetchPassword:(NSArray *)theCommands;
- (BOOL)authenticate:(NSArray *)theCommands;
- (NSString *)executeCommand:(NSString *)pathToCommand withArguments:(NSArray *)arguments;
- (void)launchCommand:(NSString *)thePath withArguments:(NSArray *)theArguments;
@end
