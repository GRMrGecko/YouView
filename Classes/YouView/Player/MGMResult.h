//
//  MGMResult.h
//  YouView
//
//  Created by Mr. Gecko on 4/25/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MGMResult : NSObject {
	NSDictionary *item;
	IBOutlet NSView *mainView;
	IBOutlet NSImageView *previewView;
	IBOutlet NSTextField *titleField;
	IBOutlet NSTextField *descriptionField;
	IBOutlet NSTextField *authorField;
	IBOutlet NSTextField *addedField;
}
+ (id)resultWithItem:(NSDictionary *)video;
- (id)initWithItem:(NSDictionary *)video;
- (NSView *)view;
- (NSURL *)entry;
- (NSDictionary *)item;
- (void)loadImage;
- (void)setImage:(NSImage *)image;
- (NSImage *)image;
@end