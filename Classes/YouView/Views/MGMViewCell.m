//
//  MGMViewCell.m
//  YouView
//
//  Created by Mr. Gecko on 4/15/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import "MGMViewCell.h"
#import "MGMController.h"
#import <GeckoReporter/GeckoReporter.h>

@implementation MGMViewCell
- (void)addSubview:(NSObject<MGMViewCellController> *)view {
	subview = view;
}
- (void)dealloc {
#if releaseDebug
	MGMLog(@"%s Releasing", __PRETTY_FUNCTION__);
#endif
	subview = nil;
	[super dealloc];
}
- (NSView *)view {
	return [subview view];
}

- (NSArray *)accessibilityAttributeNames {
    NSMutableArray *names = [[[super accessibilityAttributeNames] mutableCopy] autorelease];
    [names addObject:NSAccessibilityEnabledAttribute];
    [names addObject:NSAccessibilityDescriptionAttribute];
    [names addObject:NSAccessibilityRoleAttribute];
    return names;
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityDescriptionAttribute]) {
		if ([subview respondsToSelector:@selector(accessibilityDescription)])
			return [subview accessibilityDescription];
    } else if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
		if ([subview respondsToSelector:@selector(accessibilityRole)])
			return [subview accessibilityRole];
    } else if ([attribute isEqualToString:NSAccessibilityEnabledAttribute]) {
		return [NSNumber numberWithBool:YES];
    } else {
		return [super accessibilityAttributeValue:attribute];
    }
	return @"";
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityDescriptionAttribute] || [attribute isEqualToString:NSAccessibilityRoleAttribute]) {
		return NO;
    } else {
		return [super accessibilityIsAttributeSettable:attribute];
    }
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	[super drawWithFrame:cellFrame inView:controlView];
	
	[[self view] setFrame:cellFrame];
	
    if ([[self view] superview] != controlView) {
		[controlView addSubview:[self view]];
	}
}
@end
