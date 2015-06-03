//
//  MGMDonatePane.h
//  YouView
//
//  Created by Mr. Gecko on 7/29/10.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MGMUsers/MGMUsers.h>

extern NSString * const MGMDSalt1;
extern NSString * const MGMDSalt2;
extern NSString * const MGMDonationPath;
extern NSString * const MGMDKey;
extern NSString * const MGMDHash;
extern NSString * const MGMDName;
extern NSString * const MGMDStatus;

@interface MGMDonatePane : MGMPreferencesPane {
    IBOutlet NSView *mainView;
}
- (id)initWithPreferences:(MGMPreferences *)thePreferences;
+ (void)setUpToolbarItem:(NSToolbarItem *)theItem;
+ (NSString *)title;
- (NSView *)preferencesView;
- (IBAction)donate:(id)sender;
@end
