//
//  MGMYVTool.h
//  YouView
//
//  Created by Mr. Gecko on 7/29/10.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGMYVTool : NSObject {
	pid_t parentProcessId;
	NSTimer *shutdownCheck;
}
- (id)initWithPid:(pid_t)thePid;
@end
