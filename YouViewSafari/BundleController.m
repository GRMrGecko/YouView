//
//  BundleController.m
//  YouView Safari
//
//  Created by Mr. Gecko on 3/1/09.
//  Copyright 2009 Mr. Gecko's Media. All rights reserved.
//

#import "BundleController.h"
#import "urlCheck.h"
#import "Safari.h"

@implementation BundleController
static BundleController *sharedController = nil;

+ (BundleController*)sharedController {
    @synchronized(self) {
        if (sharedController == nil) {
            [[self alloc] init];
        }
    }
    return sharedController;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedController == nil) {
            sharedController = [super allocWithZone:zone];
            return sharedController;
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (unsigned)retainCount {
    return UINT_MAX;
}

- (void)release {
    // do nothing
}

- (id)autorelease {
    return self;
}

- (id)init {
	self = [super init];
	if (self != nil) {
		// Safari?
		if (!([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.Safari"] || [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"org.webkit.nightly.WebKit"]))
			return nil;
		
		// The magic happens here!
		// poseAsClass is deprecated, so we should use method_setImplementation
		set_webView_resource_willSendRequest_redirectResponse_fromDataSource_dataSource_original(method_setImplementation(class_getInstanceMethod([LoadProgressMonitor class], @selector(webView:resource:willSendRequest:redirectResponse:fromDataSource:)), (IMP)webView_resource_willSendRequest_redirectResponse_fromDataSource_dataSource_override));
	}
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finnishedLaunching) name:NSApplicationDidFinishLaunchingNotification object:nil];
	return self;
}
- (void)finnishedLaunching {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	// Find the first separator on the Safari menu…
    NSMenu *applicationSubmenu = [[[NSApp mainMenu] itemAtIndex:0] submenu];
    for (int i=0; i < [applicationSubmenu numberOfItems]; i++) {
        if ([[applicationSubmenu itemAtIndex:i] isSeparatorItem]) {
			YouViewMenu = [[NSMenuItem alloc] initWithTitle:([defaults boolForKey:@"YVDisabled"] ? @"Enable YouView" : @"Disable YouView") action:@selector(able:) keyEquivalent:@""];
			[YouViewMenu setTarget:self];
			[applicationSubmenu insertItem:YouViewMenu atIndex:i];
            break;
		}
    }
}
- (IBAction)able:(id)sender {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:@"YVDisabled"]) {
		[defaults setBool:NO forKey:@"YVDisabled"];
		[YouViewMenu setTitle:@"Disable YouView"];
	} else {
		[defaults setBool:YES forKey:@"YVDisabled"];
		[YouViewMenu setTitle:@"Enable YouView"];
	}
}
@end
