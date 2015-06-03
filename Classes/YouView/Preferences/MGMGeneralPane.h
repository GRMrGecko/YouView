//
//  MGMGeneralPane.h
//  YouView
//
//  Created by Mr. Gecko on 7/29/10.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MGMUsers/MGMUsers.h>

@interface MGMGeneralPane : MGMPreferencesPane {
    IBOutlet NSView *mainView;
    IBOutlet NSMatrix *maxQuality;
    IBOutlet NSMatrix *windowMode;
	IBOutlet NSButton *animationsButton;
	IBOutlet NSButton *FSFloatButton;
	IBOutlet NSButton *FSSpacesButton;
    IBOutlet NSTextField *pageMax;
}
- (id)initWithPreferences:(MGMPreferences *)thePreferences;
+ (void)setUpToolbarItem:(NSToolbarItem *)theItem;
+ (NSString *)title;
- (NSView *)preferencesView;
- (IBAction)saveVideoQuality:(id)sender;
- (IBAction)saveWindowMode:(id)sender;
- (IBAction)saveAnimations:(id)sender;
- (IBAction)saveFSFloat:(id)sender;
- (IBAction)saveFSSpaces:(id)sender;
- (IBAction)save:(id)sender;
@end
