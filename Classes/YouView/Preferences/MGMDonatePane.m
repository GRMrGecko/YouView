//
//  MGMDonatePane.m
//  YouView
//
//  Created by Mr. Gecko on 7/29/10.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import "MGMDonatePane.h"
#import "MGMController.h"

NSString * const MGMDSalt1 = @"lll3jh653k";
NSString * const MGMDSalt2 = @"jgsllwi32l5";
NSString * const MGMDonationPath = @".info.plist";
NSString * const MGMDKey = @"key";
NSString * const MGMDHash = @"hash";
NSString * const MGMDName = @"name";
NSString * const MGMDStatus = @"status";

@implementation MGMDonatePane
- (id)initWithPreferences:(MGMPreferences *)thePreferences {
    if (self = [super initWithPreferences:thePreferences]) {
        if (![NSBundle loadNibNamed:@"DonatePane" owner:self]) {
            NSLog(@"Unable to load Nib for Donate Preferences");
            [self release];
            self = nil;
        } else {

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
    [theItem setImage:[NSImage imageNamed:@"Donate"]];
}
+ (NSString *)title {
    return @"Donate";
}
- (NSView *)preferencesView {
    return mainView;
}

- (IBAction)donate:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://mrgeckosmedia.com/donate?purpose=youview"]];
}
@end
