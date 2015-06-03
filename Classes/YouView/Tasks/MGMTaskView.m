//
//  MGMTaskView.m
//  YouView
//
//  Created by Mr. Gecko on 4/16/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import "MGMTaskView.h"
#import "MGMTaskManager.h"
#import "MGMAddons.h"
#import "MGMVideoFinder.h"
#import "MGMParentalControls.h"
#import "MGMController.h"
#import <MGMUsers/MGMUsers.h>
#import <GeckoReporter/GeckoReporter.h>
#import <sys/sysctl.h>

@implementation MGMTaskView
+ (id)taskViewWithTask:(NSDictionary *)theTask withVideo:(NSURL *)theVideo manager:(MGMTaskManager *)theManager {
	return [[[self alloc] initWithTask:theTask withVideo:theVideo manager:theManager] autorelease];
}
- (id)initWithTask:(NSDictionary *)theTask withVideo:(NSURL *)theVideo manager:(MGMTaskManager *)theManager {
	if (self = [super init]) {
        manager = [theManager retain];
		if (![NSBundle loadNibNamed:@"MGMTaskView" owner:self]) {
            [self release];
            self = nil;
        } else {
			connectionManager = [[MGMURLConnectionManager manager] retain];
			[connectionManager setUserAgent:MGMUserAgent];
			
			if (theVideo!=nil) {
				entry = [theVideo retain];
				taskInfo = [[NSMutableDictionary dictionaryWithDictionary:theTask] retain];
				[taskInfo setObject:[[taskInfo objectForKey:MGMDonePath] lastPathComponent] forKey:MGMFileName];
				[taskInfo setObject:[[taskInfo objectForKey:MGMDonePath] stringByAppendingPathExtension:MGMYVTaskExt] forKey:MGMYVTaskPath];
				[taskInfo setObject:[[taskInfo objectForKey:MGMYVTaskPath] stringByAppendingPathComponent:[[[taskInfo objectForKey:MGMFileName] stringByDeletingPathExtension] stringByAppendingPathExtension:MGMMP4Ext]] forKey:MGMFilePath];
				[taskInfo setObject:[taskInfo objectForKey:MGMYVTaskPath] forKey:MGMRevealPath];
				
				NSFileManager *fileManager = [NSFileManager defaultManager];
                [fileManager createDirectoryAtPath:[taskInfo objectForKey:MGMYVTaskPath] withAttributes:nil];
				
				NSString *imageURL = [NSString stringWithFormat:MGMYTImageURL, [entry URLParameterWithName:@"v"]];
				[taskInfo setObject:imageURL forKey:MGMPreviewURL];
				
				[progress setHidden:NO];
				[progress startAnimation:self];
				[progress setIndeterminate:YES];
				[restart setHidden:YES];
				[stop setHidden:NO];
				
				startTime = [[NSDate date] timeIntervalSince1970];
				[taskInfo setObject:[entry absoluteString] forKey:MGMURL];
				[self setName];
				videoFinder = [[MGMVideoFinder alloc] initWithURL:[NSURL URLWithString:[taskInfo objectForKey:MGMURL]] connectionManager:connectionManager maxQuality:[[taskInfo objectForKey:MGMMaxQualityKey] intValue] delegate:self];
			} else if ([theTask objectForKey:MGMYVTaskPath]!=nil) {
				if ([[NSFileManager defaultManager] fileExistsAtPath:[[theTask objectForKey:MGMYVTaskPath] stringByAppendingPathComponent:MGMInfoPlist]]) {
					taskInfo = [[NSMutableDictionary dictionaryWithContentsOfFile:[[theTask objectForKey:MGMYVTaskPath] stringByAppendingPathComponent:MGMInfoPlist]] retain];
					if (![[taskInfo objectForKey:MGMYVTaskPath] isEqual:[theTask objectForKey:MGMYVTaskPath]]) {
						NSString *lastPath = [taskInfo objectForKey:MGMYVTaskPath];
						[taskInfo setObject:[theTask objectForKey:MGMYVTaskPath] forKey:MGMYVTaskPath];
						if ([lastPath isEqual:[[taskInfo objectForKey:MGMFilePath] stringByDeletingLastPathComponent]]) {
							[taskInfo setObject:[[taskInfo objectForKey:MGMYVTaskPath] stringByAppendingPathComponent:[[taskInfo objectForKey:MGMFilePath] lastPathComponent]] forKey:MGMFilePath];
						}
						[taskInfo setObject:[[[taskInfo objectForKey:MGMYVTaskPath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:[taskInfo objectForKey:MGMFileName]] forKey:MGMDonePath];
						[taskInfo setObject:[taskInfo objectForKey:MGMYVTaskPath] forKey:MGMRevealPath];
					}
					[self setName];
					[info setStringValue:@"Click restart to start"];
					[stop setHidden:YES];
					[restart setHidden:NO];
					[progress setHidden:YES];
				} else {
					NSBeep();
					[self release];
					self = nil;
				}
			} else if ([theTask objectForKey:MGMFilePath]!=nil) {
				taskInfo = [[NSMutableDictionary dictionaryWithDictionary:theTask] retain];
				[taskInfo setObject:[[taskInfo objectForKey:MGMDonePath] lastPathComponent] forKey:MGMFileName];
				[taskInfo setObject:[[taskInfo objectForKey:MGMDonePath] stringByAppendingPathExtension:MGMYVTaskExt] forKey:MGMYVTaskPath];
				[taskInfo setObject:[taskInfo objectForKey:MGMYVTaskPath] forKey:MGMRevealPath];
				
				NSFileManager *fileManager = [NSFileManager defaultManager];
                [fileManager createDirectoryAtPath:[taskInfo objectForKey:MGMYVTaskPath] withAttributes:nil];
				
				[self setName];
			} else {
				NSBeep();
				[self release];
				self = nil;
			}
			if ([taskInfo objectForKey:MGMPreviewURL]!=nil) {
#if youviewdebug
				MGMLog(@"URL: %@", [taskInfo objectForKey:MGMPreviewURL]);
#endif
				NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[taskInfo objectForKey:MGMPreviewURL]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
				MGMURLBasicHandler *handler = [MGMURLBasicHandler handlerWithRequest:theRequest delegate:self];
				[handler setFailWithError:@selector(iconLoader:didFailWithError:)];
				[handler setFinish:@selector(iconLoaderDidFinish:)];
				[connectionManager addHandler:handler];
			} else {
				[icon setImage:[NSImage imageNamed:@"YouViewA"]];
			}
		}
    }
    return self;
}
- (void)dealloc {
#if releaseDebug
	MGMLog(@"%s Releasing", __PRETTY_FUNCTION__);
#endif
	[manager release];
	[mainView release];
	[taskInfo release];
	[entry release];
	[connectionManager cancelAll];
	[connectionManager release];
	[videoFinder release];
	[secCheckTimer invalidate];
	[secCheckTimer release];
	[receivedSec release];
	[aTask terminate];
	[aTask release];
	[taskPipe release];
    [super dealloc];
}

- (void)iconLoader:(MGMURLBasicHandler *)theHandler didFailWithError:(NSError *)theError {
	NSLog(@"Error loading image: %@", theError);
}
- (void)iconLoaderDidFinish:(MGMURLBasicHandler *)theHandler {
	NSImage *image = [[[NSImage alloc] initWithData:[theHandler data]] autorelease];
	[icon setImage:image];
}

- (void)setName {
	if ([[taskInfo objectForKey:MGMConverting] boolValue]) {
		[name setStringValue:[taskInfo objectForKey:MGMFileName]];
	} else {
		[name setStringValue:[[taskInfo objectForKey:MGMFilePath] lastPathComponent]];
	}
}
- (NSString *)YVTaskPath {
	return [taskInfo objectForKey:MGMYVTaskPath];
}
- (BOOL)working {
	return working;
}
- (BOOL)converting {
	return converting;
}
- (BOOL)waitingToConvert {
	return waitingToConvert;
}
- (NSView *)view {
	return mainView;
}

- (NSString *)accessibilityRole {
	return @"task";
}
- (NSString *)accessibilityDescription {
	NSString *taskName = [[taskInfo objectForKey:MGMFilePath] lastPathComponent];
	if ([[taskInfo objectForKey:MGMConverting] boolValue])
		taskName = [taskInfo objectForKey:MGMFileName];
	return [NSString stringWithFormat:@"%@ %@", taskName, [info stringValue]];
}

- (IBAction)stop:(id)sender {
	stopped = YES;
	if (working) {
		if (converting || waitingToConvert) {
			[[NSNotificationCenter defaultCenter] removeObserver:self];
			[aTask terminate];
			[aTask release];
			aTask = nil;
			[taskInfo setObject:[NSNumber numberWithBool:YES] forKey:MGMConverting];
			[self saveInfo];
		} else {
			[connectionManager cancelAll];
			[taskInfo setObject:[NSNumber numberWithBool:NO] forKey:MGMConverting];
			[self saveInfo];
		}
		[info setStringValue:@"Canceled"];
	}
}
- (IBAction)reveal:(id)sender {
	[[NSWorkspace sharedWorkspace] selectFile:[taskInfo objectForKey:MGMRevealPath] inFileViewerRootedAtPath:nil];
}
- (IBAction)restart:(id)sender {
	stopped = NO;
	startTime = [[NSDate date] timeIntervalSince1970]-[[taskInfo objectForKey:MGMTime] intValue];
	if ([[taskInfo objectForKey:MGMConverting] boolValue]) {
		[progress setHidden:NO];
		[progress startAnimation:self];
		[stop setHidden:NO];
		[restart setHidden:YES];
		working = YES;
		if ([manager ableToConvert:self]) {
			[self startConverson];
		} else {
			[info setStringValue:@"Waiting my turn to convert."];
			waitingToConvert = YES;
		}
	} else {
		[progress setHidden:NO];
		[progress startAnimation:self];
		[progress setIndeterminate:YES];
		
		[videoFinder release];
		videoFinder = [[MGMVideoFinder alloc] initWithURL:[NSURL URLWithString:[taskInfo objectForKey:MGMURL]] connectionManager:connectionManager maxQuality:[[taskInfo objectForKey:MGMMaxQualityKey] intValue] delegate:self];
	}
	[self setName];
}

- (void)saveInfo {
	if (secCheckTimer!=nil) {
		[secCheckTimer invalidate];
		[secCheckTimer release];
		secCheckTimer = nil;
	}
	working = NO;
	converting = NO;
	waitingToConvert = NO;
	[progress setHidden:YES];
	[progress stopAnimation:self];
	[stop setHidden:YES];
	[restart setHidden:NO];
	[taskInfo setObject:[NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]-startTime] forKey:MGMTime];
	[taskInfo writeToFile:[[taskInfo objectForKey:MGMYVTaskPath] stringByAppendingPathComponent:MGMInfoPlist] atomically:YES];
}

- (void)loadFlash:(NSDictionary *)theInfo {
	if ([taskInfo objectForKey:MGMConvertFormat]==nil) {
		NSAlert *theAlert = [[NSAlert new] autorelease];
		[theAlert setMessageText:@"Video Download"];
		[theAlert setInformativeText:@"YouView was unable to download the video, would you like to download the low quality version?"];
		[theAlert addButtonWithTitle:@"Yes"];
		[theAlert addButtonWithTitle:@"No"];
		int result = [theAlert runModal];
		if (result==1000) {
			[videoFinder loadFlash];
		}
	} else {
		[videoFinder loadFlash];
	}
}
- (void)loadVideo:(NSDictionary *)theInfo {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[taskInfo setObject:[taskInfo objectForKey:MGMYVTaskPath] forKey:MGMRevealPath];
	if ([[theInfo objectForKey:MGMVLVersion] isEqual:@"FLV"]) {
		[taskInfo setObject:[[[taskInfo objectForKey:MGMFilePath] stringByDeletingPathExtension] stringByAppendingPathExtension:MGMFLVExt] forKey:MGMFilePath];
		[self setName];
		if ([taskInfo objectForKey:MGMConvertFormat]==nil) {
			[taskInfo setObject:[[[taskInfo objectForKey:MGMDonePath] stringByDeletingPathExtension] stringByAppendingPathExtension:MGMFLVExt] forKey:MGMDonePath];
			[taskInfo setObject:[[taskInfo objectForKey:MGMDonePath] lastPathComponent] forKey:MGMFileName];
			NSString *lastPath = [taskInfo objectForKey:MGMYVTaskPath];
			[taskInfo setObject:[[taskInfo objectForKey:MGMDonePath] stringByAppendingPathExtension:MGMYVTaskExt] forKey:MGMYVTaskPath];
			if ([[taskInfo objectForKey:MGMDonePath] isEqual:[[taskInfo objectForKey:MGMFilePath] stringByDeletingLastPathComponent]]) {
				[taskInfo setObject:[[taskInfo objectForKey:MGMYVTaskPath] stringByAppendingPathComponent:[[taskInfo objectForKey:MGMFilePath] lastPathComponent]] forKey:MGMFilePath];
			}
            [fileManager moveItemAtPath:lastPath toPath:[taskInfo objectForKey:MGMYVTaskPath]];
		}
	}
	MGMURLBasicHandler *handler = [MGMURLBasicHandler handlerWithRequest:[NSURLRequest requestWithURL:[theInfo objectForKey:MGMVLVideoURLKey]] delegate:self];
	[handler setFile:[taskInfo objectForKey:MGMFilePath]];
	[handler setBytesReceived:@selector(fileDownload:receivedBytes:totalBytes:expectedBytes:)];
	[handler setReceiveResponse:@selector(fileDownload:didReceiveResponse:)];
	[handler setFailWithError:@selector(fileDownload:didFailWithError:)];
	[handler setFinish:@selector(fileDownloadDidFinish:)];
	[connectionManager addHandler:handler];
	
	[progress setHidden:NO];
	[progress stopAnimation:self];
	[progress setIndeterminate:NO];
	[progress setDoubleValue:0];
	[restart setHidden:YES];
	[stop setHidden:NO];
	working = YES;
	[receivedSec release];
	receivedSec = [@"0 Bytes" retain];
	bytesReceivedSec = 1;
	receivedContentLength = 0;
	expectedContentLength = 0;
	if (secCheckTimer==nil) {
		secCheckTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(secCheck) userInfo:nil repeats:YES] retain];
	}
}


- (NSString *)bytesToString:(double)bytes {
	NSString *type = @"Bytes";
	if (bytes>1024.00) {
		type = @"KB";
		bytes = bytes/1024.00;
		if (bytes>1024.00) {
			type = @"MB";
			bytes = bytes/1024.00;
			if (bytes>1024.00) {
				type = @"GB";
				bytes = bytes/1024.00;
			}
		}
	}
	return [NSString stringWithFormat:@"%.2f %@", bytes, type];
}

- (NSString *)secsToString:(int)secs {
	NSString *type = @"Second";
	if (secs>60) {
		type = @"Minute";
		secs = secs/60;
		if (secs>60) {
			type = @"Hour";
			secs = secs/60;
			if (secs>24) {
				type = @"Day";
				secs = secs/24;
			}
		}
	}
	return [NSString stringWithFormat:@"%d %@%@", secs, type, (secs==1 ? @"" : @"s")];
}

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)didFinish {
	if (didFinish)
		[sound release];
}

- (void)convertProcessFinish:(NSNotification *)note {
	if (!stopped) {
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		[aTask release];
		aTask = nil;
		[taskPipe release];
		taskPipe = nil;
		working = NO;
		converting = NO;
		[[NSFileManager defaultManager] moveItemAtPath:[taskInfo objectForKey:MGMConvertPath] toPath:[taskInfo objectForKey:MGMDonePath]];
		[[NSFileManager defaultManager] removeItemAtPath:[taskInfo objectForKey:MGMYVTaskPath]];
		[taskInfo setObject:[taskInfo objectForKey:MGMDonePath] forKey:MGMRevealPath];
		int runTime = [[NSDate date] timeIntervalSince1970]-startTime;
		[info setStringValue:[NSString stringWithFormat:@"Finished Task in %@", [self secsToString:runTime]]];
		[progress setHidden:YES];
		[progress stopAnimation:self];
		[stop setHidden:YES];
		NSSound *done = [[NSSound soundNamed:@"Glass"] retain];
		[done setDelegate:self];
		[done play];
		[manager nextConversion];
	}
}
- (void)convertProcessResponse:(NSString*)response {
    if ([response hasPrefix:@"frame="]) {
        NSRange f, l;
		NSString *s;
		int frame=0, fps=0;
		f = [response rangeOfString:@"frame="];
		if (f.location != NSNotFound) {
			s = [response substringFromIndex:f.location + f.length];
			
			l = [s rangeOfString:@"fps"];
			if (l.location == NSNotFound) MGMLog(@"failed");
			frame = [[s substringWithRange:NSMakeRange(0, l.location)] intValue];
		}
		f = [response rangeOfString:@"fps="];
		if (f.location != NSNotFound) {
			s = [response substringFromIndex:f.location + f.length];
			
			l = [s rangeOfString:@"q"];
			if (l.location == NSNotFound) MGMLog(@"failed");
			fps = [[s substringWithRange:NSMakeRange(0, l.location)] intValue];
			if (fps==0) {
                fps = frame;
            }
		}
		int totalFrames = videoPlayTime * videoFrameRate;
		[progress setDoubleValue:(double)frame / (double)totalFrames];
		int timeLeft = 0;
        if (frame!=0 && fps!=0)
            timeLeft = (totalFrames-frame)/fps;
		[info setStringValue:[NSString stringWithFormat:@"%d FPS current frame %d - %@", fps, frame, [self secsToString:timeLeft]]];
    } else if ([response hasPrefix:@"size"]) {
		NSRange f, l;
		NSString *s, *bitrate = nil;
		double lasttime = time;
		f = [response rangeOfString:@"time="];
		if (f.location != NSNotFound) {
			s = [response substringFromIndex:f.location + f.length];
			
			l = [s rangeOfString:@"bitrate"];
			if (l.location == NSNotFound) MGMLog(@"failed");
			time = [[s substringWithRange:NSMakeRange(0, l.location)] doubleValue];
		}
		f = [response rangeOfString:@"bitrate="];
		if (f.location != NSNotFound) {
			bitrate = [[[response substringFromIndex:f.location + f.length] replace:@"\r" with:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		}
		[progress setDoubleValue:time / videoPlayTime];
		int timeLeft = (videoPlayTime-time)/(time-lasttime);
        if (bitrate!=nil)
            [info setStringValue:[NSString stringWithFormat:@"Bitrate %@ - %@", bitrate, [self secsToString:timeLeft]]];
	} else {
		if ([response length] > 0)
            MGMLog(@"Task: %@", response);
	}
}
- (void)convertProcessRead:(NSNotification *)note {
	if (![[note name] isEqual:NSFileHandleReadCompletionNotification])
        return;
	
	NSData	*data = [[note userInfo] objectForKey:NSFileHandleNotificationDataItem];
	
	if ([data length]) {
		NSMutableString *buffer = [NSMutableString string];
		NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        
        NSArray *components = [string componentsSeparatedByString:@"\n"];
        assert([components count] > 0);
        for (int i = 0; i < [components count]-1; ++i) {
            [buffer appendString:[components objectAtIndex:i]];
            [self convertProcessResponse:buffer];
            [buffer setString: @""];
        }
        
        if ([string hasSuffix:@"\n"] || [string hasSuffix:@"\r"]) {
            [buffer appendString:[components objectAtIndex:[components count]-1]];
            [self convertProcessResponse:buffer];
            [buffer setString:@""];
        }
        else {
            [buffer setString:[components objectAtIndex:[components count]-1]];
        }
		[[note object] readInBackgroundAndNotify];
    }
}

- (void)startConverson {
	converting = YES;
	waitingToConvert = NO;
	[taskInfo setObject:[NSNumber numberWithBool:YES] forKey:MGMConverting];
	NSString *file = [[self YVTaskPath] stringByAppendingPathComponent:[[[taskInfo objectForKey:MGMFilePath] lastPathComponent] stringByDeletingPathExtension]];
	[taskInfo setObject:[[file stringByAppendingPathExtension:@"tmp"] stringByAppendingPathExtension:[[[manager formats] objectAtIndex:[[taskInfo objectForKey:MGMConvertFormat] intValue]] objectForKey:MGMFExtension]] forKey:MGMConvertPath];
	[self setName];
	
	NSTask *task = [[NSTask new] autorelease];
	[task setLaunchPath:[[NSBundle mainBundle] pathForResource:@"mediainfo" ofType:@""]];
	[task setArguments:[NSArray arrayWithObjects:[@"--Inform=file://" stringByAppendingString:[[NSBundle mainBundle] pathForResource:@"mediainfo" ofType:@"form"]], [taskInfo objectForKey:MGMFilePath], nil]];
	
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput:[pipe fileHandleForWriting]];
	[task launch];
	[task waitUntilExit];
	
	NSString *error = nil;
	NSMutableData *plistData = [NSMutableData data];
	[plistData appendData:[@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\r\n<plist version=\"1.0\">\r\n<array>\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[plistData appendData:[[pipe fileHandleForReading] availableData]];
	[plistData appendData:[@"\r\n</array>\r\n</plist>" dataUsingEncoding:NSUTF8StringEncoding]];
	NSArray *plist = [NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&error];
	
	if (error!=nil) {
		MGMLog(@"Error %@", error);
		NSAlert *theAlert = [[NSAlert new] autorelease];
		[theAlert addButtonWithTitle:@"OK"];
		[theAlert setMessageText:@"Convert Error"];
		[theAlert setInformativeText:error];
		[theAlert setAlertStyle:NSWarningAlertStyle];
		[theAlert runModal];
	} else {
		[taskInfo setObject:plist forKey:MGMMediaInfoKey];
		if ([taskInfo objectForKey:MGMPreviewURL]==nil) {
			int playTime = 0;
			NSSize originalSize = NSZeroSize;
			for (int i=0; i<[[taskInfo objectForKey:MGMMediaInfoKey] count]; i++) {
				if ([[[[taskInfo objectForKey:MGMMediaInfoKey] objectAtIndex:i] objectForKey:MGMTypeKey] isEqual:MGMTypeGeneralKey]) {
					playTime = [[[[taskInfo objectForKey:MGMMediaInfoKey] objectAtIndex:i] objectForKey:MGMPlayTimeKey] intValue]/1000;
				} else if ([[[[taskInfo objectForKey:MGMMediaInfoKey] objectAtIndex:i] objectForKey:MGMTypeKey] isEqual:MGMTypeVideoKey]) {
					originalSize.width = [[[[taskInfo objectForKey:MGMMediaInfoKey] objectAtIndex:i] objectForKey:MGMWidthKey] intValue];
					originalSize.height = [[[[taskInfo objectForKey:MGMMediaInfoKey] objectAtIndex:i] objectForKey:MGMHeightKey] intValue];
				}
			}
			if (!NSEqualSizes(originalSize, NSZeroSize)) {
				NSTask *task = [[NSTask new] autorelease];
				[task setLaunchPath:[[NSBundle mainBundle] pathForResource:@"ffmpeg" ofType:@""]];
				if (playTime>8)
					playTime = 8;
				NSSize destSize = NSMakeSize(128, 128);
				float scaleFactor  = 0.0;
				float scaledWidth  = destSize.width;
				float scaledHeight = destSize.height;
				
				if (NSEqualSizes(originalSize, destSize) == NO) {
					float widthFactor  = destSize.width / originalSize.width;
					float heightFactor = destSize.height / originalSize.height;
					
					if (widthFactor < heightFactor)
						scaleFactor = widthFactor;
					else
						scaleFactor = heightFactor;
					
					scaledWidth = (int)(originalSize.width  * scaleFactor);
					scaledHeight = (int)(originalSize.height * scaleFactor);
					if ((scaledWidth/2.0)!=(float)((int)(scaledWidth/2.0)))
						scaledWidth -= 1;
					if ((scaledHeight/2.0)!=(float)((int)(scaledHeight/2.0)))
						scaledHeight -= 1;
				}
				srandomdev();
				NSString *savePath = [[[MGMUser cachePath] stringByAppendingPathComponent:[[[NSNumber numberWithInt:random()] stringValue] MD5]] stringByAppendingPathExtension:MGMJPGExt];
				[task setArguments:[NSArray arrayWithObjects:@"-y", @"-i", [taskInfo objectForKey:MGMFilePath], @"-f", @"image2", @"-ss", [[NSNumber numberWithInt:playTime] stringValue], @"-sameq", @"-t", @"0.001", @"-s", [NSString stringWithFormat:@"%.0fx%.0f", scaledWidth, scaledHeight], savePath, nil]];
				[task launch];
				[task waitUntilExit];
				if ([task terminationStatus]==0) {
					[taskInfo setObject:[[NSURL fileURLWithPath:savePath] absoluteString] forKey:MGMPreviewURL];
					NSImage *image = [[[NSImage alloc] initWithContentsOfFile:savePath] autorelease];
					[icon setImage:image];
				}
			}
		}
		
		
		[taskInfo setObject:[NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]-startTime] forKey:MGMTime];
		[taskInfo writeToFile:[[taskInfo objectForKey:MGMYVTaskPath] stringByAppendingPathComponent:MGMInfoPlist] atomically:YES];
		
		aTask = [NSTask new];
		[aTask setLaunchPath:[[NSBundle mainBundle] pathForResource:@"ffmpeg" ofType:@""]];
		NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"-y", @"-i", [taskInfo objectForKey:MGMFilePath], nil];
		[arguments addObjectsFromArray:[[[manager formats] objectAtIndex:[[taskInfo objectForKey:MGMConvertFormat] intValue]] objectForKey:MGMFArguments]];
		int currFormat = [[taskInfo objectForKey:MGMConvertFormat] intValue];
#if youviewdebug
		MGMLog(@"Format: %d", currFormat);
#endif
		if ([taskInfo objectForKey:MGMCustomBitrateKey]!=nil)
			[arguments addObjectsFromArray:[NSArray arrayWithObjects:@"-b", [taskInfo objectForKey:MGMCustomBitrateKey], nil]];
		if (currFormat!=2 && currFormat!=3 && currFormat!=5 && currFormat!=8)
			[arguments addObjectsFromArray:[NSArray arrayWithObjects:@"-threads", [NSString stringWithFormat:@"%d", [[MGMSystemInfo info] CPUCount]], nil]];
		for (int i=0; i<[[taskInfo objectForKey:MGMMediaInfoKey] count]; i++) {
			if ([[[[taskInfo objectForKey:MGMMediaInfoKey] objectAtIndex:i] objectForKey:MGMTypeKey] isEqual:MGMTypeGeneralKey]) {
				videoPlayTime = [[[[taskInfo objectForKey:MGMMediaInfoKey] objectAtIndex:i] objectForKey:MGMPlayTimeKey] doubleValue]/1000.0;
				break;
			}
		}
		if (![[taskInfo objectForKey:MGMFAudio] boolValue]) {
			for (int i=0; i<[[taskInfo objectForKey:MGMMediaInfoKey] count]; i++) {
				if ([[[[taskInfo objectForKey:MGMMediaInfoKey] objectAtIndex:i] objectForKey:MGMTypeKey] isEqual:MGMTypeVideoKey]) {
					videoFrameRate = [[[[taskInfo objectForKey:MGMMediaInfoKey] objectAtIndex:i] objectForKey:MGMFrameRateKey] doubleValue];
					[arguments addObjectsFromArray:[NSArray arrayWithObjects:@"-r", [[[taskInfo objectForKey:MGMMediaInfoKey] objectAtIndex:i] objectForKey:MGMFrameRateKey], nil]];
					break;
				}
			}
		}
		for (int i=0; i<[[taskInfo objectForKey:MGMMediaInfoKey] count]; i++) {
			if ([[[[taskInfo objectForKey:MGMMediaInfoKey] objectAtIndex:i] objectForKey:MGMTypeKey] isEqual:MGMTypeAudioKey]) {
				[arguments addObjectsFromArray:[NSArray arrayWithObjects:@"-ar", [[[taskInfo objectForKey:MGMMediaInfoKey] objectAtIndex:i] objectForKey:MGMSamplingRateKey], @"-ab", [[[taskInfo objectForKey:MGMMediaInfoKey] objectAtIndex:i] objectForKey:MGMBitrateKey], nil]];
				break;
			}
		}
		
		if ([taskInfo objectForKey:MGMCustomWidthKey]!=nil && [taskInfo objectForKey:MGMCustomHeightKey]!=nil) {
			[arguments addObjectsFromArray:[NSArray arrayWithObjects:@"-s", [NSString stringWithFormat:@"%@x%@", [taskInfo objectForKey:MGMCustomWidthKey], [taskInfo objectForKey:MGMCustomHeightKey]], nil]];
		} else if ([taskInfo objectForKey:MGMCustomWidthKey]!=nil) {
			[arguments addObjectsFromArray:[NSArray arrayWithObjects:@"-s", [NSString stringWithFormat:@"%@x%@", [taskInfo objectForKey:MGMCustomWidthKey], [taskInfo objectForKey:MGMHeightKey]], nil]];
		} else if ([taskInfo objectForKey:MGMCustomHeightKey]!=nil) {
			[arguments addObjectsFromArray:[NSArray arrayWithObjects:@"-s", [NSString stringWithFormat:@"%@x%@", [taskInfo objectForKey:MGMWidthKey], [taskInfo objectForKey:MGMCustomHeightKey]], nil]];
		} else if ([taskInfo objectForKey:MGMCustomBitrateKey]==nil) {
            for (int i=0; i<[[taskInfo objectForKey:MGMMediaInfoKey] count]; i++) {
				if ([[[[taskInfo objectForKey:MGMMediaInfoKey] objectAtIndex:i] objectForKey:MGMTypeKey] isEqual:MGMTypeVideoKey]) {
					[arguments addObjectsFromArray:[NSArray arrayWithObjects:@"-b", [[[taskInfo objectForKey:MGMMediaInfoKey] objectAtIndex:i] objectForKey:MGMBitrateKey], nil]];
					break;
				}
			}
		}
		[arguments addObject:[taskInfo objectForKey:MGMConvertPath]];
#if youviewdebug
		NSLog(@"Task Info: %@", taskInfo);
		NSLog(@"Arugments: %@", arguments);
#endif
		[aTask setArguments:arguments];
		taskPipe = [NSPipe new];
		[aTask setStandardError:[taskPipe fileHandleForWriting]];
		[aTask setStandardOutput:[taskPipe fileHandleForWriting]];
		
		int runTime = [[NSDate date] timeIntervalSince1970]-startTime;
		[taskInfo setObject:[NSNumber numberWithInt:runTime] forKey:MGMTime];
		[info setStringValue:[NSString stringWithFormat:@"%@ downloaded at %@/sec and took %@", [self bytesToString:receivedContentLength], receivedSec, [self secsToString:runTime]]];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(convertProcessFinish:) name:NSTaskDidTerminateNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(convertProcessRead:) name:NSFileHandleReadCompletionNotification object:[taskPipe fileHandleForReading]];
		[[taskPipe fileHandleForReading] readInBackgroundAndNotify];
		[aTask launch];
	}
}

- (void)setDownloading:(BOOL)isDownloading {
	if (working != isDownloading) {
		working = isDownloading;
		[secCheckTimer invalidate];
		[secCheckTimer release];
		secCheckTimer = nil;
		if (!working) {
			if ([taskInfo objectForKey:MGMConvertFormat]!=nil) {
				working = YES;
				if ([manager ableToConvert:self]) {
					[self startConverson];
				} else {
					[info setStringValue:@"Waiting my turn to convert."];
					waitingToConvert = YES;
				}
			} else {
				[[NSFileManager defaultManager] moveItemAtPath:[taskInfo objectForKey:MGMFilePath] toPath:[taskInfo objectForKey:MGMDonePath]];
				[[NSFileManager defaultManager] removeItemAtPath:[taskInfo objectForKey:MGMYVTaskPath]];
				[taskInfo setObject:[taskInfo objectForKey:MGMDonePath] forKey:MGMRevealPath];
				int runTime = [[NSDate date] timeIntervalSince1970]-startTime;
				[info setStringValue:[NSString stringWithFormat:@"%@ downloaded at %@/sec and took %@", [self bytesToString:receivedContentLength], receivedSec, [self secsToString:runTime]]];
				[progress setHidden:YES];
				[progress stopAnimation:self];
				[stop setHidden:YES];
				NSSound *done = [[NSSound soundNamed:@"Glass"] retain];
				[done setDelegate:self];
				[done play];
			}
		}
	}
}
- (void)secCheck {
	[receivedSec release];
	receivedSec = [[self bytesToString:(double)bytesReceived] retain];
	bytesReceivedSec = (bytesReceived==0 ? 1 : bytesReceived);
	bytesReceived = 0;
	int secs = (expectedContentLength-receivedContentLength)/bytesReceivedSec;
	[info setStringValue:[NSString stringWithFormat:@"%@ of %@ (%@/sec) - %@", [self bytesToString:(double)receivedContentLength], [self bytesToString:(double)expectedContentLength], receivedSec, [self secsToString:secs]]];
}
- (void)fileDownload:(MGMURLBasicHandler *)theHandler didReceiveResponse:(NSHTTPURLResponse *)theResponse {
	//NSLog(@"Got response %d", [theResponse statusCode]);
	[self setDownloading:YES];
}

- (void)fileDownload:(MGMURLBasicHandler *)theHandler receivedBytes:(unsigned long)theBytes totalBytes:(unsigned long)theTotalBytes expectedBytes:(unsigned long)theExpectedBytes {
	expectedContentLength = theExpectedBytes;
	receivedContentLength = theTotalBytes;
	bytesReceived += theBytes;
	[progress setDoubleValue:(double)theTotalBytes/(double)theExpectedBytes];
}
- (void)fileDownload:(MGMURLBasicHandler *)theHandler didFailWithError:(NSError *)error {
	NSLog(@"%@", error);
	[self saveInfo];
	if ([[videoFinder version] isEqual:@"FLV"]) {
		[info setStringValue:@"Error"];
		NSAlert *theAlert = [[NSAlert new] autorelease];
		[theAlert addButtonWithTitle:@"OK"];
		[theAlert setMessageText:@"Video Downloading"];
		[theAlert setInformativeText:@"YouView was unable to download the video.\nPlease contact support via the help menu."];
		[theAlert runModal];
	} else {
		[videoFinder shouldLoadFlash];
	}
}
- (void)fileDownloadDidFinish:(MGMURLBasicHandler *)theHandler {
	[self setDownloading:NO];
}
@end