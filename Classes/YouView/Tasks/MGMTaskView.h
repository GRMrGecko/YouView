//
//  MGMTaskView.h
//  YouView
//
//  Created by Mr. Gecko on 4/16/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGMURLConnectionManager, MGMVideoFinder, MGMTaskManager;

@interface MGMTaskView : NSObject {
	MGMTaskManager *manager;
	IBOutlet NSView *mainView;
	IBOutlet NSImageView *icon;
	IBOutlet NSTextField *name;
	IBOutlet NSProgressIndicator *progress;
	IBOutlet NSTextField *info;
	IBOutlet NSButton *stop;
	IBOutlet NSButton *restart;
	NSMutableDictionary *taskInfo;
	NSURL *entry;
	
	MGMURLConnectionManager *connectionManager;
	MGMVideoFinder *videoFinder;
	
	int startTime;
	int bytesReceivedSec;
	int bytesReceived;
	NSTimer *secCheckTimer;
	NSString *receivedSec;
    int receivedContentLength;
    int expectedContentLength;
	
	NSTask *aTask;
	NSPipe *taskPipe;
	double time;
	double videoPlayTime;
	double videoFrameRate;
	BOOL waitingToConvert;
	BOOL converting;
	BOOL working;
	BOOL stopped;
}
+ (id)taskViewWithTask:(NSDictionary *)theTask withVideo:(NSURL *)theVideo manager:(MGMTaskManager *)theManager;
- (id)initWithTask:(NSDictionary *)theTask withVideo:(NSURL *)theVideo manager:(MGMTaskManager *)theManager;
- (void)setName;
- (NSString *)YVTaskPath;
- (BOOL)working;
- (BOOL)converting;
- (BOOL)waitingToConvert;
- (NSView *)view;
- (NSString *)bytesToString:(double)bytes;
- (NSString *)secsToString:(int)secs;
- (void)convertProcessFinish:(NSNotification *)note;
- (void)convertProcessResponse:(NSString*)response;
- (void)convertProcessRead:(NSNotification *)note;
- (IBAction)stop:(id)sender;
- (IBAction)reveal:(id)sender;
- (IBAction)restart:(id)sender;
- (void)saveInfo;
- (void)startConverson;
@end