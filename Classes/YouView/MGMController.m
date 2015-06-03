//
//  Controller.m
//  YouView
//
//  Created by Mr. Gecko on 1/17/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import "MGMController.h"
#import "MGMAddons.h"
#import "MGMPlayer.h"
#import "MGMTaskManager.h"
#import "MGMParentalControls.h"
#import "MGMDonatePane.h"
#import "AppleRemote.h"
#import "KeyspanFrontRowControl.h"
#import "GlobalKeyboardDevice.h"
#import "RemoteControlContainer.h"
#import "MultiClickRemoteBehavior.h"
#import <Carbon/Carbon.h>
#import <WebKit/WebKit.h>
#import <QTKit/QTKit.h>
#import <CoreServices/CoreServices.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#import <MGMUsers/MGMUsers.h>
#import <GeckoReporter/GeckoReporter.h>

NSString * const MGMCopyright = @"Copyright (c) 2010 Mr. Gecko's Media (James Coleman). All rights reserved. https://mrgeckosmedia.com/";

NSString * const MGMYTAPIKey = @"KEY";

NSString * const MGMUserAgent = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:39.0) Gecko/20100101 Firefox/39.0";

NSString * const MGMVersion = @"MGMVersion";

NSString * const MGMSafeSearch = @"safeSearch";
NSString * const MGMAllowFlaggedVideos = @"allowFlaggedVideos";
NSString * const MGMRecentSearchesChangeNotification = @"MGMRecentSearchesChangeNotification";
NSString * const MGMRecentSearches = @"recentSearches";

NSString * const MGMSubscriptionFile = @"subscriptions.plist";

NSString * const MGMIAuthor = @"%AUTHOR%";
NSString * const MGMITitle = @"%TITLE%";
NSString * const MGMIViews = @"%VIEWS%";
NSString * const MGMIFavorites = @"%FAVORITES%";
NSString * const MGMIRating = @"%RATING%";
NSString * const MGMIAdded = @"%ADDED%";
NSString * const MGMITime = @"%TIME%";
NSString * const MGMIKeywords = @"%KEYWORDS%";
NSString * const MGMIDescription = @"%DESCRIPTION%";

NSString * const MGMAnimations = @"animationsEnabled";
NSString * const MGMFSFloat = @"FSFloat";
NSString * const MGMFSSpaces = @"FSSpaces";
NSString * const MGMFSSettingsNotification = @"MGMFSSettingsNotification";
NSString * const MGMPageMax = @"pageMax";
NSString * const MGMOrderBy = @"orderBy";
NSString * const MGMRelevance = @"relevance";
NSString * const MGMPublished = @"date";
NSString * const MGMViewCount = @"viewCount";
NSString * const MGMRating = @"rating";
NSString * const MGMMaxQuality = @"maxQuality";
NSString * const MGMWindowMode = @"windowMode";
NSString * const MGMSearchQuery = @"searchQuery";
NSString * const MGMSearchAuthor = @"searchAuthor";
NSString * const MGMSearchStart = @"searchStart";
NSString * const MGMSearchFeed = @"searchFeed";
NSString * const MGMSessionFile = @"session.plist";

NSString * const MGMYTURL = @"http://www.youtube.com/watch?v=%@&feature=YouView";
NSString * const MGMYTSDURL = @"http://www.youtube.com/watch?v=%@&feature=YouView&fmt=18";
NSString * const MGMYTImageURL = @"http://i.ytimg.com/vi/%@/default.jpg";

NSString * const MGMAppleMailID = @"com.apple.mail";
NSString * const MGMThunderBirdID = @"org.mozilla.thunderbird";
NSString * const MGMPostboxID = @"com.postbox-inc.postbox";
NSString * const MGMSparrowID = @"com.sparrowmailapp.sparrow";

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
IOReturn IOPMAssertionCreateWithName(CFStringRef AssertionType, IOPMAssertionLevel AssertionLevel, CFStringRef AssertionName, IOPMAssertionID *AssertionID);
#endif

@implementation MGMController
- (void)awakeFromNib {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setup) name:MGMGRDoneNotification object:nil];
	[MGMReporter sharedReporter];
}
- (void)setup {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:MGMVersion]==nil) {
        [userDefaults setObject:[[MGMSystemInfo info] applicationVersion] forKey:MGMVersion];
        NSString *usersPlist = [[MGMUser applicationSupportPath] stringByAppendingPathComponent:@"Users.plist"];
        id plist = [NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfFile:usersPlist] mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:nil];
        if ([plist isKindOfClass:[NSArray class]]) {
            NSString *applicationName = [[MGMSystemInfo info] applicationName];
            for (int i=0; i<[(NSArray *)plist count]; i++) {
                NSArray *keychainItems = [MGMKeychain items:@"application password" withName:applicationName service:applicationName account:[plist objectAtIndex:i] itemClass:kSecGenericPasswordItemClass];
                if (keychainItems!=nil && [keychainItems count]!=0) {
                    for (int d=0; d<[keychainItems count]; d++) {
                        [[keychainItems objectAtIndex:d] remove];
                    }
                }
            }
            [manager removeItemAtPath:usersPlist];
        }
    }
	[NSUserDefaults registerDefaults];
	
	[MGMUser cachePath];
    
    if (![userDefaults objectForKey:@"seenOSMessage"]) {
        [userDefaults setBool:YES forKey:@"seenOSMessage"];
        NSAlert *theAlert = [[NSAlert new] autorelease];
		[theAlert addButtonWithTitle:@"OK"];
		[theAlert setMessageText:@"YouView Info"];
		[theAlert setInformativeText:@"This version is very limited compared to the original, and search may not work on 10.4. If you have any problems, email me and when I find time I will try to fix it. YouView is now Open Source, you can view the source code by clicking the source code menu."];
		[theAlert setAlertStyle:NSWarningAlertStyle];
		[theAlert runModal];
    }
	
	if ([manager fileExistsAtPath:[[MGMUser applicationSupportPath] stringByAppendingPathComponent:MGMSubscriptionFile]]) {
		subscriptionsDate = [[NSMutableDictionary dictionaryWithContentsOfFile:[[MGMUser applicationSupportPath] stringByAppendingPathComponent:MGMSubscriptionFile]] retain];
	} else {
		subscriptionsDate = [NSMutableDictionary new];
		[subscriptionsDate writeToFile:[[MGMUser applicationSupportPath] stringByAppendingPathComponent:MGMSubscriptionFile] atomically:YES];
	}
	
    preferences = [MGMPreferences new];
    [preferences addPreferencesPaneClassName:@"MGMGeneralPane"];
    [preferences addPreferencesPaneClassName:@"MGMParentalControlsPane"];
    [preferences addPreferencesPaneClassName:@"MGMDonatePane"];
    
	recentSearches = [[NSMutableArray arrayWithArray:[userDefaults objectForKey:MGMRecentSearches]] retain];
	orderBy = [userDefaults integerForKey:MGMOrderBy];
	[relevance setState:(orderBy==1 ? NSOnState : NSOffState)];
	[published setState:(orderBy==2 ? NSOnState : NSOffState)];
	[viewCount setState:(orderBy==3 ? NSOnState : NSOffState)];
	[rating setState:(orderBy==4 ? NSOnState : NSOffState)];
	
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(loggedIn:) name:MGMUserStartNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(loggedOut:) name:MGMUserDoneNotification object:nil];
	
	players = [NSMutableArray new];
	
	remoteControlBehavior = [MultiClickRemoteBehavior new];
	[remoteControlBehavior setDelegate:self];
	[remoteControlBehavior setSimulateHoldEvent:YES];
	[remoteControlBehavior setClickCountingEnabled:NO];
	
	remoteControl = [[RemoteControlContainer alloc] initWithDelegate:remoteControlBehavior];
	[remoteControl addRemoteControlDevice:[[[AppleRemote alloc] initWithDelegate:remoteControlBehavior] autorelease]];
	[remoteControl addRemoteControlDevice:[[[KeyspanFrontRowControl alloc] initWithDelegate:remoteControlBehavior] autorelease]];
	[remoteControl addRemoteControlDevice:[[[GlobalKeyboardDevice alloc] initWithDelegate:remoteControlBehavior] autorelease]];
	[remoteControl setOpenInExclusiveMode:YES];
	
	currPlayer = -1;
	
	NSAppleEventManager *em = [NSAppleEventManager sharedAppleEventManager];
	[em setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
	
	[self newWindow:self];
	systemStatusTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(updateSystemStatus) userInfo:nil repeats:YES];
}
- (void)dealloc {
#if releaseDebug
	MGMLog(@"%s Releasing", __PRETTY_FUNCTION__);
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[systemStatusTimer invalidate];
	[systemStatusTimer release];
	[subscriptionsDate release];
	[holding invalidate];
	[holding release];
	[remoteControl release];
	[remoteControlBehavior release];
	[players release];
	[recentSearches release];
	[preferences release];
	[openURL release];
	[super dealloc];
}

- (void)updateSystemStatus {
	for (int i=0; i<[players count]; i++) {
		if ([[players objectAtIndex:i] isMoviePlaying]) {
            //#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
			MGMSystemInfo *systemInfo = [[MGMSystemInfo new] autorelease];
#ifdef __x86_64__
            if ([systemInfo isAfterSnowLeopard]) {
				IOPMAssertionID assertionID;
                IOReturn success = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep, kIOPMAssertionLevelOn, CFSTR(""), &assertionID);
                if (success == kIOReturnSuccess) {
                    IOPMAssertionRelease(assertionID);
                }
			} else if ([systemInfo isAfterLeopard]) {
				IOPMAssertionID assertionID;
                IOReturn success = IOPMAssertionCreate(kIOPMAssertionTypeNoDisplaySleep, kIOPMAssertionLevelOn, &assertionID);
                if (success == kIOReturnSuccess) {
                    IOPMAssertionRelease(assertionID);
                }
			}
#endif
            //#endif
			if ([systemInfo isAfterTiger]) {
#ifndef __x86_64__
                UpdateSystemActivity(OverallAct);
#endif
            }
			break;
		}
	}
}

- (NSArray *)recentSearches {
	return [NSArray arrayWithArray:recentSearches];
}
- (void)addRecentSearch:(NSString *)theSearch {
	if ([recentSearches containsObject:theSearch])
		[recentSearches removeObject:theSearch];
	[recentSearches insertObject:theSearch atIndex:0];
	if ([recentSearches count]>10) {
		while ([recentSearches count]>10) {
			[recentSearches removeLastObject];
		}
	}
	[[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:recentSearches] forKey:MGMRecentSearches];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGMRecentSearchesChangeNotification object:nil];
}
- (void)clearRecentSearches {
	[recentSearches release];
	recentSearches = nil;
	recentSearches = [NSMutableArray new];
	[[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:recentSearches] forKey:MGMRecentSearches];
	[[NSNotificationCenter defaultCenter] postNotificationName:MGMRecentSearchesChangeNotification object:nil];
}
- (NSMutableDictionary *)subscriptionsDate {
	return subscriptionsDate;
}
- (NSString *)orderBy {
	if (orderBy==1) {
		return MGMRelevance;
	} else if (orderBy==2) {
		return MGMPublished;
	} else if (orderBy==3) {
		return MGMViewCount;
	}
	return MGMRating;
}
- (int)orderByNum {
	return orderBy;
}

- (IBAction)sourceCode:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/GRMrGecko/YouView"]];
}
- (IBAction)donate:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://mrgeckosmedia.com/donate?purpose=youview"]];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	BOOL valid = YES;
	SEL	action;
	
    action = [menuItem action];
	
	if (action==@selector(goFullScreen:) || action==@selector(loop:))
        valid = ([players count]!=0 && currPlayer>=0 && [(MGMPlayer *)[players objectAtIndex:currPlayer] isMovieOpen]);
    return valid;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	if (!flag && openURL==nil) {
		[self newWindow:self];
	}
	return YES;
}

- (IBAction)installSafari:(id)sender {
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"YouView Safari Plugin" ofType:@"pkg"]];
}
- (IBAction)installSafariExt:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://mrgeckosmedia.com/YouView.safariextz"]];
}
- (IBAction)installChrome:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://mrgeckosmedia.com/YouViewChrome.crx"]];
}
- (IBAction)installFirefox:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://mrgeckosmedia.com/YouViewFirefox.xpi"]];
}

- (IBAction)showOpenPanel:(id)sender {
	[openField setStringValue:@"http://www.youtube.com/watch?v=##########"];
	[openWindow makeKeyAndOrderFront:sender];
}

- (IBAction)loop:(id)sender {
	if (currPlayer>=0)
		[[players objectAtIndex:currPlayer] loop];
}

- (IBAction)openURL:(id)sender {
	NSString *videoID = nil;
    if ([[openField stringValue] containsString:@"youtube.com/watch?"]) {
		[openButton setEnabled:NO];
		[openField setEnabled:NO];
		[openURL release];
		videoID = [[NSURL URLWithString:[openField stringValue]] URLParameterWithName:@"v"];
        [openURL release];
		openURL = [[NSString stringWithFormat:MGMYTURL, videoID] retain];
	} else if ([[openField stringValue] containsString:@"youtu.be"]) {
		[openURL release];
        videoID = [[[NSURL URLWithString:[openField stringValue]] path] lastPathComponent];
        [openURL release];
        openURL = [[NSString stringWithFormat:MGMYTURL, videoID] retain];
	} else {
		NSAlert *theAlert = [[NSAlert new] autorelease];
		[theAlert addButtonWithTitle:@"OK"];
		[theAlert setMessageText:@"URL Error"];
		[theAlert setInformativeText:@"The URL does not match any supported URLs."];
		[theAlert setAlertStyle:NSWarningAlertStyle];
		[theAlert runModal];
	}
    if (videoID!=nil) {
        BOOL new = YES;
        BOOL windowModeMain = ([[NSUserDefaults standardUserDefaults] integerForKey:MGMWindowMode]==0);
        
        NSURL *videoURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@", videoID]];
        if (currPlayer>=0 && ![(MGMPlayer *)[players objectAtIndex:currPlayer] isMovieOpen]) {
            [(MGMPlayer *)[players objectAtIndex:currPlayer] openMovie:videoURL];
            new = NO;
        } else {
            for (int i=0; i<[players count]; i++) {
                if ([[(MGMPlayer *)[players objectAtIndex:i] entry] isEqual:videoURL] && [(MGMPlayer *)[players objectAtIndex:i] isMovieOpen]) {
                    [[(MGMPlayer *)[players objectAtIndex:i] mainWindow] makeKeyAndOrderFront:self];
                    new = NO;
                    break;
                } else if (![(MGMPlayer *)[players objectAtIndex:i] isMovieOpen] && windowModeMain) {
                    [(MGMPlayer *)[players objectAtIndex:i] openMovie:videoURL];
                    [[(MGMPlayer *)[players objectAtIndex:i] mainWindow] makeKeyAndOrderFront:self];
                    new = NO;
                    break;
                }
            }
        }
		if (new) {
			[players addObject:[MGMPlayer playerWithVideo:videoURL controller:self player:!windowModeMain]];
			currPlayer = [players count]-1;
		}
    }
    [openButton setEnabled:YES];
	[openField setEnabled:YES];
	[openWindow close];
}

- (void)openVideo:(NSURL *)theVideo {
	BOOL new = YES;
    BOOL windowModeMain = ([[NSUserDefaults standardUserDefaults] integerForKey:MGMWindowMode]==0);
    for (int i=0; i<[players count]; i++) {
        if ([[(MGMPlayer *)[players objectAtIndex:i] entry] isEqual:theVideo] && [(MGMPlayer *)[players objectAtIndex:i] isMovieOpen]) {
            [[(MGMPlayer *)[players objectAtIndex:i] mainWindow] makeKeyAndOrderFront:self];
            new = NO;
            break;
        } else if (![(MGMPlayer *)[players objectAtIndex:i] isMovieOpen] && windowModeMain) {
            [(MGMPlayer *)[players objectAtIndex:i] openMovie:theVideo];
            [[(MGMPlayer *)[players objectAtIndex:i] mainWindow] makeKeyAndOrderFront:self];
            new = NO;
            break;
        }
    }
    if (new) {
        [players addObject:[MGMPlayer playerWithVideo:theVideo controller:self player:!windowModeMain]];
        currPlayer = [players count]-1;
    }

}
//Apple Remote
- (void)applicationWillBecomeActive:(NSNotification *)aNotification {
	[remoteControl startListening:self];
}
- (void)applicationWillResignActive:(NSNotification *)aNotification {
	[remoteControl stopListening:self];
}

- (void)remoteButton:(RemoteControlEventIdentifier)buttonIdentifier pressedDown:(BOOL)pressedDown clickCount:(unsigned int)clickCount {
	MGMPlayer *player = (currPlayer>=0 ? [players objectAtIndex:currPlayer] : nil);
	if (player==nil) {
		[players addObject:[MGMPlayer playerWithVideo:nil controller:self player:NO]];
		player = [players lastObject];
		currPlayer = [players indexOfObject:player];
	}
	QTMovieView *moviePlayer = [player moviePlayer];
	
#if youviewdebug
	NSString *buttonName = @"";
	NSString *pressed = @"";
	if (pressedDown) pressed = @"(pressed)"; else pressed = @"(released)";
#endif
	
	switch(buttonIdentifier) {
		case kRemoteButtonPlus:
#if youviewdebug
			buttonName = @"Volume up";
#endif
			if ([player isMovieOpen]) {
				if (!pressedDown) {
					double volume = [[moviePlayer movie] volume];
					if (volume!=1) {
						volume += 0.2;
					}
					[[moviePlayer movie] setVolume:volume];
				}
			} else {
				if (!pressedDown) {
					if ([[player resultsTable] selectedRow]-1!=-1) {
						[[player resultsTable] selectRowIndexes:[NSIndexSet indexSetWithIndex:[[player resultsTable] selectedRow]-1] byExtendingSelection:NO];
						[[player resultsTable] scrollRowToVisible:[[player resultsTable] selectedRow]];
						[[player mainWindow] makeFirstResponder:[player resultsTable]];
					}
				}
			}
			break;
		case kRemoteButtonMinus:
#if youviewdebug
			buttonName = @"Volume down";
#endif
			if ([player isMovieOpen]) {
				if (!pressedDown) {
					double volume = [[moviePlayer movie] volume];
					if (volume!=0) {
						volume -= 0.2;
					}
					[[moviePlayer movie] setVolume:volume];
				}
			} else {
				if (!pressedDown) {
					if ([player resultsCount]>[[player resultsTable] selectedRow]+1) {
						[[player resultsTable] selectRowIndexes:[NSIndexSet indexSetWithIndex:[[player resultsTable] selectedRow]+1] byExtendingSelection:NO];
						[[player resultsTable] scrollRowToVisible:[[player resultsTable] selectedRow]];
						[[player mainWindow] makeFirstResponder:[player resultsTable]];
					}
				}
			}
			break;
		case kRemoteButtonMenu:
#if youviewdebug
			buttonName = @"Menu";
#endif
			if ([player isMovieOpen]) {
				if (!pressedDown) {
					[player goFullScreen];
				}
			}
			break;
		case kRemoteButtonPlay:
#if youviewdebug
			buttonName = @"Play";
#endif
			if ([player isMovieOpen]) {
				if (!pressedDown) {
					if (([[moviePlayer movie] rate] == 0)) {
						[[moviePlayer movie] play];
					} else {
						[[moviePlayer movie] stop];
					}
				}
			} else {
				if ([[player resultsTable] isRowSelected:[[player resultsTable] selectedRow]]) {
					[player openVideo:self];
				}
			}
			break;
		case kRemoteButtonRight:
#if youviewdebug
			buttonName = @"Right";
#endif
			if ([player isMovieOpen]) {
				if (!pressedDown) {
					for (int i=0; i<30; i++) {
						[[moviePlayer movie] stepForward];
					}
					[[moviePlayer movie] play];
				}
			}
			break;
		case kRemoteButtonLeft:
#if youviewdebug
			buttonName = @"Left";
#endif
			if ([player isMovieOpen]) {
				if (!pressedDown) {
					for (int i=0; i<30; i++) {
						[[moviePlayer movie] stepBackward];
					}
					[[moviePlayer movie] play];
				}
			}
			break;
		case kRemoteButtonRight_Hold:
#if youviewdebug
			buttonName = @"Right holding";
#endif
			if ([player isMovieOpen]) {
				if (pressedDown) {
					NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:player, @"player", [NSNumber numberWithInt:buttonIdentifier], @"button", nil];
					[holding invalidate];
					[holding release];
					holding = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(holding:) userInfo:dic repeats:YES] retain];
				} else {
					[holding invalidate];
					[holding release];
					holding = nil;
					[[moviePlayer movie] play];
				}
			}
			break;
		case kRemoteButtonLeft_Hold:
#if youviewdebug
			buttonName = @"Left holding";
#endif
			if ([player isMovieOpen]) {
				if (pressedDown) {
					NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:player, @"player", [NSNumber numberWithInt:buttonIdentifier], @"button", nil];
					[holding invalidate];
					[holding release];
					holding = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(holding:) userInfo:dic repeats:YES] retain];
				} else {
					[holding invalidate];
					[holding release];
					holding = nil;
					[[moviePlayer movie] play];
				}
			}
			break;
		case kRemoteButtonPlus_Hold:
#if youviewdebug
			buttonName = @"Volume up holding";
#endif
			if ([player isMovieOpen]) {
				if (pressedDown) {
					[[moviePlayer movie] setVolume:1.0];
				}
			}
			break;
		case kRemoteButtonMinus_Hold:
#if youviewdebug
			buttonName = @"Volume down holding";
#endif
			if ([player isMovieOpen]) {
				if (pressedDown) {
					[[moviePlayer movie] setVolume:0.0];
				}
			}
			break;
		case kRemoteButtonPlay_Hold:
#if youviewdebug
			buttonName = @"Play (sleep mode)";
#endif
			if ([player isMovieOpen]) {
				if (pressedDown) {
					if (![player isFullScreen]) {
						[player closeMovie];
					} else {
						[player goFullScreen];
					}
				}
			}
			break;
		case kRemoteButtonMenu_Hold:
#if youviewdebug
			buttonName = @"Menu (long)";
#endif
			[[player mainWindow] makeFirstResponder:[player resultsTable]];
			break;
		case kRemoteControl_Switched:
#if youviewdebug
			buttonName = @"Remote Control Switched";
#endif
			break;
		default:
			MGMLog(@"Unmapped event for button %d", buttonIdentifier);
			break;
	}
#if youviewdebug
	MGMLog(@"Button %@ pressed %@", buttonName, pressed);
	NSString* clickCountString = @"";
	if (clickCount > 1) clickCountString = [NSString stringWithFormat: @"%d clicks", clickCount];
	NSString* feedbackString = [NSString stringWithFormat:@"%@ %@ %@", buttonName, pressed, clickCountString];
	
	MGMLog(@"%@", feedbackString);
	if (pressedDown == NO) printf("\n");
#endif
}

- (void)holding:(NSTimer *)theTimer {
	RemoteControlEventIdentifier buttonIdentifier = [[[theTimer userInfo] objectForKey:@"button"] intValue];
	MGMPlayer *player = [[theTimer userInfo] objectForKey:@"player"];
	switch(buttonIdentifier) {
		case kRemoteButtonRight_Hold:
			if ([player isMovieOpen]) {
				for (int i=0; i<10; i++) {
					[[[player moviePlayer] movie] stepForward];
				}
			}
			break;
		case kRemoteButtonLeft_Hold:
			if ([player isMovieOpen]) {
				for (int i=0; i<10; i++) {
					[[[player moviePlayer] movie] stepBackward];
				}
			}
			break;
        default:
            break;
	}
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
	NSURL *url = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
	if ([[[url scheme] lowercaseString] isEqual:@"youview"]) {
        NSString *videoID = @"";
		if ([url host]!=nil) {
			videoID = [url host];
		} else if ([url query]) {
			videoID = [[url query] URLParameterWithName:@"id"];
		}
		[openURL release];
		openURL = [[NSString stringWithFormat:MGMYTURL, videoID] retain];
		
        BOOL new = YES;
        BOOL windowModeMain = ([[NSUserDefaults standardUserDefaults] integerForKey:MGMWindowMode]==0);
        
        NSURL *videoURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@", videoID]];
        if (currPlayer>=0 && ![(MGMPlayer *)[players objectAtIndex:currPlayer] isMovieOpen]) {
            [(MGMPlayer *)[players objectAtIndex:currPlayer] openMovie:videoURL];
            new = NO;
        } else {
            for (int i=0; i<[players count]; i++) {
                if ([[(MGMPlayer *)[players objectAtIndex:i] entry] isEqual:videoURL] && [(MGMPlayer *)[players objectAtIndex:i] isMovieOpen]) {
                    [[(MGMPlayer *)[players objectAtIndex:i] mainWindow] makeKeyAndOrderFront:self];
                    new = NO;
                    break;
                } else if (![(MGMPlayer *)[players objectAtIndex:i] isMovieOpen] && windowModeMain) {
                    [(MGMPlayer *)[players objectAtIndex:i] openMovie:videoURL];
                    [[(MGMPlayer *)[players objectAtIndex:i] mainWindow] makeKeyAndOrderFront:self];
                    new = NO;
                    break;
                }
            }
        }
		if (new) {
			[players addObject:[MGMPlayer playerWithVideo:videoURL controller:self player:!windowModeMain]];
			currPlayer = [players count]-1;
		}
	}
}

- (void)playerClosed:(MGMPlayer *)player {
	[players removeObject:player];
}
- (void)playerBecameKey:(MGMPlayer *)player {
	if ([player isFullScreen]) {
		if ([[[player fullScreenWindow] screen] isEqual:[[NSScreen screens] objectAtIndex:0]])
			[NSMenu setMenuBarVisible:NO];
	} else {
		[NSMenu setMenuBarVisible:YES];
	}
	if ([players containsObject:player]) {
		currPlayer = [players indexOfObject:player];
	}
}
- (IBAction)goFullScreen:(id)sender {
	MGMPlayer *player = [players objectAtIndex:currPlayer];
	if ([player isMovieOpen]) {
		[player goFullScreen];
	}
}

- (IBAction)newWindow:(id)sender {
	[players addObject:[MGMPlayer playerWithVideo:nil controller:self player:NO]];
	currPlayer = [players count]-1;
}

- (NSString *)currentURL {
    MGMPlayer *player = [players objectAtIndex:currPlayer];
	NSString *videoID = [[player entry] URLParameterWithName:@"v"];
    if (videoID==nil)
        return nil;
	return [NSString stringWithFormat:@"http://youtu.be/%@?feature=YouView", videoID];
}

- (IBAction)copyURL:(id)sender {
	NSString *url = [self currentURL];
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
	[pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
	[pasteBoard setString:url forType:NSStringPboardType];
}

- (void)mailHTML:(NSString *)theHTML withSubject:(NSString *)theSubject {
    WebResource *mainResource = [[WebResource alloc] initWithData:[theHTML dataUsingEncoding:NSUTF8StringEncoding] URL:[NSURL URLWithString:@""] MIMEType:@"text/html" textEncodingName:@"UTF-8" frameName:nil];
    WebArchive *webArchive = [[WebArchive alloc] initWithMainResource:mainResource subresources:nil subframeArchives:nil];
    [mainResource release];
    
    
    const char *bundleIdentifier = [MGMAppleMailID UTF8String];
	AppleEvent *cmdEvent;
    OSErr err;
    
    NSData *messageData = [webArchive data];
    
    AEDesc *messageDesc = malloc(sizeof(AEDesc));
    err = AEBuildDesc(messageDesc, NULL, "'tdta'(@)", [messageData length], [messageData bytes]);
    
    if (err!=noErr) {
        NSLog(@"Error with constructing message: %d", err);
        free(messageDesc);
        goto fail;
    }
    
    AEDesc *subjectDesc = malloc(sizeof(AEDesc));
    err = AEBuildDesc(subjectDesc, NULL, "'utxt'(@)", [theSubject lengthOfBytesUsingEncoding:NSUnicodeStringEncoding], [theSubject cStringUsingEncoding:NSUnicodeStringEncoding]);
    
    if (err!=noErr) {
        NSLog(@"Error with constructing subject: %d", err);
        free(subjectDesc);
        AEDisposeDesc(messageDesc);
        free(messageDesc);
        goto fail;
    }
    
    cmdEvent = malloc(sizeof(AppleEvent));
	err = AEBuildAppleEvent('mail', 'mlpg', typeApplicationBundleID, bundleIdentifier, strlen(bundleIdentifier), kAutoGenerateReturnID, kAnyTransactionID, cmdEvent, NULL, "'----':@, 'urln':@", messageDesc, subjectDesc);
    
    AEDisposeDesc(messageDesc);
    free(messageDesc);
    
    AEDisposeDesc(subjectDesc);
    free(subjectDesc);
    
	if (err!=noErr) {
		NSLog(@"Error creating Apple Event: %d", err);
		free(cmdEvent);
		goto fail;
	}
    
    FSRef mailPath;
    err = LSFindApplicationForInfo(0, (CFStringRef)MGMAppleMailID, nil, &mailPath, nil);
    if (err!=noErr) {
		NSLog(@"Error finding Apple Mail: %d", err);
        Handle printData;
        AEPrintDescToHandle(cmdEvent, &printData);
        NSLog(@"%s", *printData);
        AEDisposeDesc(cmdEvent);
        free(cmdEvent);
		goto fail;
	}
    
    
    LSApplicationParameters appParams;
    
    memset(&appParams, 0, sizeof(appParams));
    
    appParams.version = 0;
    appParams.flags = kLSLaunchDontSwitch;
    appParams.application = &mailPath;
    appParams.initialEvent = cmdEvent;
    
    ProcessSerialNumber psn;
    err = LSOpenApplication(&appParams, &psn);
    if (err!=noErr) {
		NSLog(@"Error sending AppleEvent: %d", err);
        Handle printData;
        AEPrintDescToHandle(cmdEvent, &printData);
        NSLog(@"%s", *printData);
        AEDisposeDesc(cmdEvent);
        free(cmdEvent);
		goto fail;
	}
	AEDisposeDesc(cmdEvent);
	free(cmdEvent);
    
    [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    
    cmdEvent = malloc(sizeof(AppleEvent));
	err = AEBuildAppleEvent('misc', 'actv', typeApplicationBundleID, bundleIdentifier, strlen(bundleIdentifier), kAutoGenerateReturnID, kAnyTransactionID, cmdEvent, NULL, "");
    
	if (err!=noErr) {
		NSLog(@"Error creating Apple Event: %d", err);
		free(cmdEvent);
		goto fail;
	}
    
	err = AESendMessage(cmdEvent, NULL, kAENoReply | kAENeverInteract, kAEDefaultTimeout);
	if (err!=noErr) {
		NSLog(@"Error sending AppleEvent: %d", err);
        Handle printData;
        AEPrintDescToHandle(cmdEvent, &printData);
        NSLog(@"%s", *printData);
        AEDisposeDesc(cmdEvent);
        free(cmdEvent);
		goto fail;
	}
	AEDisposeDesc(cmdEvent);
	free(cmdEvent);
    
    goto fail;
fail:
    [webArchive release];
}

- (void)sparrowHTML:(NSString *)theHTML withSubject:(NSString *)theSubject {
    const char *bundleIdentifier = [MGMSparrowID UTF8String];
	AppleEvent *cmdEvent;
    OSErr err;
    
    cmdEvent = malloc(sizeof(AppleEvent));
	err = AEBuildAppleEvent('misc', 'actv', typeApplicationBundleID, bundleIdentifier, strlen(bundleIdentifier), kAutoGenerateReturnID, kAnyTransactionID, cmdEvent, NULL, "");
    
	if (err!=noErr) {
		NSLog(@"Error creating Apple Event: %d", err);
		free(cmdEvent);
		goto fail;
	}
    
    FSRef sparrowPath;
    err = LSFindApplicationForInfo(0, (CFStringRef)MGMSparrowID, nil, &sparrowPath, nil);
    if (err!=noErr) {
		NSLog(@"Error finding Sparrow: %d", err);
        Handle printData;
        AEPrintDescToHandle(cmdEvent, &printData);
        NSLog(@"%s", *printData);
        AEDisposeDesc(cmdEvent);
        free(cmdEvent);
		goto fail;
	}
    
    LSApplicationParameters appParams;
    
    memset(&appParams, 0, sizeof(appParams));
    
    appParams.version = 0;
    appParams.flags = kLSLaunchDontSwitch;
    appParams.application = &sparrowPath;
    appParams.initialEvent = cmdEvent;
    
    ProcessSerialNumber psn;
    err = LSOpenApplication(&appParams, &psn);
    if (err!=noErr) {
		NSLog(@"Error sending AppleEvent: %d", err);
        Handle printData;
        AEPrintDescToHandle(cmdEvent, &printData);
        NSLog(@"%s", *printData);
        AEDisposeDesc(cmdEvent);
        free(cmdEvent);
		goto fail;
	}
	AEDisposeDesc(cmdEvent);
	free(cmdEvent);
    
    AEDesc *subjectDesc = malloc(sizeof(AEDesc));
    err = AEBuildDesc(subjectDesc, NULL, "'utxt'(@)", [theSubject lengthOfBytesUsingEncoding:NSUnicodeStringEncoding], [theSubject cStringUsingEncoding:NSUnicodeStringEncoding]);
    
    if (err!=noErr) {
        NSLog(@"Error with constructing subject: %d", err);
        free(subjectDesc);
        goto fail;
    }
    
    AEDesc *messageDesc = malloc(sizeof(AEDesc));
    err = AEBuildDesc(messageDesc, NULL, "'utxt'(@)", [theHTML lengthOfBytesUsingEncoding:NSUnicodeStringEncoding], [theHTML cStringUsingEncoding:NSUnicodeStringEncoding]);
    
    if (err!=noErr) {
        NSLog(@"Error with constructing message: %d", err);
        free(messageDesc);
        AEDisposeDesc(subjectDesc);
        free(subjectDesc);
        goto fail;
    }
    
    cmdEvent = malloc(sizeof(AppleEvent));
	err = AEBuildAppleEvent('core', 'crel', typeApplicationBundleID, bundleIdentifier, strlen(bundleIdentifier), kAutoGenerateReturnID, kAnyTransactionID, cmdEvent, NULL, "'kocl':type('bcke'), 'prdt':reco {'subj':@, 'htct':@}", subjectDesc, messageDesc);
    
    AEDisposeDesc(messageDesc);
    free(messageDesc);
    
    AEDisposeDesc(subjectDesc);
    free(subjectDesc);
    
	if (err!=noErr) {
		NSLog(@"Error creating Apple Event: %d", err);
		free(cmdEvent);
		goto fail;
	}
    
    AppleEvent *replyEvent = malloc(sizeof(AppleEvent));
	err = AESendMessage(cmdEvent, replyEvent, kAEWaitReply | kAENeverInteract, kAEDefaultTimeout);
	if (err!=noErr) {
		NSLog(@"Error sending AppleEvent: %d", err);
        Handle printData;
        AEPrintDescToHandle(cmdEvent, &printData);
        NSLog(@"%s", *printData);
        free(replyEvent);
        AEDisposeDesc(cmdEvent);
        free(cmdEvent);
		goto fail;
	}
	AEDisposeDesc(cmdEvent);
	free(cmdEvent);
    
    AEDesc *objectDesc = malloc(sizeof(AEDesc));
    err = AEGetParamDesc(replyEvent, keyDirectObject, typeWildCard, objectDesc);
    
    if (err!=noErr) {
		NSLog(@"Error getting direct object: %d", err);
        Handle printData;
        AEPrintDescToHandle(replyEvent, &printData);
        NSLog(@"%s", *printData);
        free(objectDesc);
        AEDisposeDesc(replyEvent);
        free(replyEvent);
		goto fail;
	}
    
    Size idSize = 255*sizeof(unichar);
    unichar *idData = (unichar *)malloc(idSize);
    err = AEGetParamPtr(objectDesc, 'seld', typeUnicodeText, NULL, idData, idSize, &idSize);
    
    if (err!=noErr) {
		NSLog(@"Error getting data: %d", err);
        Handle printData;
        AEPrintDescToHandle(objectDesc, &printData);
        NSLog(@"%s", *printData);
        free(idData);
        AEDisposeDesc(objectDesc);
        free(objectDesc);
        AEDisposeDesc(replyEvent);
        free(replyEvent);
		goto fail;
	}
    
    NSString *identifier = [[[NSString alloc] initWithCharacters:idData length:idSize/sizeof(unichar)] autorelease];
    free(idData);
    
	AEDisposeDesc(objectDesc);
    free(objectDesc);
    
	AEDisposeDesc(replyEvent);
    free(replyEvent);
    
    
    AEDesc *identifierDesc = malloc(sizeof(AEDesc));
    err = AEBuildDesc(identifierDesc, NULL, "'utxt'(@)", [identifier lengthOfBytesUsingEncoding:NSUnicodeStringEncoding], [identifier cStringUsingEncoding:NSUnicodeStringEncoding]);
    
    if (err!=noErr) {
        NSLog(@"Error with constructing message: %d", err);
        free(identifierDesc);
        goto fail;
    }
    
    cmdEvent = malloc(sizeof(AppleEvent));
	err = AEBuildAppleEvent('sprw', 'cmps', typeApplicationBundleID, bundleIdentifier, strlen(bundleIdentifier), kAutoGenerateReturnID, kAnyTransactionID, cmdEvent, NULL, "'----':obj {'form':('ID  '), 'want':type('bcke'), 'seld':@, 'from':null()}", identifierDesc);
    
    AEDisposeDesc(identifierDesc);
    free(identifierDesc);
    
	if (err!=noErr) {
		NSLog(@"Error creating Apple Event: %d", err);
		free(cmdEvent);
		goto fail;
	}
    
	err = AESendMessage(cmdEvent, NULL, kAENoReply | kAENeverInteract, kAEDefaultTimeout);
	if (err!=noErr) {
		NSLog(@"Error sending AppleEvent: %d", err);
        Handle printData;
        AEPrintDescToHandle(cmdEvent, &printData);
        NSLog(@"%s", *printData);
        AEDisposeDesc(cmdEvent);
        free(cmdEvent);
		goto fail;
	}
	AEDisposeDesc(cmdEvent);
	free(cmdEvent);
    
    goto fail;
fail:
    return;
}

- (IBAction)about:(id)sender {
	[aboutTitle setStringValue:[NSString stringWithFormat:@"YouView %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
	[aboutWin makeKeyAndOrderFront:sender];
}
- (IBAction)preferences:(id)sender {
	[preferences showPreferences];
}

- (void)setOrder:(int)order {
	orderBy = order;
	[[NSUserDefaults standardUserDefaults] setInteger:order forKey:MGMOrderBy];
	[relevance setState:(orderBy==1 ? NSOnState : NSOffState)];
	[published setState:(orderBy==2 ? NSOnState : NSOffState)];
	[viewCount setState:(orderBy==3 ? NSOnState : NSOffState)];
	[rating setState:(orderBy==4 ? NSOnState : NSOffState)];;
}

- (IBAction)setOrderBy:(id)sender {
	[self setOrder:[sender tag]];
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id <WebPolicyDecisionListener>)listener {
	if (![[[request URL] absoluteString] isEqual:@"about:blank"]) {
		NSURL *url = [actionInformation objectForKey:WebActionOriginalURLKey];
		[[NSWorkspace sharedWorkspace] openURL:url];
		
		[listener ignore];
	} else {
		[listener use];
	}
}
- (void)iconLoader:(MGMURLBasicHandler *)theHandler didFailWithError:(NSError *)theError {
	NSLog(@"Error loading image: %@ %@", [[theHandler object] objectForKey:MGMILURL], theError);
}
- (void)iconLoaderDidFinish:(MGMURLBasicHandler *)theHandler {
	NSDictionary *info = [theHandler object];
	NSImage *image = [[[NSImage alloc] initWithData:[theHandler data]] autorelease];
	if (image!=nil) {
		[[image TIFFRepresentation] writeToFile:[info objectForKey:MGMILPath] atomically:YES];
	}
	[self setIcon:image];
}
- (void)setIcon:(NSImage *)preview {
	if (preview==nil) {
		[[NSApplication sharedApplication] setApplicationIconImage:[NSImage imageNamed:@"NSApplicationIcon"]];
	} else {
		NSImage *iconImage = [NSImage imageNamed:@"YouViewPreview"];
		NSImage *previewImage = [[[NSImage alloc] initWithSize:[iconImage size]] autorelease];
		NSSize	destSize = NSMakeSize(116, 74);
		NSSize originalSize = [preview size];
		float width  = originalSize.width;
		float height = originalSize.height;
		
		float targetWidth  = destSize.width;
		float targetHeight = destSize.height;
		
		float scaleFactor  = 0.0;
		float scaledWidth  = targetWidth;
		float scaledHeight = targetHeight;
		
		NSPoint thumbnailPoint = NSZeroPoint;
		
		if (NSEqualSizes(originalSize, destSize) == NO) {
			float widthFactor  = targetWidth / width;
			float heightFactor = targetHeight / height;
			
			if (widthFactor < heightFactor)
				scaleFactor = widthFactor;
			else
				scaleFactor = heightFactor;
			
			scaledWidth  = width  * scaleFactor;
			scaledHeight = height * scaleFactor;
			
			if (widthFactor < heightFactor)
				thumbnailPoint.y = (targetHeight - scaledHeight) * 7;
			else
				thumbnailPoint.y = 36;
			
			if ( widthFactor > heightFactor )
				thumbnailPoint.x = (targetWidth - scaledWidth) * 0.85;
			else
				thumbnailPoint.x = 6;
		}
		NSRect thumbnailRect;
		thumbnailRect.origin = thumbnailPoint;
		thumbnailRect.size.width = scaledWidth;
		thumbnailRect.size.height = scaledHeight;
		[previewImage lockFocus];
		NSBezierPath *mPath = [NSBezierPath bezierPath];
		[mPath appendBezierPathWithRect:NSMakeRect(6, 36, 116, 74)];
		[mPath closePath];
		[[NSColor blackColor] set];
		[mPath fill];
		
		[preview drawInRect:thumbnailRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction: 1.0];
		
		[iconImage drawInRect:NSMakeRect(0, 0, [iconImage size].width, [iconImage size].height) fromRect:NSMakeRect(0, 0, [iconImage size].width, [iconImage size].height) operation:NSCompositeSourceOver fraction:1.0];
		[previewImage unlockFocus];
		[[NSApplication sharedApplication] setApplicationIconImage:previewImage];
	}
}

- (IBAction)saveVideo:(id)sender {
	MGMPlayer *player = [players objectAtIndex:currPlayer];
	[taskManager saveEntry:[player entry] title:[player title]];
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
	[taskManager application:sender openFiles:filenames];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	NSApplicationTerminateReply reply = [taskManager applicationShouldTerminate:sender];
	if (reply==NSTerminateNow) {
	}
    [[NSFileManager defaultManager] removeItemAtPath:[MGMUser cachePath]];
	return reply;
}

- (NSURL *)generateAPIURL:(NSString *)path arguments:(NSMutableDictionary *)arguments {
    NSMutableString *url = [NSMutableString stringWithFormat:@"https://www.googleapis.com/youtube/v3/%@?key=%@", path, MGMYTAPIKey];
    if (arguments==nil) {
        arguments = [NSMutableDictionary dictionary];
    }
    NSArray *keys = [arguments allKeys];
    for (long i=0; i<[keys count]; i++) {
        [url appendFormat:@"&%@=%@", [[keys objectAtIndex:i] addPercentEscapes], [[arguments objectForKey:[keys objectAtIndex:i]] addPercentEscapes]];
    }
    return [NSURL URLWithString:url];
}
@end