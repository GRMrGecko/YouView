//
//  MGMParentalControlsPane.m
//  YouView
//
//  Created by Mr. Gecko on 7/29/10.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import "MGMParentalControlsPane.h"
#import "MGMController.h"
#import "MGMParentalControls.h"
#import "MGMAdminAction.h"
#import "MGMYVToolConnection.h"
#import "MGMYVToolProtocol.h"
#import <SecurityInterface/SFAuthorizationView.h>

@implementation MGMParentalControlsPane
- (id)initWithPreferences:(MGMPreferences *)thePreferences {
    if (self = [super initWithPreferences:thePreferences]) {
        if (![NSBundle loadNibNamed:@"ParentalControlsPane" owner:self]) {
            NSLog(@"Unable to load Nib for General Preferences");
            [self release];
            self = nil;
        } else {
			rights = [MGMAdminAction rightsForCommands:[NSArray arrayWithObject:[[NSBundle mainBundle] pathForResource:@"YVTool" ofType:@""]]];
            [autherizationView setAuthorizationRights:&rights];
			[autherizationView setDelegate:self];
			[autherizationView updateStatus:self];
			[autherizationView setAutoupdate:YES];
			
			MGMParentalControls *parentalControls = [MGMParentalControls standardParentalControls];
			if ([parentalControls boolForKey:MGMAllowFlaggedVideos]) {
				[flaggedVideo setState:NSOnState];
			} else {
				[flaggedVideo setState:NSOffState];
			}
			NSString *safeSearchValue = [parentalControls stringForKey:MGMSafeSearch];
			if (safeSearchValue==nil) {
				safeSearchValue = @"moderate";
			}
			if ([safeSearchValue isEqual:@"none"])
				[safeSearch selectCellAtRow:0 column:0];
			else if ([safeSearchValue isEqual:@"moderate"])
				[safeSearch selectCellAtRow:1 column:0];
			else if ([safeSearchValue isEqual:@"strict"])
				[safeSearch selectCellAtRow:2 column:0];
			[parentalControls setString:safeSearchValue forKey:MGMSafeSearch];
			[parentalControls save];
        }
    }
    return self;
}
- (void)dealloc {
	[mainView release];
	[yvToolConnection release];
	free(rights.items);
    [super dealloc];
}
+ (void)setUpToolbarItem:(NSToolbarItem *)theItem {
    [theItem setLabel:[self title]];
    [theItem setPaletteLabel:[theItem label]];
    [theItem setImage:[NSImage imageNamed:@"ParentalControls"]];
}
+ (NSString *)title {
    return @"Parental Controls";
}
- (NSView *)preferencesView {
    return mainView;
}

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view {
	if (yvToolConnection==nil)
		yvToolConnection = [[MGMYVToolConnection connectionWithAuthorization:[[autherizationView authorization] authorizationRef]] retain];
	[yvToolConnection isServerConnected];
	[flaggedVideo setEnabled:YES];
	[safeSearch setEnabled:YES];
}
- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view {
	[flaggedVideo setEnabled:NO];
	[safeSearch setEnabled:NO];
}

- (IBAction)saveFlaggedVideos:(id)sender {
	if ([autherizationView authorizationState]==SFAuthorizationViewUnlockedState) {
		MGMParentalControls *parentalControls = [MGMParentalControls standardParentalControls];
		[[yvToolConnection server] changePremissionsForPath:[parentalControls path] to:@"666"];
		[parentalControls setBool:([flaggedVideo state]==NSOnState) forKey:MGMAllowFlaggedVideos];
		[[yvToolConnection server] changePremissionsForPath:[parentalControls path] to:@"644"];
		[[yvToolConnection server] changeOwnerForPath:[parentalControls path] to:@"root"];
	}
}
- (IBAction)saveSafeSearch:(id)sender {
	if ([autherizationView authorizationState]==SFAuthorizationViewUnlockedState) {
		MGMParentalControls *parentalControls = [MGMParentalControls standardParentalControls];
		[[yvToolConnection server] changePremissionsForPath:[parentalControls path] to:@"666"];
		NSString *safeSearchValue = @"strict";
		if ([safeSearch selectedRow]==0)
			safeSearchValue = @"none";
		else if ([safeSearch selectedRow]==1)
			safeSearchValue = @"moderate";
		[parentalControls setString:safeSearchValue forKey:MGMSafeSearch];
		[[yvToolConnection server] changePremissionsForPath:[parentalControls path] to:@"644"];
		[[yvToolConnection server] changeOwnerForPath:[parentalControls path] to:@"root"];
	}
}
@end
