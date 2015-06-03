//
//  MGMGradient.h
//  YouView
//
//  Created by Mr. Gecko on 1/28/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGMGradient : NSOutlineView {

}

@end

@interface MGMTextCell : NSTextFieldCell {
	
}
- (NSString*)truncateString:(NSString *)string forWidth:(double) inWidth andAttributes:(NSDictionary*)inAttributes;
@end