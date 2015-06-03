//
//  Controller.h
//  YouView
//
//  Created by Mr. Gecko on 1/17/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define youviewdebug 1
#define releaseDebug 0

extern NSString * const MGMUserAgent;

extern NSString * const MGMSafeSearch;
extern NSString * const MGMAllowFlaggedVideos;
extern NSString * const MGMSalt1;
extern NSString * const MGMSalt2;
extern NSString * const MGMDonationPath;
extern NSString * const MGMRecentSearchesChangeNotification;
extern NSString * const MGMRecentSearches;

extern NSString * const MGMSubscriptionFile;

extern NSString * const MGMIAuthor;
extern NSString * const MGMITitle;
extern NSString * const MGMIViews;
extern NSString * const MGMIFavorites;
extern NSString * const MGMIRating;
extern NSString * const MGMIAdded;
extern NSString * const MGMITime;
extern NSString * const MGMIKeywords;
extern NSString * const MGMIDescription;

extern NSString * const MGMAnimations;
extern NSString * const MGMFSFloat;
extern NSString * const MGMFSSpaces;
extern NSString * const MGMFSSettingsNotification;
extern NSString * const MGMPageMax;
extern NSString * const MGMOrderBy;
extern NSString * const MGMRelevance;
extern NSString * const MGMPublished;
extern NSString * const MGMViewCount;
extern NSString * const MGMRating;
extern NSString * const MGMMaxQuality;
extern NSString * const MGMWindowMode;

extern NSString * const MGMYTURL;
extern NSString * const MGMYTSDURL;
extern NSString * const MGMYTImageURL;

@class WebView, MGMTaskManager, MGMPlayer, RemoteControlContainer, MultiClickRemoteBehavior, MGMPreferences;

@interface MGMController : NSObject {
	//Essentials
	NSMutableDictionary *subscriptionsDate;
	//Apple Remote
	NSTimer *holding;
	RemoteControlContainer *remoteControl;
	MultiClickRemoteBehavior *remoteControlBehavior;
	//About
	IBOutlet NSWindow *aboutWin;
	IBOutlet NSTextField *aboutTitle;
	//Prefences
	MGMPreferences *preferences;
	//Sorting
	IBOutlet NSMenuItem *relevance;
	IBOutlet NSMenuItem *published;
	IBOutlet NSMenuItem *viewCount;
	IBOutlet NSMenuItem *rating;
	int orderBy;
	//Open
	IBOutlet NSWindow *openWindow;
	IBOutlet NSTextField *openField;
	IBOutlet NSButton *openButton;
	NSString *openURL;
	//Task
	IBOutlet MGMTaskManager *taskManager;
	
	NSMutableArray *players;
	int currPlayer;
	
	NSMutableArray *recentSearches;
	NSTimer *systemStatusTimer;
    
    BOOL openingURL;
}
- (void)setup;
- (NSArray *)recentSearches;
- (void)addRecentSearch:(NSString *)theSearch;
- (void)clearRecentSearches;
- (NSMutableDictionary *)subscriptionsDate;
- (NSString *)orderBy;
- (int)orderByNum;

- (IBAction)sourceCode:(id)sender;
- (IBAction)donate:(id)sender;

- (IBAction)installSafari:(id)sender;
- (IBAction)installSafariExt:(id)sender;
- (IBAction)installChrome:(id)sender;
- (IBAction)installFirefox:(id)sender;
- (void)holding:(NSTimer *)theTimer;
- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent;
- (IBAction)showOpenPanel:(id)sender;
- (IBAction)loop:(id)sender;
- (IBAction)openURL:(id)sender;
- (void)openVideo:(NSURL *)theVideo;
- (void)playerClosed:(MGMPlayer *)player;
- (void)playerBecameKey:(MGMPlayer *)player;
- (IBAction)goFullScreen:(id)sender;
- (IBAction)newWindow:(id)sender;
- (IBAction)copyURL:(id)sender;
- (IBAction)about:(id)sender;
- (IBAction)preferences:(id)sender;
- (void)setOrder:(int)order;
- (IBAction)setOrderBy:(id)sender;
- (void)setIcon:(NSImage *)preview;
- (IBAction)saveVideo:(id)sender;

- (NSURL *)generateAPIURL:(NSString *)path arguments:(NSMutableDictionary *)arguments;
@end
