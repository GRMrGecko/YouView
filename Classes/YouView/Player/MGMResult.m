//
//  MGMResult.m
//  YouView
//
//  Created by Mr. Gecko on 4/25/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import "MGMResult.h"
#import "MGMAddons.h"
#import "MGMController.h"
#import <MGMUsers/MGMUsers.h>
#import <GeckoReporter/GeckoReporter.h>

@implementation MGMResult
+ (id)resultWithItem:(NSDictionary *)video {
	return [[[self alloc] initWithItem:video] autorelease];
}
- (id)initWithItem:(NSDictionary *)video {
	if (self = [super init]) {
        if (![NSBundle loadNibNamed:@"MGMResultView" owner:self]) {
            [self release];
            self = nil;
        } else {
            NSLog(@"%@", video);
			item = [video retain];
			[self loadImage];
			NSDictionary *snippet = [item objectForKey:@"snippet"];
			[titleField setStringValue:[snippet objectForKey:@"title"]];
			[descriptionField setStringValue:[snippet objectForKey:@"description"]];
			NSString *author = [snippet objectForKey:@"channelTitle"];
			if ([author isEqual:@""]) {
				author = [snippet objectForKey:@"channelId"];
			}
			[authorField setStringValue:author];
			
			NSString *published = [snippet objectForKey:@"publishedAt"];
			NSRange dotRange = [published rangeOfString:@"."];
			if (dotRange.location!=NSNotFound) {
				published = [published substringToIndex:dotRange.location];
			}
			NSDateFormatter *formatter = [NSDateFormatter new];
			[formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
			[formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];//2015-03-14T01:45:20.000Z
			NSDate *date = [formatter dateFromString:published];
			[formatter setTimeZone:[NSTimeZone localTimeZone]];
			[formatter setDateFormat:@"M/dd/yy hh:mm:ss a"];
			NSString *formattedDate = [formatter stringFromDate:date];
			if (formattedDate!=nil)
				[addedField setStringValue:formattedDate];
		}
    }
    return self;
}
- (void)dealloc {
#if releaseDebug
	MGMLog(@"%s Releasing", __PRETTY_FUNCTION__);
#endif
	[item release];
	[mainView removeFromSuperview];
	[mainView release];
	[super dealloc];
}
- (NSView *)view {
	return mainView;
}
- (NSString *)accessibilityRole {
	return @"video";
}
- (NSString *)accessibilityDescription {
	return @"";
}
- (NSDictionary *)item {
	return item;
}
- (NSURL *)entry {
	return [NSURL URLWithString:[NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@", [[item objectForKey:@"id"] objectForKey:@"videoId"]]];
}

- (void)loadImage {
	NSString *imagePath = [[[MGMUser cachePath] stringByAppendingPathComponent:[[item objectForKey:@"id"] objectForKey:@"videoId"]] stringByAppendingPathExtension:@"tiff"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
		[self setImage:[[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease]];
	}
}
- (void)setImage:(NSImage *)image {
	[previewView setImage:image];
	[previewView setHidden:NO];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:MGMAnimations]) {
		NSMutableDictionary *animationInfo = [NSMutableDictionary dictionary];
		[animationInfo setObject:previewView forKey:NSViewAnimationTargetKey];
		[animationInfo setObject:NSViewAnimationFadeInEffect forKey:NSViewAnimationEffectKey];
		NSViewAnimation *animation = [[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:animationInfo]] autorelease];
		[animation setDuration:1.0];
		[animation startAnimation];
	}
}
- (NSImage *)image {
	return [previewView image];
}
@end