//
//  MGMPlayer.m
//  YouView
//
//  Created by Mr. Gecko on 10/15/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import "MGMPlayer.h"
#import "MGMAddons.h"
#import "MGMVideoFinder.h"
#import "MGMController.h"
#import "MGMParentalControls.h"
#import "MGMViewCell.h"
#import "MGMResult.h"
#import <MGMUsers/MGMUsers.h>
#import <GeckoReporter/GeckoReporter.h>

NSString * const MGMILObject = @"object";
NSString * const MGMILURL = @"url";
NSString * const MGMILID = @"id";
NSString * const MGMILPath = @"path";

@implementation MGMPlayer
+ (id)playerWithVideo:(NSURL *)theVideo controller:(MGMController *)theController player:(BOOL)isPlayer {
	return [[[self alloc] initWithVideo:theVideo controller:theController player:isPlayer] autorelease];
}
- (id)initWithVideo:(NSURL *)theVideo controller:(MGMController *)theController player:(BOOL)isPlayer {
	if (self = [super init]) {
		if (![NSBundle loadNibNamed:@"MGMPlayer" owner:self]) {
			[self release];
			self = nil;
		} else {
			player = isPlayer;
			controller = [theController retain];
			if (!player) {
				[self setResults:nil];
				start = 0;
			}
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FSSettingsChanged) name:MGMFSSettingsNotification object:nil];
			if (!player) {
				loaderLock = [NSLock new];
				connectionManager = [[MGMURLConnectionManager manager] retain];
				[connectionManager setUserAgent:MGMUserAgent];
				imageLoaderManager = [[MGMURLConnectionManager manager] retain];
				[imageLoaderManager setUserAgent:MGMUserAgent];
                [[[resultsTable tableColumns] objectAtIndex:0] setDataCell:[[MGMViewCell new] autorelease]];
				[resultsTable setTarget:self];
				[resultsTable setDoubleAction:@selector(openVideo:)];
				[nextPrevious setEnabled:NO forSegment:0];
				[nextPrevious setEnabled:NO forSegment:1];
				[self reloadRecentSearches];
				
				[browserView setFrame:[mainView frame]];
				[mainView addSubview:browserView];
				
				[mainWindow makeKeyAndOrderFront:self];
				[mainWindow makeFirstResponder:searchBox];
				
				NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
				[notificationCenter addObserver:self selector:@selector(loggedIn:) name:MGMUserStartNotification object:nil];
				[notificationCenter addObserver:self selector:@selector(loggedOut:) name:MGMUserDoneNotification object:nil];
				[notificationCenter addObserver:self selector:@selector(reloadRecentSearches) name:MGMRecentSearchesChangeNotification object:nil];
			} else {
				[browserView release];
				browserView = nil;
				[mainWindow setFrameAutosaveName:@""];
				[mainWindow makeKeyAndOrderFront:self];
				[mainWindow setContentSize:NSMakeSize(320, 240)];
				[mainWindow center];
			}
			if (theVideo!=nil) {
				[self openMovie:theVideo];
			}
		}
	}
	return self;
}

- (void)dealloc {
#if releaseDebug
	MGMLog(@"%s Releasing", __PRETTY_FUNCTION__);
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[controller release];
	[browserView removeFromSuperview];
	[browserView release];
	[mainWindow release];
	[resultsArray release];
	[loaderLock release];
	[imageLoaderManager release];
	[query release];
	[messageTimer invalidate];
	[messageTimer release];
	[messages release];
	[movieView removeFromSuperview];
	[movieView release];
	[fullScreenWindow release];
	[controlsWindow release];
	[videoFinder release];
	[entry release];
	[updateControlsTimer invalidate];
	[updateControlsTimer release];
	[super dealloc];
}

- (NSWindow *)mainWindow {
	return (FullScreen ? fullScreenWindow : mainWindow);
}
- (NSWindow *)fullScreenWindow {
	return fullScreenWindow;
}
- (NSWindow *)controlsWindow {
	return controlsWindow;
}

- (MGMPlayerControls *)controlsView {
	return controlsView;
}

- (MGMPlayerTracking *)playerTracking {
	return PlayerTracking;
}

- (QTMovieView *)moviePlayer {
	return moviePlayer;
}

- (void)setResults:(NSArray *)theResults {
	[loaderLock lock];
	[imageLoaderManager cancelAll];
	[loaderLock unlock];
	
	[resultsArray release];
	resultsArray = nil;
	if (theResults==nil) {
		resultsArray = [NSArray new];
	} else {
		resultsArray = [theResults retain];
	}
	resultsCount = [resultsArray count];
	[self reloadData];
}

- (NSArray *)results {
	return [NSArray arrayWithArray:resultsArray];
}

- (int)resultsCount {
	return resultsCount;
}

- (NSTableView *)resultsTable {
	return resultsTable;
}

- (int)totalResults {
	return totalResults;
}

- (int)start {
	return start;
}

- (BOOL)player {
	return player;
}

- (BOOL)isMovieOpen {
	return movieOpen;
}
- (BOOL)isMoviePlaying {
	if (movieOpen) {
		return ([[moviePlayer movie] rate]!=0);
	}
	return NO;
}

- (BOOL)isFullScreen {
	return FullScreen;
}

- (NSURL *)entry {
	if (movieOpen) {
		return entry;
	} else if (resultsCount!=0 && [resultsTable isRowSelected:[resultsTable selectedRow]]) {
        return [[resultsArray objectAtIndex:[resultsTable selectedRow]] entry];
    }
	return nil;
}

- (NSString *)title {
    if (movieOpen) {
		return title;
	} else if (resultsCount!=0 && [resultsTable isRowSelected:[resultsTable selectedRow]]) {
        return [[[[resultsArray objectAtIndex:[resultsTable selectedRow]] item] objectForKey:@"snippet"] objectForKey:@"title"];
    }
	return nil;
}

- (void)startProgress {
	[progressIndecator startAnimation:self];
}
- (void)stopProgress {
	[progressIndecator stopAnimation:self];
}

- (void)startImageLoader {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	[loaderLock lock];
	NSString *cachePath = [MGMUser cachePath];
	NSFileManager *manager = [NSFileManager defaultManager];
	for (int i=0; i<resultsCount; i++) {
		MGMResult *result;
		@synchronized(resultsArray) {
			result = [resultsArray objectAtIndex:i];
		};
		if (result!=nil && ![manager fileExistsAtPath:[[cachePath stringByAppendingPathComponent:[[result entry] URLParameterWithName:@"v"]] stringByAppendingPathExtension:@"tiff"]]) {
			[self performSelectorOnMainThread:@selector(loadImageForResult:) withObject:result waitUntilDone:NO];
		}
	}
	[loaderLock unlock];
	[pool drain];
}
- (void)loadImageForResult:(MGMResult *)theResult {
	NSString *imagePath = [[[MGMUser cachePath] stringByAppendingPathComponent:[[theResult entry] URLParameterWithName:@"v"]] stringByAppendingPathExtension:@"tiff"];
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:theResult, MGMILObject, [NSString stringWithFormat:MGMYTImageURL, [[theResult entry] URLParameterWithName:@"v"]], MGMILURL, [[theResult entry] URLParameterWithName:@"v"], MGMILID, imagePath, MGMILPath, nil];
#if youviewdebug
	MGMLog(@"ID: %@", [info objectForKey:MGMILID]);
	MGMLog(@"URL: %@", [info objectForKey:MGMILURL]);
#endif
	NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[info objectForKey:MGMILURL]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
	MGMURLBasicHandler *handler = [MGMURLBasicHandler handlerWithRequest:theRequest delegate:self];
	[handler setFailWithError:@selector(imageLoader:didFailWithError:)];
	[handler setFinish:@selector(imageLoaderDidFinish:)];
	[handler setObject:info];
	[imageLoaderManager addHandler:handler];
}
- (void)imageLoader:(MGMURLBasicHandler *)theHandler didFailWithError:(NSError *)theError {
	NSLog(@"Error loading image: %@ %@", [[theHandler object] objectForKey:MGMILURL], theError);
}
- (void)imageLoaderDidFinish:(MGMURLBasicHandler *)theHandler {
	NSDictionary *info = [theHandler object];
	NSImage *image = [[[NSImage alloc] initWithData:[theHandler data]] autorelease];
	if (image!=nil) {
		[[image TIFFRepresentation] writeToFile:[info objectForKey:MGMILPath] atomically:YES];
	}
	[[info objectForKey:MGMILObject] performSelectorOnMainThread:@selector(loadImage) withObject:nil waitUntilDone:NO];
}

- (void)reloadRecentSearches {
	[searchBox setRecentSearches:[controller recentSearches]];
}
- (IBAction)clearRecentSearches:(id)sender {
	[controller clearRecentSearches];
}
- (IBAction)setOrderBy:(id)sender {
	[controller setOrder:[sender tag]];
}
- (void)reloadData {
	while ([[resultsTable subviews] count] > 0) {
		[[[resultsTable subviews] lastObject] removeFromSuperviewWithoutNeedingDisplay];
	}
	
	[resultsTable reloadData];
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return resultsCount;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return nil;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	[(MGMViewCell *)cell addSubview:[resultsArray objectAtIndex:row]];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
#if youviewdebug
	MGMLog(@"%@", NSStringFromSelector(commandSelector));
#endif
	if (commandSelector == @selector(insertNewline:)) {
		[self search];
		return YES;
	} else if (commandSelector == @selector(moveDown:)) {
		[resultsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
		[mainWindow makeFirstResponder:resultsTable];
		return YES;
	}
	return NO;
}

- (void)search {
	NSString *search = [searchBox stringValue];
	[controller addRecentSearch:search];
	start = 0;
	[self setResults:nil];
	[nextPrevious setEnabled:NO forSegment:0];
	[nextPrevious setEnabled:NO forSegment:1];
	[self startProgress];
	[self removeAllMessages];
	[self addMessage:@"Searching YouTube"];
    NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
    [arguments setObject:@"id,snippet" forKey:@"part"];
    [arguments setObject:@"video" forKey:@"type"];
    [arguments setObject:[[[NSUserDefaults standardUserDefaults] objectForKey:MGMPageMax] stringValue] forKey:@"maxResults"];
    [arguments setObject:[controller orderBy] forKey:@"order"];
    [arguments setObject:[[MGMParentalControls standardParentalControls] stringForKey:MGMSafeSearch] forKey:@"safeSearch"];
    [arguments setObject:search forKey:@"q"];
	[currentQuery release];
	currentQuery = [arguments retain];
    NSURL *searchURL = [controller generateAPIURL:@"search" arguments:arguments];
    MGMURLBasicHandler *handler = [MGMURLBasicHandler handlerWithRequest:[NSURLRequest requestWithURL:searchURL] delegate:self];
    [connectionManager addHandler:handler];
	[query release];
	query = [search retain];
}

- (IBAction)nextPrevious:(id)sender {
	[self setResults:nil];
	[self startProgress];
	[self removeAllMessages];
	if ([nextPrevious selectedSegment]==0) {
		[self addMessage:@"Going back one page"];
		[currentQuery setObject:prevPageToken forKey:@"pageToken"];
		NSURL *searchURL = [controller generateAPIURL:@"search" arguments:currentQuery];
		MGMURLBasicHandler *handler = [MGMURLBasicHandler handlerWithRequest:[NSURLRequest requestWithURL:searchURL] delegate:self];
		[connectionManager addHandler:handler];	
	} else {
		[self addMessage:@"Going to next page"];
		[currentQuery setObject:nextPageToken forKey:@"pageToken"];
		NSURL *searchURL = [controller generateAPIURL:@"search" arguments:currentQuery];
		MGMURLBasicHandler *handler = [MGMURLBasicHandler handlerWithRequest:[NSURLRequest requestWithURL:searchURL] delegate:self];
		[connectionManager addHandler:handler];
	}
}

- (void)handler:(MGMURLBasicHandler *)theHandler didFailWithError:(NSError *)theError {
	MGMLog(@"Error %@", theError);
    NSAlert *theAlert = [[NSAlert new] autorelease];
    [theAlert addButtonWithTitle:@"OK"];
    [theAlert setMessageText:@"YouView Error"];
    [theAlert setInformativeText:[theError localizedDescription]];
    [theAlert setAlertStyle:NSWarningAlertStyle];
    [theAlert runModal];
    [self stopProgress];
}
- (void)handlerDidFinish:(MGMURLBasicHandler *)theHandler {
	[self stopProgress];
	NSDictionary *data = [[theHandler data] parseJSON];
    if ([data objectForKey:@"error"]!=nil) {
		NSLog(@"%@", data);
		NSAlert *theAlert = [[NSAlert new] autorelease];
		[theAlert addButtonWithTitle:@"OK"];
		[theAlert setMessageText:@"YouView Error"];
		[theAlert setInformativeText:[data objectForKey:@"message"]];
		[theAlert setAlertStyle:NSWarningAlertStyle];
		[theAlert runModal];
        return;
    }
	
	nextPageToken = [data objectForKey:@"nextPageToken"];
	[nextPrevious setEnabled:(nextPageToken!=nil) forSegment:1];
	prevPageToken = [data objectForKey:@"prevPageToken"];
	[nextPrevious setEnabled:(prevPageToken!=nil) forSegment:0];
	
	NSArray *items = [data objectForKey:@"items"];
	
	NSMutableArray *restuls = [NSMutableArray array];
	for (long i=0; i<[items count]; i++) {
		[restuls addObject:[MGMResult resultWithItem:[items objectAtIndex:i]]];
	}
	[self setResults:restuls];
	[NSThread detachNewThreadSelector:@selector(startImageLoader) toTarget:self withObject:nil];
}

- (void)addMessage:(NSString *)message {
	if (messages==nil) {
		messages = [NSMutableArray new];
	}
	[messages addObject:message];
	if (messageTimer==nil) {
		[messageField setStringValue:[messages objectAtIndex:0]];
		messageTimer = [[NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(messageTimer) userInfo:nil repeats:YES] retain];
	}
}
- (void)messageTimer {
	[messages removeObjectAtIndex:0];
	if ([messages count]==0) {
		[messageTimer invalidate];
		[messageTimer release];
		messageTimer = nil;
		[messages release];
		messages = nil;
		[messageField setStringValue:@""];
	} else {
		[messageField setStringValue:[messages objectAtIndex:0]];
	}
}
- (void)removeAllMessages {
	if (messageTimer!=nil) {
		[messageTimer invalidate];
		[messageTimer release];
		messageTimer = nil;
	}
	if (messages!=nil) {
		[messages release];
		messages = nil;
	}
	[messageField setStringValue:@""];
}

- (IBAction)openVideo:(id)sender {
    if ([[NSUserDefaults standardUserDefaults] integerForKey:MGMWindowMode]==0) {
        [self openMovie:[self entry]];
    } else {
        [controller openVideo:[self entry]];
    }
}

- (IBAction)openVideoReverse:(id)sender {
    if ([[NSUserDefaults standardUserDefaults] integerForKey:MGMWindowMode]==1) {
        [self openMovie:[self entry]];
    } else {
        [controller openVideo:[self entry]];
    }
}

- (void)openMovie:(NSURL *)theVideo {
	[videoFinder release];
	videoFinder = [[MGMVideoFinder alloc] initWithURL:theVideo connectionManager:nil maxQuality:[[[NSUserDefaults standardUserDefaults] objectForKey:MGMMaxQuality] intValue] delegate:self];
	
	[movieView setFrame:[mainView frame]];
	[mainView addSubview:movieView];
	[entry release];
	entry = [theVideo retain];
	moviePlaying = NO;
	movieOpen = YES;
	[mainWindow setShowsResizeIndicator:NO];
	if (!player) {
		transitioning = YES;
		[mainWindow makeFirstResponder:PlayerTracking];
		[movieView setHidden:NO];
		if ([[NSUserDefaults standardUserDefaults] boolForKey:MGMAnimations]) {
			NSMutableDictionary *animationInfo = [NSMutableDictionary dictionary];
			[animationInfo setObject:movieView forKey:NSViewAnimationTargetKey];
			[animationInfo setObject:NSViewAnimationFadeInEffect forKey:NSViewAnimationEffectKey];
			NSViewAnimation *animation = [[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:animationInfo]] autorelease];
			[animation setDuration:1];
			[animation setDelegate:self];
			[animation startAnimation];
		} else {
			[browserView removeFromSuperview];
			transitioning = NO;
		}
	}
}

- (void)closeMovie {
	movieOpen = NO;
	if (!player) {
		[mainWindow setShowsResizeIndicator:YES];
		[browserView setFrame:[mainView frame]];
		[mainView addSubview:browserView positioned:NSWindowBelow relativeTo:nil];
		transitioning = YES;
		[mainWindow makeFirstResponder:resultsTable];
	}
	[[moviePlayer movie] stop];
	if (videoFinder!=nil) {
		[videoFinder release];
		videoFinder = nil;
	}
	[moviePlayer setMovie:nil];
	[mainWindow removeChildWindow:controlsWindow];
	[controlsWindow orderOut:self];
	if (updateControlsTimer!=nil) {
		[updateControlsTimer invalidate];
		[updateControlsTimer release];
		updateControlsTimer = nil;
	}
	
	if (!player) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:MGMAnimations]) {
			NSMutableDictionary *animationInfo = [NSMutableDictionary dictionary];
			[animationInfo setObject:movieView forKey:NSViewAnimationTargetKey];
			[animationInfo setObject:NSViewAnimationFadeOutEffect forKey:NSViewAnimationEffectKey];
			NSViewAnimation *animation = [[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:animationInfo]] autorelease];
			[animation setDuration:1];
			[animation setDelegate:self];
			[animation startAnimation];
		} else {
			[movieView removeFromSuperview];
			[self setTitle];
		}
	} else {
		[mainWindow performClose:self];
	}
}

- (void)loop {
	QTMovie *theMovie = [moviePlayer movie];
	if ([[theMovie attributeForKey:QTMovieLoopsAttribute] boolValue]) {
		[theMovie setAttribute:[NSNumber numberWithBool:NO] forKey:QTMovieLoopsAttribute];
	} else {
		[theMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieLoopsAttribute];
	}
}

- (void)FSSettingsChanged {
	if (FullScreen) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[fullScreenWindow setLevel:([defaults boolForKey:MGMFSFloat] ? NSMainMenuWindowLevel : NSNormalWindowLevel)];
		if ([fullScreenWindow respondsToSelector:@selector(setCollectionBehavior:)]) {
			[fullScreenWindow setCollectionBehavior:([defaults boolForKey:MGMFSSpaces] ? NSWindowCollectionBehaviorCanJoinAllSpaces : NSWindowCollectionBehaviorDefault)];
		}
	}
}

- (void)goFullScreen {
	if (movieOpen && moviePlaying) {
		if (FullScreen) {
			FullScreen = NO;
			[controller playerBecameKey:self];
			[mainWindow setFrame:windowFrame display:YES];
			float alpha = [controlsWindow alphaValue];
			[controlsWindow setAlphaValue:0.0];
			[fullScreenWindow setHasShadow:YES];
			[fullScreenWindow setFrame:windowContentFrame display:YES animate:[[NSUserDefaults standardUserDefaults] boolForKey:MGMAnimations]];
			[mainView setBackgroundColor:[NSColor blackColor]];
			[mainWindow makeKeyAndOrderFront:self];
			[mainView addSubview:movieView];
			[movieView setFrame:[mainView frame]];
			[fullScreenWindow removeChildWindow:controlsWindow];
			[mainWindow addChildWindow:controlsWindow ordered:NSWindowAbove];
			[controlsWindow display];
			[controlsWindow setAlphaValue:alpha];
			[fullScreenWindow orderOut:self];
			[mainView setBackgroundColor:[NSColor clearColor]];
			[PlayerTracking hideCursorNow];
			[PlayerTracking resetTracking];
			[mainWindow makeFirstResponder:PlayerTracking];
		} else {
			FullScreen = YES;
			windowFrame = [mainWindow frame];
			windowContentFrame = [mainWindow contentRectForFrameRect:windowFrame];
			[controller playerBecameKey:self];
			[fullScreenWindow setFrame:windowContentFrame display:YES];
			[fullScreenView setBackgroundColor:[NSColor blackColor]];
			[fullScreenWindow makeKeyAndOrderFront:self];
			[fullScreenView addSubview:movieView];
			[movieView setFrame:[fullScreenView frame]];
			[fullScreenView display];
			[mainWindow removeChildWindow:controlsWindow];
			float alpha = [controlsWindow alphaValue];
			[controlsWindow setAlphaValue:0.0];
			[fullScreenWindow setFrame:[[mainWindow screen] frame] display:YES animate:[[NSUserDefaults standardUserDefaults] boolForKey:MGMAnimations]];
			[fullScreenView setBackgroundColor:[NSColor clearColor]];
			[mainWindow orderOut:self];
			[fullScreenWindow addChildWindow:controlsWindow ordered:NSWindowAbove];
			[controlsWindow display];
			[controlsWindow setAlphaValue:alpha];
			[PlayerTracking hideCursorNow];
			[PlayerTracking resetTracking];
			[fullScreenWindow makeFirstResponder:PlayerTracking];
			[fullScreenWindow setHasShadow:NO];
			[self FSSettingsChanged];
		}
	}
}

- (void)loadFlash:(NSDictionary *)theInfo {
	NSAlert *theAlert = [[NSAlert new] autorelease];
	[theAlert setMessageText:@"Video Loading"];
	[theAlert setInformativeText:@"YouView was unable to load the video, would you like to load the low quality version with Perian.org?"];
	[theAlert addButtonWithTitle:@"Yes"];
	[theAlert addButtonWithTitle:@"No"];
	int result = [theAlert runModal];
	if (result==1000) {
		[videoFinder loadFlash];
	}
}
- (void)loadVideo:(NSDictionary *)theInfo {
    [title release];
	title = [[theInfo objectForKey:MGMVLTitle] retain];
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:[NSNumber numberWithBool:YES] forKey:@"QTMovieOpenForPlaybackAttribute"];
	[attributes setObject:[theInfo objectForKey:MGMVLVideoURLKey] forKey:QTMovieURLAttribute];
	QTMovie *theMovie = [QTMovie movieWithAttributes:attributes error:nil];
	if (theMovie==nil) {
		NSAlert *theAlert = [[NSAlert new] autorelease];
		[theAlert addButtonWithTitle:@"Ok"];
		[theAlert setMessageText:@"Error while finding video"];
		[theAlert setInformativeText:@"Could not create video."];
		[theAlert setAlertStyle:2];
		[theAlert runModal];
	} else {
		[theMovie autoplay];
		[moviePlayer setMovie:theMovie];
		[self setTitle];
		[controlsWindow setAlphaValue:0.0];
		[mainWindow addChildWindow:controlsWindow ordered:NSWindowAbove];
		[PlayerTracking hideCursorNow];
		[PlayerTracking resetTracking];
		[controlsWindow display];
		[updateControlsTimer invalidate];
		[updateControlsTimer release];
		updateControlsTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateControls) userInfo:nil repeats:YES] retain];
	}
}

- (void)updateControls {
	if ([[moviePlayer movie] loadState]==-1L) {
		[moviePlayer setMovie:nil];
		if (updateControlsTimer!=nil) {
			[updateControlsTimer invalidate];
			[updateControlsTimer release];
			updateControlsTimer = nil;
		}
		if ([[videoFinder version] isEqual:@"FLV"]) {
			NSAlert *theAlert = [[NSAlert new] autorelease];
			[theAlert addButtonWithTitle:@"OK"];
			[theAlert setMessageText:@"Video Loading"];
			[theAlert setInformativeText:@"YouView was unable to load low quality video."];
			[theAlert runModal];
		} else {
			[videoFinder shouldLoadFlash];
		}
	}
	if ([[moviePlayer movie] loadState]>=10000) {
		if (player && !FullScreen && !resized) {
			[mainWindow setContentSize:[[[moviePlayer movie] attributeForKey:QTMovieNaturalSizeAttribute] sizeValue]];
			[mainWindow center];
			[PlayerTracking resetTracking];
			resized = YES;
		}
		moviePlaying = YES;
	}
	if ([controlsWindow alphaValue]>0) {
		[controlsView display];
	}
}

- (void)controlWithKeyEvent:(NSEvent *)theEvent {
	if (!transitioning) {
		int keyCode = [theEvent keyCode];
		//MGMLog(@"%d", keyCode);
		if (keyCode==53) {
			if (FullScreen) {
				[self goFullScreen];
			} else {
				[self closeMovie];
			}
		} else if (keyCode==49) {
			if ([[moviePlayer movie] rate] == 0) {
				[[moviePlayer movie] play];
			} else {
				[[moviePlayer movie] stop];
			}
		} else if (keyCode==124 && [theEvent modifierFlags] & NSCommandKeyMask) {
			[[moviePlayer movie] stepForward];
		} else if (keyCode==123 && [theEvent modifierFlags] & NSCommandKeyMask) {
			[[moviePlayer movie] stepBackward];
		} else if (keyCode==124 && [theEvent modifierFlags] & NSAlternateKeyMask) {
			QTTime time = [[moviePlayer movie] currentTime];
			time = QTTimeIncrement(time, QTMakeTimeWithTimeInterval(5));
			[[moviePlayer movie] setCurrentTime:time];
		} else if (keyCode==123 && [theEvent modifierFlags] & NSAlternateKeyMask) {
			QTTime time = [[moviePlayer movie] currentTime];
			time = QTTimeDecrement(time, QTMakeTimeWithTimeInterval(5));
			[[moviePlayer movie] setCurrentTime:time];
		} else if (keyCode==124) {
			QTTime time = [[moviePlayer movie] currentTime];
			time = QTTimeIncrement(time, QTMakeTimeWithTimeInterval(10));
			[[moviePlayer movie] setCurrentTime:time];
		} else if (keyCode==123) {
			QTTime time = [[moviePlayer movie] currentTime];
			time = QTTimeDecrement(time, QTMakeTimeWithTimeInterval(10));
			[[moviePlayer movie] setCurrentTime:time];
		} else if (keyCode==126) {
			double volume = [[moviePlayer movie] volume];
			if (volume!=1) {
				volume += 0.2;
			}
			[[moviePlayer movie] setVolume:volume];
		} else if (keyCode==125) {
			double volume = [[moviePlayer movie] volume];
			if (volume!=0) {
				volume -= 0.2;
			}
			[[moviePlayer movie] setVolume:volume];
		} else {
			[moviePlayer keyDown:theEvent];
		}
	}
}

- (void)animationDidEnd:(NSAnimation *)animation {
	transitioning = NO;
	if (movieOpen) {
		[browserView removeFromSuperview];
	} else {
		[movieView removeFromSuperview];
		[self setTitle];
	}
}

//Window managing
- (void)setTitle {
	if (movieOpen) {
		[mainWindow setTitle:[title flattenHTML]];
		[fullScreenWindow setTitle:[title flattenHTML]];
	} else {
		[mainWindow setTitle:@"YouView"];
		[fullScreenWindow setTitle:@"YouView"];
	}
}

- (void)windowDidMove:(NSNotification *)window {
	if (movieOpen) {
		[PlayerTracking resetTracking];
		[controlsWindow display];
	}
	[controller playerBecameKey:self];
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
	[controller playerBecameKey:self];
}

- (BOOL)windowShouldClose:(id)sender {
	if (movieOpen) {
		if (FullScreen) {
			[self goFullScreen];
		} else {
			[self closeMovie];
		}
		return NO;
	}
	if (!player) {
		if (transitioning) {
			return NO;
		}
		
		[loaderLock lock];
		[imageLoaderManager cancelAll];
		[loaderLock unlock];
		[self removeAllMessages];
	}
	return YES;
}
- (void)windowWillClose:(NSNotification *)notification {
	[PlayerTracking releaseTimers];
	[controller playerClosed:self];
}
- (void)windowDidResize:(NSNotification *)notification {
	if (movieOpen) {
		[controlsWindow display];
	}
}
@end

@implementation MGMResultsTable
- (void)mouseDown:(NSEvent *)theEvent {
	if ([theEvent modifierFlags] & NSCommandKeyMask) {
		if ([theEvent clickCount]==1) {
			NSEvent *sendEvent = [NSEvent mouseEventWithType:[theEvent type]
													location:[theEvent locationInWindow]
											   modifierFlags:NSAlternateKeyMask
												   timestamp:[theEvent timestamp]
												windowNumber:[theEvent windowNumber]
													 context:[theEvent context]
												 eventNumber:[theEvent eventNumber]
												  clickCount:[theEvent clickCount]
													pressure:[theEvent pressure]];
			[super mouseDown:sendEvent];
			[player openVideoReverse:self];
		}
	} else {
		[super mouseDown:theEvent];
	}
}
- (void)keyDown:(NSEvent *)theEvent {
	int keyCode = [theEvent keyCode];
	//MGMLog(@"%d", keyCode);
	if (keyCode==36 || keyCode==76 || keyCode==49) {
		if ([theEvent modifierFlags] & NSAlternateKeyMask) {
			[player openVideoReverse:self];
		} else {
			[player openVideo:self];
		}
	} else {
		[super keyDown:theEvent];
	}
}
@end


@implementation MGMBottomControl
- (void)drawRect:(NSRect)rect {
	NSImage *bgImg = [NSImage imageNamed:@"bar"];
	NSSize bgSize = [bgImg size];
	for (int i = rect.origin.x; i < (rect.origin.x + rect.size.width); i += bgSize.width) {
		[bgImg drawInRect:NSMakeRect(i, rect.origin.y, bgSize.width, rect.size.height)
				 fromRect:NSMakeRect(0, 0, bgSize.width, bgSize.height)
				operation:NSCompositeSourceOver
				 fraction:1.0];
	}
}
@end

@implementation MGMFullScreenWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag  {
    if (self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:flag]) {
		[self setMovableByWindowBackground:NO];
		return self;
    }
    return nil;
}

- (void)becomeKeyWindow {
	[player windowDidBecomeKey:nil];
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}
@end

@implementation MGMPlayerTracking
- (void)releaseTimers {
	if (hideCursorTimer!=nil) {
		[hideCursorTimer invalidate];
		[hideCursorTimer release];
		hideCursorTimer = nil;
	}
	if (fadeTimer!=nil) {
		[fadeTimer invalidate];
		[fadeTimer release];
		fadeTimer = nil;
	}
	if (controlsTimer!=nil) {
		[controlsTimer invalidate];
		[controlsTimer release];
		controlsTimer = nil;
	}
}
- (void)resetTracking {
	[self removeTrackingRect:rolloverTrackingRectTag];
	NSPoint screenPoint = [NSEvent mouseLocation];
	NSPoint windowPoint = [[self window] convertScreenToBase:screenPoint];
	NSPoint point = [self convertPoint:windowPoint fromView:nil];
	BOOL mouseInside = NSMouseInRect(point, [self bounds], [self isFlipped]);
	rolloverTrackingRectTag = [self addTrackingRect:[self frame] owner:self userData:NULL assumeInside:mouseInside];
	if (mouseInside) {
		playerEntered = YES;
		wasAcceptingMouseEvents = [[self window] acceptsMouseMovedEvents];
		[[self window] setAcceptsMouseMovedEvents:YES];
		[[self window] makeFirstResponder:self];
	}
	[[player controlsView] resetTracking];
}

- (void)mouseUp:(NSEvent *)theEvent {
	[self resetTracking];
	[[self window] makeFirstResponder:self];
}

- (void)mouseDown:(NSEvent *)theEvent {
	if ([[[player moviePlayer] movie] rate] == 0) {
		[[[player moviePlayer] movie] play];
	} else {
		[[[player moviePlayer] movie] stop];
	}
}

- (void)keyDown:(NSEvent *)theEvent {
	[player controlWithKeyEvent:theEvent];
}

- (void)scrollWheel:(NSEvent *)theEvent {
	[[player moviePlayer] scrollWheel:theEvent];
}

- (void)mouseEntered:(NSEvent *)theEvent {
	wasAcceptingMouseEvents = [[self window] acceptsMouseMovedEvents];
	[[self window] setAcceptsMouseMovedEvents:YES];
	[[self window] makeFirstResponder:self];
	playerEntered = YES;
}

- (void)mouseMoved:(NSEvent *)theEvent {
	if (!controls && playerEntered) {
		[hideCursorTimer invalidate];
		[hideCursorTimer release];
		hideCursorTimer = [[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(hideCursorNow) userInfo:nil repeats:NO] retain];
		if (!fadeIn) {
			[[player controlsView] display];
			fadeIn = YES;
			[fadeTimer invalidate];
			[fadeTimer release];
			fadeTimer = nil;
			if ([[NSUserDefaults standardUserDefaults] boolForKey:MGMAnimations]) {
				fadeTimer = [[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(fade:) userInfo:nil repeats:YES] retain];
			} else {
				[[player controlsWindow] setAlphaValue:1.0];
			}
		}
	}
}

- (void)mouseExited:(NSEvent *)theEvent {
	[[self window] setAcceptsMouseMovedEvents:wasAcceptingMouseEvents];
	playerEntered = NO;
	if (!controls) {
		[hideCursorTimer invalidate];
		[hideCursorTimer release];
		hideCursorTimer = nil;
		if (fadeIn) {
			fadeIn = NO;
			[fadeTimer invalidate];
			[fadeTimer release];
			fadeTimer = nil;
			if ([[NSUserDefaults standardUserDefaults] boolForKey:MGMAnimations]) {
				fadeTimer = [[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(fade:) userInfo:nil repeats:YES] retain];
			} else {
				[[player controlsWindow] setAlphaValue:0.0];
			}
		}
	}
}

- (void)hideCursorNow {
	if (fadeIn) {
		fadeIn = NO;
		[fadeTimer invalidate];
		[fadeTimer release];
		fadeTimer = nil;
		if ([[NSUserDefaults standardUserDefaults] boolForKey:MGMAnimations]) {
			fadeTimer = [[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(fade:) userInfo:nil repeats:YES] retain];
		} else {
			[[player controlsWindow] setAlphaValue:0.0];
		}
	}
	[NSCursor setHiddenUntilMouseMoves:YES];
}
- (void)fade:(NSTimer *)theTimer {
	if (fadeIn && [[player controlsWindow] alphaValue] < 1.0) {
		[[player controlsWindow] setAlphaValue:[[player controlsWindow] alphaValue] + 0.1];
	} else if (!fadeIn && [[player controlsWindow] alphaValue] > 0.0) {
		[[player controlsWindow] setAlphaValue:[[player controlsWindow] alphaValue] - 0.1];
	} else {
		[fadeTimer invalidate];
		[fadeTimer release];
		fadeTimer = nil;
	}
}
- (void)controlsEntered {
	fadeIn = YES;
	[fadeTimer invalidate];
	[fadeTimer release];
	fadeTimer = nil;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:MGMAnimations]) {
		fadeTimer = [[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(fade:) userInfo:nil repeats:YES] retain];
	} else {
		[[player controlsWindow] setAlphaValue:1.0];
	}
	if (controlsTimer!=nil) {
		[controlsTimer invalidate];
		[controlsTimer release];
		controlsTimer = nil;
	}
	controls = YES;
}
- (void)controlsExited {
	[controlsTimer invalidate];
	[controlsTimer release];
	controlsTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(controlsTimer) userInfo:nil repeats:YES] retain];
	controls = NO;
}

- (void)controlsTimer {
	if (!playerEntered) {
		fadeIn = NO;
		[fadeTimer invalidate];
		[fadeTimer release];
		fadeTimer = nil;
		if ([[NSUserDefaults standardUserDefaults] boolForKey:MGMAnimations]) {
			fadeTimer = [[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(fade:) userInfo:nil repeats:YES] retain];
		} else {
			[[player controlsWindow] setAlphaValue:0.0];
		}
	}
}
- (BOOL)acceptsFirstResponder {
	return YES;
}
@end

@implementation MGMPlayerControls
- (void)drawRect:(NSRect)rect {
	QTMovie *theMovie = [[player moviePlayer] movie];
	
	NSImage *VCControl = [NSImage imageNamed:@"VCControl"];
	NSSize VCControlS = [VCControl size];
	for (int i = rect.origin.x; i < (rect.origin.x + rect.size.width); i += VCControlS.width) {
		[VCControl drawInRect:NSMakeRect(i, 0, VCControlS.width, VCControlS.height) fromRect:NSMakeRect(0, 0, VCControlS.width, VCControlS.height) operation:NSCompositeSourceOver fraction:1.0];
	}
	
	float volume = [theMovie volume];
	NSImage *VCMute = [NSImage imageNamed:(volume<=0.0 ? @"VCUMute" : @"VCMute")];
	NSSize VCMuteS = [VCMute size];
	VCMuteR = NSMakeRect(0, (VCControlS.height-VCMuteS.height)/2, VCMuteS.width, VCMuteS.height);
	[VCMute drawInRect:VCMuteR fromRect:NSMakeRect(0, 0, VCMuteS.width, VCMuteS.height) operation:NSCompositeSourceOver fraction:1.0];
	
	NSImage *VCPlay = [NSImage imageNamed:([theMovie rate] == 0 ? @"VCPlay" : @"VCPause")];
	NSSize VCPlayS = [VCPlay size];
	VCPlayR = NSMakeRect(VCMuteR.origin.x+VCMuteR.size.width, (VCControlS.height-VCPlayS.height)/2, VCPlayS.width, VCPlayS.height);
	[VCPlay drawInRect:VCPlayR fromRect:NSMakeRect(0, 0, VCPlayS.width, VCPlayS.height) operation:NSCompositeSourceOver fraction:1.0];
	
	QTTime QTDuration = [theMovie duration];
	QTTime QTCurrentTime = [theMovie currentTime];
	
	double duration = (double)QTDuration.timeValue/QTDuration.timeScale;
	double currentTime = (double)QTCurrentTime.timeValue/QTCurrentTime.timeScale;
	
	NSString *durationString = [NSString stringWithFormat:@"-%@", [NSString stringWithSeconds:(int)duration-currentTime]];
	NSString *currentTimeString = [NSString stringWithSeconds:(int)currentTime];
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSColor whiteColor], NSForegroundColorAttributeName, [NSFont fontWithName:@"Helvetica" size:12], NSFontAttributeName, nil];
	
	NSSize currentTimeSize = [currentTimeString sizeWithAttributes:attributes];
	currentTimeR = NSMakeRect(VCPlayR.origin.x+VCPlayR.size.width, (VCControlS.height-currentTimeSize.height)/2, currentTimeSize.width+4, currentTimeSize.height);
	[currentTimeString drawInRect:currentTimeR withAttributes:attributes];
	
	if (![player isFullScreen]) {
		NSImage *VCSize = [NSImage imageNamed:@"VCSize"];
		NSSize VCSizeS = [VCSize size];
		VCSizeR = NSMakeRect(rect.size.width-VCSizeS.width, (VCControlS.height-VCSizeS.height)/2, VCSizeS.width, VCSizeS.height);
		[VCSize drawInRect:VCSizeR fromRect:NSMakeRect(0, 0, VCSizeS.width, VCSizeS.height) operation:NSCompositeSourceOver fraction:1.0];
	} else {
		VCSizeR = NSMakeRect(rect.size.width, 0, 0, 0);
	}
	
	NSImage *VCFullScreen = [NSImage imageNamed:([player isFullScreen] ? @"VCUFullScreen" : @"VCFullScreen")];
	NSSize VCFullScreenS = [VCFullScreen size];
	VCFullScreenR = NSMakeRect(VCSizeR.origin.x-VCFullScreenS.width, (VCControlS.height-VCFullScreenS.height)/2, VCFullScreenS.width, VCFullScreenS.height);
	[VCFullScreen drawInRect:VCFullScreenR fromRect:NSMakeRect(0, 0, VCFullScreenS.width, VCFullScreenS.height) operation:NSCompositeSourceOver fraction:1.0];
	
	NSSize durationSize = [durationString sizeWithAttributes:attributes];
	durationR = NSMakeRect(VCFullScreenR.origin.x-durationSize.width, (VCControlS.height-durationSize.height)/2, durationSize.width+4, durationSize.height);
	[durationString drawInRect:durationR withAttributes:attributes];
	durationR.origin.x-=4;
	
	NSImage *VCLBarL = [NSImage imageNamed:@"VCLBarL"];
	NSSize VCLBarLS = [VCLBarL size];
	NSRect VCLBarLR = NSMakeRect(currentTimeR.origin.x+currentTimeR.size.width, (VCControlS.height-VCLBarLS.height)/2, VCLBarLS.width, VCLBarLS.height);
	[VCLBarL drawInRect:VCLBarLR fromRect:NSMakeRect(0, 0, VCLBarLS.width, VCLBarLS.height) operation:NSCompositeSourceOver fraction:1.0];
	
	NSImage *VCLBarR = [NSImage imageNamed:@"VCLBarR"];
	NSSize VCLBarRS = [VCLBarR size];
	NSRect VCLBarRR = NSMakeRect(durationR.origin.x-VCLBarRS.width, (VCControlS.height-VCLBarRS.height)/2, VCLBarRS.width, VCLBarRS.height);
	[VCLBarR drawInRect:VCLBarRR fromRect:NSMakeRect(0, 0, VCLBarRS.width, VCLBarRS.height) operation:NSCompositeSourceOver fraction:1.0];
	
	NSImage *VCLBarC = [NSImage imageNamed:@"VCLBarC"];
	NSSize VCLBarCS = [VCLBarC size];
	for (int i = VCLBarLR.origin.x+VCLBarLR.size.width; i < VCLBarRR.origin.x; i += VCLBarCS.width) {
		[VCLBarC drawInRect:NSMakeRect(i, (VCControlS.height-VCLBarCS.height)/2, VCLBarCS.width, VCLBarCS.height) fromRect:NSMakeRect(0, 0, VCLBarCS.width, VCLBarCS.height) operation:NSCompositeSourceOver fraction:1.0];
	}
	
	int barSize = (VCLBarRR.origin.x-VCLBarRR.size.width)-VCLBarLR.origin.x;
	int barPosition = (int)((currentTime/duration)*barSize);
	
	NSImage *VCBarL = [NSImage imageNamed:@"VCBarL"];
	NSSize VCBarLS = [VCBarL size];
	NSRect VCBarLR = NSMakeRect(currentTimeR.origin.x+currentTimeR.size.width, (VCControlS.height-VCBarLS.height)/2, VCBarLS.width, VCBarLS.height);
	[VCBarL drawInRect:VCBarLR fromRect:NSMakeRect(0, 0, VCBarLS.width, VCBarLS.height) operation:NSCompositeSourceOver fraction:1.0];
	
	double loadedtime;
	int loadPosition = barSize;
	if ([theMovie respondsToSelector:@selector(loadedRanges)]) {
		NSArray *timeRanges = [theMovie loadedRanges];
		for (int i=0; i<[timeRanges count]; i++) {
			loadedtime = (double)[[timeRanges objectAtIndex:i] QTTimeRangeValue].duration.timeValue/[[timeRanges objectAtIndex:i] QTTimeRangeValue].duration.timeScale;
			loadPosition = (int)((loadedtime/duration)*barSize);
		}
	} else {
		QTTime loadedQTTime = [theMovie maxTimeLoaded];
		loadedtime = (double)loadedQTTime.timeValue/loadedQTTime.timeScale;
		loadPosition = (int)((loadedtime/duration)*barSize);
	}
	
	NSImage *VCBarR = [NSImage imageNamed:@"VCBarR"];
	NSSize VCBarRS = [VCBarR size];
	NSRect VCBarRR = NSMakeRect(durationR.origin.x-VCBarRS.width, (VCControlS.height-VCBarRS.height)/2, VCBarRS.width, VCBarRS.height);
	if (loadPosition==barSize) {
		[VCBarR drawInRect:VCBarRR fromRect:NSMakeRect(0, 0, VCBarRS.width, VCBarRS.height) operation:NSCompositeSourceOver fraction:1.0];
	}
	
	if (loadPosition>=(int)VCBarLR.size.width) {
		loadPosition = loadPosition+(int)(VCBarLR.origin.x+VCBarLR.size.width);
		NSImage *VCBarC = [NSImage imageNamed:@"VCBarC"];
		NSSize VCBarCS = [VCBarC size];
		for (int i = VCBarLR.origin.x+VCBarLR.size.width; i < loadPosition; i += VCBarCS.width) {
			[VCBarC drawInRect:NSMakeRect(i, (VCControlS.height-VCBarCS.height)/2, VCBarCS.width, VCBarCS.height) fromRect:NSMakeRect(0, 0, VCBarCS.width, VCBarCS.height) operation:NSCompositeSourceOver fraction:1.0];
		}
	}
	
	VCBarRect = NSMakeRect(VCLBarLR.origin.x, VCLBarLR.origin.y, barSize, VCLBarLR.size.height);
	NSImage *VCPosition = [NSImage imageNamed:@"VCPosition"];
	NSSize VCPositionS = [VCPosition size];
	VCPositionR = NSMakeRect(VCLBarLR.origin.x+barPosition, (VCControlS.height-VCPositionS.height)/2, VCPositionS.width, VCPositionS.height);
	[VCPosition drawInRect:VCPositionR fromRect:NSMakeRect(0, 0, VCPositionS.width, VCPositionS.height) operation:NSCompositeSourceOver fraction:1.0];
}

- (void)mouseDown:(NSEvent *)theEvent {
	//MGMLog(@"Down at x:%f y:%f", [theEvent locationInWindow].x, [theEvent locationInWindow].y);
	if (NSPointInRect([theEvent locationInWindow], VCSizeR)) {
		resizing = YES;
	} else if (NSPointInRect([theEvent locationInWindow], VCBarRect)) {
		inBar = YES;
		[[[player moviePlayer] movie] stop];
	}
}
- (void)mouseDragged:(NSEvent *)theEvent {
	if (resizing) {
		NSWindow *window = [[self window] parentWindow];
		NSRect windowSize = [window frame];
		NSSize maxSize = [window maxSize];
		NSSize minSize = [window minSize];
		
		float newWidth = windowSize.size.width + [theEvent deltaX];
		if (maxSize.width>=newWidth && minSize.width<=newWidth) {
			windowSize.size.width = newWidth;
		}
		float newHeight = windowSize.size.height + [theEvent deltaY];
		if (maxSize.height>=newHeight && minSize.height<=newHeight) {
			windowSize.size.height = newHeight;
			windowSize.origin.y -= [theEvent deltaY];
		}
		
		[window setFrame:windowSize display:YES];
		//MGMLog(@"Dragged at x:%f y:%f", [theEvent deltaX], [theEvent deltaY]);
	} else if (inBar) {
		QTMovie *theMovie = [[player moviePlayer] movie];
		int position = [theEvent locationInWindow].x-VCBarRect.origin.x;
		QTTime time = [theMovie duration];
		time.timeValue = (position/VCBarRect.size.width)*time.timeValue;
		[theMovie setCurrentTime:time];
	}
}
- (void)mouseUp:(NSEvent *)theEvent {
	//MGMLog(@"Up at x:%f y:%f", [theEvent locationInWindow].x, [theEvent locationInWindow].y);
	QTMovie *theMovie = [[player moviePlayer] movie];
	if (resizing) {
		resizing = NO;
	} else if (NSPointInRect([theEvent locationInWindow], VCMuteR)) {
		float volume = [theMovie volume];
		if (volume>0.0) {
			lastVolume = volume;
			[theMovie setVolume:0.0];
		} else {
			[theMovie setVolume:(lastVolume==0.0 ? 1.0 : lastVolume)];
		}
	} else if (NSPointInRect([theEvent locationInWindow], VCFullScreenR)) {
		[player goFullScreen];
	} else if (NSPointInRect([theEvent locationInWindow], VCPlayR)) {
		if ([theMovie rate] == 0) {
			[theMovie play];
		} else {
			[theMovie stop];
		}
	} else if (NSPointInRect([theEvent locationInWindow], VCBarRect)) {
		int position = [theEvent locationInWindow].x-VCBarRect.origin.x;
		QTTime time = [theMovie duration];
		time.timeValue = (position/VCBarRect.size.width)*time.timeValue;
		[theMovie setCurrentTime:time];
		[theMovie play];
		inBar = NO;
	}
	[self display];
}

- (void)resetTracking {
	[self removeTrackingRect:rolloverTrackingRectTag];
	NSPoint screenPoint = [NSEvent mouseLocation];
	NSPoint windowPoint = [[self window] convertScreenToBase:screenPoint];
	NSPoint point = [self convertPoint:windowPoint fromView:nil];
	BOOL mouseInside = NSMouseInRect(point, [self bounds], [self isFlipped]);
	rolloverTrackingRectTag = [self addTrackingRect:[self frame] owner:self userData:NULL assumeInside:mouseInside];
	if (mouseInside) {
		wasAcceptingMouseEvents = [[self window] acceptsMouseMovedEvents];
		[[self window] setAcceptsMouseMovedEvents:YES];
		[[self window] makeFirstResponder:self];
	}
}

- (void)mouseEntered:(NSEvent *)theEvent {
	[[player playerTracking] controlsEntered];
}

- (void)mouseExited:(NSEvent *)theEvent {
	[[player playerTracking] controlsExited];
	[[player playerTracking] resetTracking];
}
@end

@implementation MGMControlsWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag  {
    if (self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:flag]) {
		[self setBackgroundColor:[NSColor clearColor]];
        [self setAlphaValue:1.0];
        [self setOpaque:NO];
        [self setMovableByWindowBackground:NO];
		return self;
    }
    return nil;
}
- (void)display {
	NSRect windowSize = [[self parentWindow] frame];
	windowSize.size.height = [[NSImage imageNamed:@"VCControl"] size].height;
	[super setFrame:windowSize display:NO];
	[playerControls resetTracking];
	[super display];
}
@end

@implementation MGMBackgroundView
- (id)initWithFrame:(NSRect)frameRect {
	if (self = [super initWithFrame:frameRect]) {
		backgroundColor = [[NSColor clearColor] retain];
	}
	return self;
}
- (void)dealloc {
	[backgroundColor release];
	[super dealloc];
}
- (void)setBackgroundColor:(NSColor *)theColor {
	[backgroundColor release];
	backgroundColor = [theColor retain];
	[self display];
}
- (NSColor *)backgroundColor {
	return backgroundColor;
}
- (void)drawRect:(NSRect)rect {
	NSBezierPath *backgroundPath = [NSBezierPath bezierPathWithRect:rect];
	[backgroundColor set];
	[backgroundPath fill];
}
@end