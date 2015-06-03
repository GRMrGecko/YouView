//
//  MGMViewCell.h
//  YouView
//
//  Created by Mr. Gecko on 4/15/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol MGMViewCellController <NSObject>
- (NSView *)view;
- (NSString *)accessibilityDescription;
- (NSString *)accessibilityRole;
@end

@interface MGMViewCell : NSCell {
	NSObject<MGMViewCellController> *subview;
}
- (void)addSubview:(NSObject<MGMViewCellController> *)view;
@end
