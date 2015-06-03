//
//  MGMPlayer.h
//  YouView
//
//  Created by Mr. Gecko on 10/15/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

extern NSString * const MGMILObject;
extern NSString * const MGMILURL;
extern NSString * const MGMILID;
extern NSString * const MGMILPath;

@class MGMBackgroundView, MGMURLConnectionManager, MGMVideoFinder, QTMovieView, QTMovie, MGMController, MGMPlayerTracking, MGMPlayerControls;

@interface MGMPlayer : NSObject {
	BOOL player;
	IBOutlet NSWindow *mainWindow;
	IBOutlet MGMBackgroundView *mainView;
	IBOutlet NSWindow *fullScreenWindow;
	IBOutlet MGMBackgroundView *fullScreenView;
	IBOutlet MGMPlayerControls *controlsView;
	IBOutlet NSWindow *controlsWindow;
	IBOutlet NSView *browserView;
	IBOutlet NSView *movieView;
	MGMController *controller;
	//Essentials
	NSMutableDictionary *currentQuery;
	NSString *nextPageToken;
	NSString *prevPageToken;
	NSArray *resultsArray;
	IBOutlet NSTableView *resultsTable;
	IBOutlet NSSearchField *searchBox;
	IBOutlet NSProgressIndicator *progressIndecator;
	IBOutlet NSSegmentedControl *nextPrevious;
	IBOutlet NSTextField *foundResults;
	IBOutlet NSTextField *page;
	NSLock *loaderLock;
    MGMURLConnectionManager *connectionManager;
	MGMURLConnectionManager *imageLoaderManager;
	int totalResults;
	int start;
	int resultsCount;
	NSString *query;
	IBOutlet NSButton *loginButton;
	//Message
	NSTimer *messageTimer;
	NSMutableArray *messages;
	IBOutlet NSTextField *messageField;
	//Order
	IBOutlet NSMenuItem *relevance;
	IBOutlet NSMenuItem *published;
	IBOutlet NSMenuItem *viewCount;
	IBOutlet NSMenuItem *rating;
	
	//Movie View
	NSURL *entry;
    NSString *title;
	MGMVideoFinder *videoFinder;
	IBOutlet QTMovieView *moviePlayer;
	IBOutlet MGMPlayerTracking *PlayerTracking;
	BOOL FullScreen;
	BOOL resized;
	NSRect windowFrame;
	NSRect windowContentFrame;
	BOOL movieOpen;
	BOOL moviePlaying;
	BOOL transitioning;
	NSTimer *updateControlsTimer;
}
+ (id)playerWithVideo:(NSURL *)theVideo controller:(MGMController *)theController player:(BOOL)isPlayer;
- (id)initWithVideo:(NSURL *)theVideo controller:(MGMController *)theController player:(BOOL)isPlayer;
- (NSWindow *)mainWindow;
- (NSWindow *)fullScreenWindow;
- (NSWindow *)controlsWindow;
- (MGMPlayerControls *)controlsView;
- (MGMPlayerTracking *)playerTracking;
- (QTMovieView *)moviePlayer;
- (void)setResults:(NSArray *)theResults;
- (NSArray *)results;
- (int)resultsCount;
- (NSTableView *)resultsTable;
- (int)totalResults;
- (int)start;
- (BOOL)player;
- (BOOL)isMovieOpen;
- (BOOL)isMoviePlaying;
- (BOOL)isFullScreen;
- (NSURL *)entry;
- (NSString *)title;
- (void)startProgress;
- (void)stopProgress;
- (void)startImageLoader;
- (void)reloadRecentSearches;
- (IBAction)clearRecentSearches:(id)sender;
- (IBAction)setOrderBy:(id)sender;
- (void)reloadData;
- (void)search;
- (IBAction)nextPrevious:(id)sender;
- (void)addMessage:(NSString *)message;
- (void)messageTimer;
- (void)removeAllMessages;
- (IBAction)openVideo:(id)sender;
- (IBAction)openVideoReverse:(id)sender;
- (void)openMovie:(NSURL *)theVideo;
- (void)closeMovie;
- (void)loop;
- (void)goFullScreen;
- (void)updateControls;
- (void)controlWithKeyEvent:(NSEvent *)theEvent;
- (void)setTitle;
@end

@interface MGMFullScreenWindow : NSWindow {
	IBOutlet MGMPlayer *player;
}

@end

@interface MGMResultsTable : NSTableView {
	IBOutlet MGMPlayer *player;
}

@end

@interface MGMBottomControl : NSView {
	
}

@end

@interface MGMPlayerTracking : NSView {
	IBOutlet MGMPlayer *player;
	NSTrackingRectTag rolloverTrackingRectTag;
	NSTimer *hideCursorTimer;
	BOOL wasAcceptingMouseEvents;
	
	BOOL fadeIn;
	NSTimer *fadeTimer;
	BOOL controls;
	BOOL playerEntered;
	NSTimer *controlsTimer;
}
- (void)releaseTimers;
- (void)resetTracking;
- (void)hideCursorNow;
- (void)controlsEntered;
- (void)controlsExited;
@end

@interface QTMovie (MGMAdditions)
- (QTTime)maxTimeLoaded;
- (NSArray *)loadedRanges;
- (long)loadState;
@end

@interface MGMPlayerControls : NSView {
	IBOutlet MGMPlayer *player;
	NSTrackingRectTag rolloverTrackingRectTag;
	BOOL wasAcceptingMouseEvents;
	
	//Controls
	NSRect VCMuteR;
	NSRect VCPlayR;
	NSRect durationR;
	NSRect currentTimeR;
	NSRect VCFullScreenR;
	NSRect VCSizeR;
	NSRect VCPositionR;
	NSRect VCBarRect;
	
	BOOL inBar;
	BOOL resizing;
	float lastVolume;
}
- (void)resetTracking;
@end

@interface MGMControlsWindow : NSWindow {
	IBOutlet MGMPlayerControls *playerControls;
}

@end

@interface MGMBackgroundView : NSView {
	NSColor *backgroundColor;
}
- (void)setBackgroundColor:(NSColor *)theColor;
- (NSColor *)backgroundColor;
@end