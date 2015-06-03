//
//  MGMGeneralPane.m
//  YouView
//
//  Created by Mr. Gecko on 7/29/10.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import "MGMGeneralPane.h"
#import "MGMController.h"

@implementation MGMGeneralPane
- (id)initWithPreferences:(MGMPreferences *)thePreferences {
    if (self = [super initWithPreferences:thePreferences]) {
        if (![NSBundle loadNibNamed:@"GeneralPane" owner:self]) {
            NSLog(@"Unable to load Nib for General Preferences");
            [self release];
            self = nil;
        } else {
            [maxQuality selectCellAtRow:0 column:[preferences integerForKey:MGMMaxQuality]];
            [windowMode selectCellAtRow:0 column:[preferences integerForKey:MGMWindowMode]];
			[animationsButton setState:([preferences boolForKey:MGMAnimations] ? NSOnState : NSOffState)];
			[FSFloatButton setState:([preferences boolForKey:MGMFSFloat] ? NSOnState : NSOffState)];
			[FSSpacesButton setState:([preferences boolForKey:MGMFSSpaces] ? NSOnState : NSOffState)];
            [pageMax setIntValue:[preferences integerForKey:MGMPageMax]];
        }
    }
    return self;
}
- (void)dealloc {
	[mainView release];
    [super dealloc];
}
+ (void)setUpToolbarItem:(NSToolbarItem *)theItem {
    [theItem setLabel:[self title]];
    [theItem setPaletteLabel:[theItem label]];
    [theItem setImage:[NSImage imageNamed:@"General"]];
}
+ (NSString *)title {
    return @"General";
}
- (NSView *)preferencesView {
    return mainView;
}
- (IBAction)saveVideoQuality:(id)sender {
    [preferences setInteger:[maxQuality selectedColumn] forKey:MGMMaxQuality];
}
- (IBAction)saveWindowMode:(id)sender {
    [preferences setInteger:[windowMode selectedColumn] forKey:MGMWindowMode];
}
- (IBAction)saveAnimations:(id)sender {
	[preferences setBool:([animationsButton state]==NSOnState) forKey:MGMAnimations];
}
- (IBAction)saveFSFloat:(id)sender {
	[preferences setBool:([FSFloatButton state]==NSOnState) forKey:MGMFSFloat];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGMFSSettingsNotification object:nil];
}
- (IBAction)saveFSSpaces:(id)sender {
	[preferences setBool:([FSSpacesButton state]==NSOnState) forKey:MGMFSSpaces];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGMFSSettingsNotification object:nil];
}
- (IBAction)save:(id)sender {
	int max = [pageMax intValue];
	if (max<=0)
		max = [preferences integerForKey:MGMPageMax];
	[pageMax setIntValue:max];
	[preferences setInteger:max forKey:MGMPageMax];
}
@end
