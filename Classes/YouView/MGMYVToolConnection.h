//
//  MGMYVToolConnection.h
//  YouView
//
//  Created by Mr. Gecko on 5/28/10.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Security/Authorization.h>
#import <Security/AuthorizationTags.h>

@protocol MGMYVToolProtocol;
@class MGMAdminAction;

@interface MGMYVToolConnection : NSObject {
	MGMAdminAction *adminAction;
	id yvTool;
	NSConnection *yvToolConnection;
}
+ (id)connectionWithAuthorization:(AuthorizationRef)theAuthorization;
- (id)initWithAuthorization:(AuthorizationRef)theAuthorization;
- (void)connectToServer;
- (void)disconnectFromServer;
- (BOOL)isServerConnected;
- (id<MGMYVToolProtocol>)server;
@end