//
//  MGMParentalControlsPane.h
//  YouView
//
//  Created by Mr. Gecko on 7/29/10.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MGMUsers/MGMUsers.h>

@class SFAuthorizationView, MGMYVToolConnection;

@interface MGMParentalControlsPane : MGMPreferencesPane {
    IBOutlet NSView *mainView;
	IBOutlet NSButton *flaggedVideo;
	IBOutlet NSMatrix *safeSearch;
	AuthorizationRights rights;
	IBOutlet SFAuthorizationView *autherizationView;
	MGMYVToolConnection *yvToolConnection;
}
- (id)initWithPreferences:(MGMPreferences *)thePreferences;
+ (void)setUpToolbarItem:(NSToolbarItem *)theItem;
+ (NSString *)title;
- (NSView *)preferencesView;
- (IBAction)saveFlaggedVideos:(id)sender;
- (IBAction)saveSafeSearch:(id)sender;
@end
