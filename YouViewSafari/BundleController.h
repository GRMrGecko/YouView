//
//  BundleController.h
//  YouView Safari
//
//  Created by Mr. Gecko on 3/1/09.
//  Copyright 2009 Mr. Gecko's Media. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface BundleController : NSObject {
	NSMenuItem *YouViewMenu;
}
+ (BundleController*)sharedController;
+ (id)allocWithZone:(NSZone *)zone;
- (id)copyWithZone:(NSZone *)zone;
- (id)retain;
- (unsigned)retainCount;
- (void)release;
- (id)autorelease;
- (void)finnishedLaunching;
@end
