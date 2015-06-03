//
//  MGMGradient.m
//  YouView
//
//  Created by Mr. Gecko on 1/28/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import "MGMGradient.h"
#import "MGMController.h"
#import <GeckoReporter/GeckoReporter.h>

@implementation MGMGradient
- (void)awakeFromNib {
	[self setIntercellSpacing:NSMakeSize(0.0, 0.0)];
	
	NSTableColumn *column = [[self tableColumns] objectAtIndex:0];
	MGMTextCell *theTextCell = [[MGMTextCell new] autorelease];
	[column setDataCell:theTextCell];
	[[column dataCell] setFont:[NSFont labelFontOfSize:[NSFont labelFontSize]]];
}
- (void)dealloc {
#if releaseDebug
	MGMLog(@"%s Releasing", __PRETTY_FUNCTION__);
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}
- (void)highlightSelectionInClipRect:(NSRect)clipRect {
	int selectedRow = [self selectedRow];
	if(selectedRow == -1)
		return;
	[self lockFocus];
	NSImage *bgImg;
	if([[self window] firstResponder]==self && [[self window] isKeyWindow]) {
		bgImg = [NSImage imageNamed:@"gradient"];
	} else {
		bgImg = [NSImage imageNamed:@"gradientDeselected"];
	}
	
	NSRect drawingRect = [self rectOfRow:selectedRow];
	NSSize bgSize = [bgImg size];
	int i = 0;
	for (i = drawingRect.origin.x; i < (drawingRect.origin.x + drawingRect.size.width); i += bgSize.width) {
		[bgImg drawInRect:NSMakeRect(i, drawingRect.origin.y, bgSize.width, drawingRect.size.height)
				 fromRect:NSMakeRect(0, 0, bgSize.width, bgSize.height)
				operation:NSCompositeSourceOver
				 fraction:1.0];
	}
	[self unlockFocus];
}

- (void)viewWillDraw {
	if ([[self window] isKeyWindow]) {
		[self setBackgroundColor:[NSColor colorWithCalibratedRed:0.863389 green:0.892058 blue:0.9205 alpha:1.0]];
	} else {
		[self setBackgroundColor:[NSColor colorWithCalibratedRed:0.929412 green:0.929412 blue:0.929412 alpha:1.0]];
	}
}
@end

@implementation MGMTextCell
- (id)init {
	self = [super init];
	if (self != nil) {
		[self setWraps:NO];
	}
	return self;
}
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	[controlView lockFocus];
	
	NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:[[self attributedStringValue] attributesAtIndex:0 effectiveRange:NULL]];
	
	cellFrame.size.width += 10;
	
	if ([self isHighlighted]) {
		[attrs setObject:[NSFont boldSystemFontOfSize:[[self font] pointSize]] forKey:NSFontAttributeName];
		[attrs setValue:[NSColor whiteColor] forKey:@"NSColor"];
	} else {
		[attrs setObject:[self font] forKey:NSFontAttributeName];
	}
	
	NSRect inset = [self drawingRectForBounds:cellFrame];
	inset.origin.x += 4;
	inset.size.width-=inset.origin.x;
	NSString *displayString = [self truncateString:[self stringValue] forWidth:inset.size.width andAttributes:attrs];
	
	[displayString drawAtPoint:inset.origin withAttributes:attrs];
	
	[controlView unlockFocus];
}

- (NSString*)truncateString:(NSString *)string forWidth:(double) inWidth andAttributes:(NSDictionary*)inAttributes {
	unichar  ellipsesCharacter = 0x2026;
	NSString* ellipsisString = [NSString stringWithCharacters:&ellipsesCharacter length:1];
	
	NSString* truncatedString = [NSString stringWithString:string];
	int truncatedStringLength = [truncatedString length];
	
	if ((truncatedStringLength > 2) && ([truncatedString sizeWithAttributes:inAttributes].width > inWidth)) {
		double targetWidth = inWidth - [ellipsisString sizeWithAttributes:inAttributes].width;
		NSCharacterSet* whiteSpaceCharacters = [NSCharacterSet 
												whitespaceAndNewlineCharacterSet];
		
		while([truncatedString sizeWithAttributes:inAttributes].width > targetWidth && truncatedStringLength) {
			truncatedStringLength--;
			while ([whiteSpaceCharacters characterIsMember:[truncatedString characterAtIndex:(truncatedStringLength -1)]]) {
				truncatedStringLength--;
			}
			
			truncatedString = [truncatedString substringToIndex:truncatedStringLength];
		}
		
		truncatedString = [truncatedString stringByAppendingString:ellipsisString];
	}
	
	return truncatedString;
}

- (NSRect)drawingRectForBounds:(NSRect)theRect {
	NSRect newRect = [super drawingRectForBounds:theRect];
	
	NSSize textSize = [self cellSizeForBounds:theRect];
	
	float heightDelta = newRect.size.height - textSize.height;	
	if (heightDelta > 0) {
		newRect.size.height -= heightDelta;
		newRect.origin.y += (heightDelta / 2);
	}
	newRect.size.width -= 1;
	
	return newRect;
}
@end