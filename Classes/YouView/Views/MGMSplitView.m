//
//  splitView.m
//  YouView
//
//  Created by Mr. Gecko on 1/23/09.
//  Copyright (c) 2010 Mr. Gecko's Media (James Coleman). All rights reserved. https://mrgeckosmedia.com/
//

#import "MGMSplitView.h"

@implementation MGMSplitView
- (CGFloat)dividerThickness {
	return 1.0;
}
- (void)drawDividerInRect:(NSRect)aRect {
	[[NSColor lightGrayColor] set];
	NSRectFill (aRect);
}
@end
