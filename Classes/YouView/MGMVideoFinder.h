//
//  MGMVideoFinder.h
//  YouView
//
//  Created by Mr. Gecko on 8/3/10.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol MGMVideoFinderDelegate
- (void)loadFlash:(NSDictionary *)info;
- (void)loadVideo:(NSDictionary *)info;
@end

extern NSString * const MGMVLVideoURLKey;
extern NSString * const MGMVLAudioURLKey;
extern NSString * const MGMVLURLKey;
extern NSString * const MGMVLTitle;
extern NSString * const MGMVLVersion;

@class MGMURLConnectionManager;

@interface MGMVideoFinder : NSObject {
	id<MGMVideoFinderDelegate> delegate;
	int maxQuality;
	NSURL *URL;
	MGMURLConnectionManager *connectionManager;
	NSMutableArray *videoURLS;
	NSString *title;
	NSString *version;
	BOOL requestingSD;
    
    NSMutableDictionary *videoQualities;
}
- (id)initWithURL:(NSURL *)theURL connectionManager:(MGMURLConnectionManager *)theConnectionManager maxQuality:(int)theMaxQuality delegate:(id)theDelegate;
- (void)setTitle:(NSString *)theTitle;
- (NSString *)title;
- (void)setVersion:(NSString *)theVersion;
- (NSString *)version;
- (void)startVideo;
- (void)loadSD;
- (void)shouldLoadFlash;
- (void)loadFlash;
@end
