//
//  MGMVideoFinder.m
//  YouView
//
//  Created by Mr. Gecko on 8/3/10.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import "MGMVideoFinder.h"
#import "MGMController.h"
#import "MGMAddons.h"
#import "MGMParentalControls.h"
#import <MGMUsers/MGMUsers.h>
#import <GeckoReporter/GeckoReporter.h>

NSString * const MGMVLVideoURLKey = @"videoURL";
NSString * const MGMVLAudioURLKey = @"audioURL";
NSString * const MGMVLURLKey = @"URL";
NSString * const MGMVLTitle = @"title";
NSString * const MGMVLVersion = @"version";

NSString * const MGMULType = @"type";
NSString * const MGMULTag = @"itag";
NSString * const MGMULURL = @"url";

NSString * const MGMVTType = @"type";
NSString * const MGMVTQuality = @"quality";
NSString * const MGMVTAudio = @"audio";
NSString * const MGMVTVideo = @"video";
NSString * const MGMVT3D = @"3D";

@implementation MGMVideoFinder
- (id)initWithURL:(NSURL *)theURL connectionManager:(MGMURLConnectionManager *)theConnectionManager maxQuality:(int)theMaxQuality delegate:(id)theDelegate {
	if (self = [super init]) {
		if (theURL==nil || theDelegate==nil) {
			[self release];
			self = nil;
		} else {
			maxQuality = theMaxQuality;
			requestingSD = NO;
			videoURLS = [NSMutableArray new];
			URL = [theURL retain];
			delegate = theDelegate;
			if (theConnectionManager!=nil) {
				connectionManager = [theConnectionManager retain];
			} else {
				connectionManager = [[MGMURLConnectionManager manager] retain];
				[connectionManager setUserAgent:MGMUserAgent];
			}
#if youviewdebug
			NSLog(@"Finding video for %@", theURL);
#endif
			NSURLRequest *theRequest = [NSURLRequest requestWithURL:theURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
			MGMURLBasicHandler *handler = [MGMURLBasicHandler handlerWithRequest:theRequest delegate:self];
			[connectionManager addHandler:handler];
            
            
            videoQualities = [NSMutableDictionary new];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"3GP", MGMVTType, @"144p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"13"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"3GP", MGMVTType, @"144p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"17"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"3GP", MGMVTType, @"240p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"36"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"FLV", MGMVTType, @"240p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"5"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"FLV", MGMVTType, @"270p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"6"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"FLV", MGMVTType, @"360p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"34"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"FLV", MGMVTType, @"480p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"35"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"MP4", MGMVTType, @"480p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"18"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"MP4", MGMVTType, @"720p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"22"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"MP4", MGMVTType, @"1080p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"37"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"MP4", MGMVTType, @"2160p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"38"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"MP4", MGMVTType, @"144p", MGMVTQuality, [NSNumber numberWithBool:NO], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"160"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"MP4", MGMVTType, @"240p", MGMVTQuality, [NSNumber numberWithBool:NO], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"133"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"MP4", MGMVTType, @"360p", MGMVTQuality, [NSNumber numberWithBool:NO], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"134"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"MP4", MGMVTType, @"480p", MGMVTQuality, [NSNumber numberWithBool:NO], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"135"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"MP4", MGMVTType, @"720p", MGMVTQuality, [NSNumber numberWithBool:NO], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"136"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"MP4", MGMVTType, @"1080p", MGMVTQuality, [NSNumber numberWithBool:NO], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"137"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"MP4", MGMVTType, @"1440p", MGMVTQuality, [NSNumber numberWithBool:NO], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"264"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"MP4", MGMVTType, @"2160p", MGMVTQuality, [NSNumber numberWithBool:NO], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"138"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"M4A", MGMVTType, @"48Kbps", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:NO], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"139"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"M4A", MGMVTType, @"128kbps", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:NO], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"140"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"M4A", MGMVTType, @"256kbps", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:NO], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"141"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"WEBM", MGMVTType, @"128kbps", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:NO], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"171"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"WEBM", MGMVTType, @"192kbps", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:NO], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"172"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"MP4", MGMVTType, @"240p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:YES], MGMVT3D, nil] forKey:@"83"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"MP4", MGMVTType, @"360p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:YES], MGMVT3D, nil] forKey:@"82"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"MP4", MGMVTType, @"520p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:YES], MGMVT3D, nil] forKey:@"85"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"MP4", MGMVTType, @"720p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:YES], MGMVT3D, nil] forKey:@"84"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"WEBM", MGMVTType, @"360p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"43"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"WEBM", MGMVTType, @"480p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"44"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"WEBM", MGMVTType, @"720p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"45"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"WEBM", MGMVTType, @"1080p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"46"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"WEBM", MGMVTType, @"240p", MGMVTQuality, [NSNumber numberWithBool:NO], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"242"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"WEBM", MGMVTType, @"360p", MGMVTQuality, [NSNumber numberWithBool:NO], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"243"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"WEBM", MGMVTType, @"480p 64kbps", MGMVTQuality, [NSNumber numberWithBool:NO], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"244"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"WEBM", MGMVTType, @"480p 110kbps", MGMVTQuality, [NSNumber numberWithBool:NO], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"245"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"WEBM", MGMVTType, @"480p 210kbps", MGMVTQuality, [NSNumber numberWithBool:NO], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"246"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"WEBM", MGMVTType, @"720p", MGMVTQuality, [NSNumber numberWithBool:NO], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"247"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"WEBM", MGMVTType, @"1080p", MGMVTQuality, [NSNumber numberWithBool:NO], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"248"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"WEBM", MGMVTType, @"1440p", MGMVTQuality, [NSNumber numberWithBool:NO], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"271"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"WEBM", MGMVTType, @"2160p", MGMVTQuality, [NSNumber numberWithBool:NO], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:NO], MGMVT3D, nil] forKey:@"272"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"WEBM", MGMVTType, @"360p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:YES], MGMVT3D, nil] forKey:@"100"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"WEBM", MGMVTType, @"360p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:YES], MGMVT3D, nil] forKey:@"101"];
            [videoQualities setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"WEBM", MGMVTType, @"720p", MGMVTQuality, [NSNumber numberWithBool:YES], MGMVTAudio, [NSNumber numberWithBool:YES], MGMVTVideo, [NSNumber numberWithBool:YES], MGMVT3D, nil] forKey:@"102"];
		}
	}
	return self;
}
- (void)dealloc {
	[URL release];
	[connectionManager cancelAll];
	[connectionManager release];
	[videoURLS release];
    [videoQualities release];
	[title release];
	[version release];
	[super dealloc];
}

- (void)processURLs:(NSArray *)urls {
    for (int i=0; i<[urls count]; i++) {
        NSString *type = [[urls objectAtIndex:i] URLParameterWithName:MGMULType];
        NSString *itag = [[urls objectAtIndex:i] URLParameterWithName:MGMULTag];
        NSString *videoURL = [[urls objectAtIndex:i] URLParameterWithName:MGMULURL];
        NSString *signature = [[urls objectAtIndex:i] URLParameterWithName:@"sig"];
        if (signature==nil)
            signature = [[urls objectAtIndex:i] URLParameterWithName:@"s"];
        if (signature==nil)
            signature = [videoURL URLParameterWithName:@"signature"];
        if ([signature length]==86) {
            NSMutableString *newSignature = [NSMutableString string];
            NSArray *signatureBreakDown = [signature componentsSeparatedByString:@"."];
            if ([signatureBreakDown count]>=2 && [[signatureBreakDown objectAtIndex:0] length]==42 && [[signatureBreakDown objectAtIndex:1] length]==43) {
                [newSignature appendFormat:@"%@.", [[signatureBreakDown objectAtIndex:0] substringFromIndex:2]];
                [newSignature appendString:[[signatureBreakDown objectAtIndex:1] substringToIndex:20]];
                [newSignature appendString:[[signatureBreakDown objectAtIndex:1] substringWithRange:NSMakeRange(39, 1)]];
                [newSignature appendString:[[signatureBreakDown objectAtIndex:1] substringWithRange:NSMakeRange(21, 18)]];
                [newSignature appendString:[[signatureBreakDown objectAtIndex:1] substringWithRange:NSMakeRange(20, 1)]];
            } else if ([signatureBreakDown count]>=2 && [[signatureBreakDown objectAtIndex:0] length]==43 && [[signatureBreakDown objectAtIndex:1] length]==42) {
                [newSignature appendFormat:@"%@.", [[signatureBreakDown objectAtIndex:0] substringFromIndex:3]];
                [newSignature appendString:[[signatureBreakDown objectAtIndex:1] substringToIndex:[[signatureBreakDown objectAtIndex:1] length]-2]];
            }
            if ([newSignature length]!=0) {
                signature = newSignature;
            }
        }
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@&signature=%@", videoURL, signature]];
        [videoURLS addObject:[NSDictionary dictionaryWithObjectsAndKeys:type, MGMULType, itag, MGMULTag, url, MGMULURL, nil]];
    }
}

- (void)handler:(MGMURLBasicHandler *)theHandler didFailWithError:(NSError *)theError {
	[connectionManager release];
	connectionManager = nil;
	NSLog(@"Error Getting Video: %@", theError);
	NSAlert *theAlert = [[NSAlert new] autorelease];
	[theAlert addButtonWithTitle:@"Ok"];
	[theAlert setMessageText:@"Error while finding video"];
	[theAlert setInformativeText:[theError localizedDescription]];
	[theAlert setAlertStyle:2];
	[theAlert runModal];
}
- (void)handlerDidFinish:(MGMURLBasicHandler *)theHandler {
	NSString *receivedString = [theHandler string];
	//NSLog(@"%@", theHandler);
	//NSLog(@"%@", receivedString);
	
	if (![[[theHandler response] MIMEType] containsString:@"text/html"]) {
        NSLog(@"Hello from special loader.");
		NSString *urlMap = nil;
		NSRange range = [receivedString rangeOfString:@"url_encoded_fmt_stream_map\": \""];
		if (range.location!=NSNotFound) {
			NSString *s = [receivedString substringFromIndex:range.location + range.length];
			
			range = [s rangeOfString:@"\""];
			if (range.location!=NSNotFound)
				urlMap = [s substringFromIndex:range.location + range.length];
		}
		if (urlMap==nil) {
			NSRange range = [receivedString rangeOfString:@"url_encoded_fmt_stream_map': '"];
			if (range.location!=NSNotFound) {
				NSString *s = [receivedString substringFromIndex:range.location + range.length];
				
				range = [s rangeOfString:@"'"];
				if (range.location!=NSNotFound)
					urlMap = [s substringFromIndex:range.location + range.length];
			}
		}
		if (urlMap==nil) {
			NSDictionary *parameters = [receivedString URLParameters];
			NSArray *keys = [parameters allKeys];
			for (int i=0; i<[keys count]; i++) {
				if ([[keys objectAtIndex:i] containsString:@"url_encoded_fmt_stream_map"]) {
					urlMap = [parameters objectForKey:[keys objectAtIndex:i]];
				}
			}
		}
        
        NSString *adaptiveMap = nil;
		range = [receivedString rangeOfString:@"adaptive_fmts\": \""];
		if (range.location!=NSNotFound) {
			NSString *s = [receivedString substringFromIndex:range.location + range.length];
			
			range = [s rangeOfString:@"\""];
			if (range.location!=NSNotFound)
				adaptiveMap = [s substringFromIndex:range.location + range.length];
		}
		if (adaptiveMap==nil) {
			NSRange range = [receivedString rangeOfString:@"adaptive_fmts': '"];
			if (range.location!=NSNotFound) {
				NSString *s = [receivedString substringFromIndex:range.location + range.length];
				
				range = [s rangeOfString:@"'"];
				if (range.location!=NSNotFound)
					adaptiveMap = [s substringFromIndex:range.location + range.length];
			}
		}
		if (adaptiveMap==nil) {
			NSDictionary *parameters = [receivedString URLParameters];
			NSArray *keys = [parameters allKeys];
			for (int i=0; i<[keys count]; i++) {
				if ([[keys objectAtIndex:i] containsString:@"adaptive_fmts"]) {
					adaptiveMap = [parameters objectForKey:[keys objectAtIndex:i]];
				}
			}
		}
        
		if (urlMap!=nil) {
			NSArray *urls = [urlMap componentsSeparatedByString:@","];
			[self processURLs:urls];
            NSArray *adaptiveURLs = [adaptiveMap componentsSeparatedByString:@","];
			[self processURLs:adaptiveURLs];
		} else {
			NSLog(@"Unable to find url map.");
		}
#if youviewdebug
		NSLog(@"%@", videoURLS);
#endif
		[self startVideo];
	} else if (![receivedString containsString:@"verify-age"]) {
		NSRange range = NSMakeRange(0, [receivedString length]);
		id config = nil;
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		while (range.length>1) {
			NSRange configRange = [receivedString rangeOfString:@"ytplayer.config = " options:NSCaseInsensitiveSearch range:range];
			if (configRange.location!=NSNotFound) {
				range.location = configRange.location+configRange.length;
				range.length = [receivedString length]-range.location;
				NSRange endRange = [receivedString rangeOfString:@"};" options:NSCaseInsensitiveSearch range:range];
				if (endRange.location==NSNotFound)
					break;
				NSString *configString = [receivedString substringWithRange:NSMakeRange(range.location, (endRange.location+endRange.length)-range.location)];
				range.location = endRange.location+endRange.length;
				range.length = [receivedString length]-range.location;
                
                [config release];
				config = [[configString parseJSON] retain];
				//NSLog(@"%@", config);
				if (config!=nil && [config isKindOfClass:[NSDictionary class]]) {
					if ([config objectForKey:@"args"]!=nil) {
						break;
					}
				} else {
                    [config release];
					config = nil;
				}
			} else {
				break;
			}
			[pool drain];
			pool = [NSAutoreleasePool new];
		}
		[pool drain];
		/*if (config==nil) {
         NSRange range = NSMakeRange(0, [receivedString length]);
         NSAutoreleasePool *pool = [NSAutoreleasePool new];
         while (range.length>1) {
         NSRange configRange = [receivedString rangeOfString:@"ytplayer.config = " options:NSCaseInsensitiveSearch range:range];
         if (configRange.location!=NSNotFound) {
         range.location = configRange.location+configRange.length;
         range.length = [receivedString length]-range.location;
         NSRange endRange = [receivedString rangeOfString:@"};" options:NSCaseInsensitiveSearch range:range];
         if (endRange.location==NSNotFound)
         break;
         NSString *configString = [receivedString substringWithRange:NSMakeRange(range.location, (endRange.location+endRange.length)-range.location)];
         range.location = endRange.location+endRange.length;
         range.length = [receivedString length]-range.location;
         
         [config release];
         config = [[configString parseJSON] retain];
         //NSLog(@"%@", config);
         if (config!=nil && [config isKindOfClass:[NSDictionary class]]) {
         if ([config objectForKey:@"args"]!=nil) {
         break;
         }
         } else {
         [config release];
         config = nil;
         }
         } else {
         break;
         }
         [pool drain];
         pool = [NSAutoreleasePool new];
         }
         [pool drain];
         }*/
        [config autorelease];
		NSString *urlMap = nil;
		NSString *adaptiveMap = nil;
		if (config!=nil && [config isKindOfClass:[NSDictionary class]]) {
			//NSLog(@"%@", config);
            id tmp = [config objectForKey:@"args"];
            if ([tmp isKindOfClass:[NSDictionary class]]) {
				urlMap = [tmp objectForKey:@"url_encoded_fmt_stream_map"];
                adaptiveMap = [tmp objectForKey:@"adaptive_fmts"];
            }
            if (urlMap==nil)
                NSLog(@"%@", config);
		} else {
			NSLog(@"What happened here? %@", config);
		}
		if (urlMap!=nil) {
			NSArray *urls = [urlMap componentsSeparatedByString:@","];
			[self processURLs:urls];
            NSArray *adaptiveURLs = [adaptiveMap componentsSeparatedByString:@","];
			[self processURLs:adaptiveURLs];
		}
#if youviewdebug
		NSLog(@"%@", videoURLS);
#endif
		
		if (title==nil || [title isEqual:@""]) {
			NSString *thisTitle = @"";
			range = [receivedString rangeOfString:@"<title>"];
			if (range.location!=NSNotFound) {
				NSString *s = [receivedString substringFromIndex:range.location + range.length];
				
				range = [s rangeOfString:@"</title>"];
				if (range.location == NSNotFound) NSLog(@"failed");
				thisTitle = [s substringWithRange:NSMakeRange(0, range.location)];
				range = [thisTitle rangeOfString:@"-"];
				if (range.location!=NSNotFound) {
					thisTitle = [thisTitle substringToIndex:range.location];
				}
                thisTitle = [[thisTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] flattenHTML];
#if youviewdebug
                NSLog(@"Found Title: %@", thisTitle);
#endif
			}
			[self setTitle:thisTitle];
		}
		
		if (urlMap==nil) {
			NSDictionary *parameters = [[URL query] URLParameters];
			NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.youtube.com/get_video_info?video_id=%@&asv=3&el=detailpage&hl=en_US&sts=16136", [parameters objectForKey:@"v"]]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
			MGMURLBasicHandler *handler = [MGMURLBasicHandler handlerWithRequest:theRequest delegate:self];
			[connectionManager addHandler:handler];
		} else {
			[self startVideo];
		}
	} else {
		if ([[MGMParentalControls standardParentalControls] boolForKey:MGMAllowFlaggedVideos]) {
			NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.youtube.com/verify_age"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
			[postRequest setHTTPMethod:@"POST"];
			[postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
			[postRequest setHTTPBody:[[NSString stringWithFormat:@"next_url=%@?%@&action_confirm=Confirm%20Birth%20Date", [URL path], [URL query]] dataUsingEncoding:NSASCIIStringEncoding]];
			
			MGMURLBasicHandler *handler = [MGMURLBasicHandler handlerWithRequest:postRequest delegate:self];
			[connectionManager addHandler:handler];
		} else {
			NSAlert *theAlert = [[NSAlert new] autorelease];
			[theAlert addButtonWithTitle:@"OK"];
			[theAlert setMessageText:@"Parental Controls"];
			[theAlert setInformativeText:@"You cannot view this video because it is flagged.\nTo enable watching flagged videos, go to YouView->Parental Controls."];
			[theAlert runModal];
			[connectionManager release];
			connectionManager = nil;
		}
	}
}
- (void)setTitle:(NSString *)theTitle {
	[title release];
	title = [theTitle retain];
}
- (NSString *)title {
	return title;
}
- (void)setVersion:(NSString *)theVersion {
	[version release];
	version = [theVersion retain];
}
- (NSString *)version {
	return version;
}
- (void)startVideo {
	//NSLog(@"%@", videoQualities);
	
	int videoQualityFound = 0;
	NSDictionary *video = nil;
	//int audioQualityFound = 0;
	NSDictionary *audio = nil;
	for (int i=0; i<[videoURLS count]; i++) {
		NSDictionary *videoURL = [videoURLS objectAtIndex:i];
		NSDictionary *videoQuality = [videoQualities objectForKey:[videoURL objectForKey:MGMULTag]];
        NSLog(@"%@ %@ %@", [videoURL objectForKey:MGMULTag], [videoURL objectForKey:MGMULURL], videoQuality);
		if (videoQuality==nil) {
			NSLog(@"Unknown Video Quality %@", videoURL);
			continue;
		}
        /*if (audioQualityFound<3 && ![[videoQuality objectForKey:MGMVTVideo] boolValue] && [[videoQuality objectForKey:MGMVTAudio] boolValue] && [[videoQuality objectForKey:MGMVTType] isEqual:@"M4A"] && [[videoQuality objectForKey:MGMVTQuality] containsString:@"256kbps"]) {
         audioQualityFound = 3;
         audio = videoURL;
         } else if (audioQualityFound<2 && ![[videoQuality objectForKey:MGMVTVideo] boolValue] && [[videoQuality objectForKey:MGMVTAudio] boolValue] && [[videoQuality objectForKey:MGMVTType] isEqual:@"M4A"] && [[videoQuality objectForKey:MGMVTQuality] containsString:@"192kbps"]) {
         audioQualityFound = 2;
         audio = videoURL;
         } else if (audioQualityFound<1 && ![[videoQuality objectForKey:MGMVTVideo] boolValue] && [[videoQuality objectForKey:MGMVTAudio] boolValue] && [[videoQuality objectForKey:MGMVTType] isEqual:@"M4A"] && [[videoQuality objectForKey:MGMVTQuality] containsString:@"128kbps"]) {
         audioQualityFound = 1;
         audio = videoURL;
         } else if (audioQualityFound<=0 && ![[videoQuality objectForKey:MGMVTVideo] boolValue] && [[videoQuality objectForKey:MGMVTAudio] boolValue] && [[videoQuality objectForKey:MGMVTType] isEqual:@"M4A"]) {
         audio = videoURL;
         }*/
        
		if (videoQualityFound<5 && maxQuality>=3 && ![[videoQuality objectForKey:MGMVT3D] boolValue] && [[videoQuality objectForKey:MGMVTVideo] boolValue] && [[videoQuality objectForKey:MGMVTAudio] boolValue] && [[videoQuality objectForKey:MGMVTType] isEqual:@"MP4"] && [[videoQuality objectForKey:MGMVTQuality] containsString:@"2160p"]) {
			videoQualityFound = 5;
			video = videoURL;
			[self setVersion:[videoQuality objectForKey:MGMVTType]];
		} else if (videoQualityFound<4 && maxQuality>=3 && ![[videoQuality objectForKey:MGMVT3D] boolValue] && [[videoQuality objectForKey:MGMVTVideo] boolValue] && [[videoQuality objectForKey:MGMVTAudio] boolValue] && [[videoQuality objectForKey:MGMVTType] isEqual:@"MP4"] && [[videoQuality objectForKey:MGMVTQuality] containsString:@"1440p"]) {
			videoQualityFound = 4;
			video = videoURL;
			[self setVersion:[videoQuality objectForKey:MGMVTType]];
		} else if (videoQualityFound<3 && maxQuality>=2 && ![[videoQuality objectForKey:MGMVT3D] boolValue] && [[videoQuality objectForKey:MGMVTVideo] boolValue] && [[videoQuality objectForKey:MGMVTAudio] boolValue] && [[videoQuality objectForKey:MGMVTType] isEqual:@"MP4"] && [[videoQuality objectForKey:MGMVTQuality] containsString:@"1080p"]) {
			videoQualityFound = 3;
			video = videoURL;
			[self setVersion:[videoQuality objectForKey:MGMVTType]];
		} else if (videoQualityFound<2 && maxQuality>=1 && ![[videoQuality objectForKey:MGMVT3D] boolValue] && [[videoQuality objectForKey:MGMVTVideo] boolValue] && [[videoQuality objectForKey:MGMVTAudio] boolValue] && [[videoQuality objectForKey:MGMVTType] isEqual:@"MP4"] && [[videoQuality objectForKey:MGMVTQuality] containsString:@"720p"]) {
			videoQualityFound = 2;
			video = videoURL;
			[self setVersion:[videoQuality objectForKey:MGMVTType]];
		} else if (videoQualityFound<1 && ![[videoQuality objectForKey:MGMVT3D] boolValue] && [[videoQuality objectForKey:MGMVTVideo] boolValue] && [[videoQuality objectForKey:MGMVTAudio] boolValue] && [[videoQuality objectForKey:MGMVTType] isEqual:@"MP4"] && [[videoQuality objectForKey:MGMVTQuality] containsString:@"480p"]) {
			videoQualityFound = 1;
			video = videoURL;
			[self setVersion:[videoQuality objectForKey:MGMVTType]];
		} else if (videoQualityFound<=0 && ![[videoQuality objectForKey:MGMVT3D] boolValue] && [[videoQuality objectForKey:MGMVTVideo] boolValue] && [[videoQuality objectForKey:MGMVTAudio] boolValue] && [[videoQuality objectForKey:MGMVTType] isEqual:@"MP4"]) {
			video = videoURL;
			[self setVersion:[videoQuality objectForKey:MGMVTType]];
		}
	}
	
	if ([videoURLS count]>0 && video==nil) {
		[self shouldLoadFlash];
		return;
	}
	
#if youviewdebug
	NSLog(@"Using video %@ with %@", [[videoQualities objectForKey:[video objectForKey:MGMULTag]] objectForKey:MGMVTQuality], video);
    if (audio!=nil)
        NSLog(@"Using audio %@ with %@", [[videoQualities objectForKey:[audio objectForKey:MGMULTag]] objectForKey:MGMVTQuality], audio);
#endif
	if (video==nil) {
		NSAlert *theAlert = [[NSAlert new] autorelease];
		[theAlert addButtonWithTitle:@"OK"];
		[theAlert setMessageText:@"Video"];
		[theAlert setInformativeText:@"YouView tried as much as possible and couldn't find the video.\nPlease contact support via the help menu."];
		[theAlert runModal];
	} else {
		NSMutableDictionary *info = [NSMutableDictionary dictionary];
        [info setObject:[video objectForKey:MGMULURL] forKey:MGMVLVideoURLKey];
        
		if (![[[videoQualities objectForKey:[video objectForKey:MGMULTag]] objectForKey:MGMVTAudio] boolValue]) {
            [info setObject:[audio objectForKey:MGMULURL] forKey:MGMVLAudioURLKey];
        }
        [info setObject:URL forKey:MGMVLURLKey];
		[info setObject:title forKey:MGMVLTitle];
		[info setObject:version forKey:MGMVLVersion];
#if youviewdebug
        NSLog(@"Passing %@ to load", info);
#endif
		[delegate loadVideo:info];
	}
}
- (void)loadSD {
#if youviewdebug
	NSLog(@"Finding SD version.");
#endif
	requestingSD = YES;
	NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:MGMYTSDURL, [URL URLParameterWithName:@"v"]]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	MGMURLBasicHandler *handlers = [MGMURLBasicHandler handlerWithRequest:theRequest delegate:self];
	[connectionManager addHandler:handlers];
}
- (void)shouldLoadFlash {
	if (requestingSD) {
		NSMutableDictionary *info = [NSMutableDictionary dictionary];
		[info setObject:URL forKey:MGMVLURLKey];
		[info setObject:title forKey:MGMVLTitle];
		[delegate loadFlash:info];
	} else {
		[self loadSD];
	}
}
- (void)loadFlash {
#if youviewdebug
	NSLog(@"Loading flash version.");
#endif
	int qualityFound = 0;
	NSDictionary *video = nil;
	for (int i=0; i<[videoURLS count]; i++) {
		NSDictionary *videoURL = [videoURLS objectAtIndex:i];
		NSDictionary *videoQuality = [videoQualities objectForKey:[videoURL objectForKey:MGMULTag]];
		if (videoQuality==nil) {
			NSLog(@"Unknown Video Quality %@", [videoURL objectForKey:MGMULTag]);
			continue;
		}
        if (qualityFound<3 && ![[videoQuality objectForKey:MGMVT3D] boolValue] && [[videoQuality objectForKey:MGMVTVideo] boolValue] && [[videoQuality objectForKey:MGMVTAudio] boolValue] && [[videoQuality objectForKey:MGMVTType] isEqual:@"FLV"] && [[videoQuality objectForKey:MGMVTQuality] containsString:@"480p"]) {
            qualityFound = 3;
            video = videoURL;
        } else if (qualityFound<2 && ![[videoQuality objectForKey:MGMVT3D] boolValue] && [[videoQuality objectForKey:MGMVTVideo] boolValue] && [[videoQuality objectForKey:MGMVTAudio] boolValue] && [[videoQuality objectForKey:MGMVTType] isEqual:@"FLV"] && [[videoQuality objectForKey:MGMVTQuality] containsString:@"360p"]) {
            qualityFound = 2;
            video = videoURL;
        } else if (qualityFound<1 && ![[videoQuality objectForKey:MGMVT3D] boolValue] && [[videoQuality objectForKey:MGMVTVideo] boolValue] && [[videoQuality objectForKey:MGMVTAudio] boolValue] && [[videoQuality objectForKey:MGMVTType] isEqual:@"FLV"] && [[videoQuality objectForKey:MGMVTQuality] containsString:@"270p"]) {
            qualityFound = 1;
            video = videoURL;
        } else if (qualityFound<=0 && ![[videoQuality objectForKey:MGMVT3D] boolValue] && [[videoQuality objectForKey:MGMVTVideo] boolValue] && [[videoQuality objectForKey:MGMVTAudio] boolValue] && [[videoQuality objectForKey:MGMVTType] isEqual:@"FLV"]) {
            video = videoURL;
        }
    }
#if youviewdebug
	NSLog(@"Should load video %@ with URL %@.", [[videoQualities objectForKey:[video objectForKey:MGMULTag]] objectForKey:MGMVTQuality], video);
#endif
	if (video==nil) {
		NSAlert *theAlert = [[NSAlert new] autorelease];
		[theAlert addButtonWithTitle:@"OK"];
		[theAlert setMessageText:@"Video"];
		[theAlert setInformativeText:@"YouView tried as much as possible and couldn't find the video.\nPlease contact support via the help menu."];
		[theAlert runModal];
	} else {
		NSMutableDictionary *info = [NSMutableDictionary dictionary];
		[info setObject:[video objectForKey:MGMULURL] forKey:MGMVLVideoURLKey];
		[info setObject:URL forKey:MGMVLURLKey];
		[info setObject:title forKey:MGMVLTitle];
		[info setObject:version forKey:MGMVLVersion];
		[delegate loadVideo:info];
	}
}
@end
