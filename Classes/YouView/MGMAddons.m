//
//  NSAddons.m
//  YouView
//
//  Created by Mr. Gecko on 3/4/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import "MGMAddons.h"
#import "MGMController.h"
#import "MGMXML.h"
#import <GeckoReporter/MGMLog.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <CommonCrypto/CommonDigest.h>
#import <openssl/evp.h>
#import <openssl/rand.h>
#import <openssl/rsa.h>
#import <openssl/engine.h>
#import <openssl/sha.h>
#import <openssl/pem.h>
#import <openssl/bio.h>
#import <openssl/err.h>
#import <openssl/ssl.h>

@implementation NSString (MGMAddons)
+ (NSString *)stringWithSeconds:(int)time {
	int seconds = time%60;
	time = time/60;
	int minutes = time%60;
	time = time/60;
	int hours = time%24;
    int days = time/24;
	NSString *string;
	if (days!=0) {
		string = [NSString stringWithFormat:@"%d:%02d:%02d:%02d", days, hours, minutes, seconds];
	} else if (hours!=0) {
		string = [NSString stringWithFormat:@"%d:%02d:%02d", hours, minutes, seconds];
	} else {
		string = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
	}
	return string;
}


//Remove html
- (NSString *)flattenHTML {
	NSString *xml = [NSString stringWithFormat:@"<div>%@</div>", self];
	MGMXMLDocument *document = [[MGMXMLDocument alloc] initWithXMLString:xml options:MGMXMLDocumentTidyHTML error:nil];
	MGMXMLElement *element = nil;
	if (document!=nil) {
		element = [[[document rootElement] retain] autorelease];
		if (element!=nil)
			[element detach];
		[document release];
	}
	return [element stringValue];
}

//Replace
- (NSString *)replace:(NSString *)targetString with:(NSString *)replaceString {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSMutableString *temp = [NSMutableString new];
	NSRange replaceRange = NSMakeRange(0, [self length]);
	NSRange rangeInOriginalString = replaceRange;
	int replaced = 0;
	
	while (1) {
		NSRange rangeToCopy;
		NSRange foundRange = [self rangeOfString:targetString options:0 range:rangeInOriginalString];
		if (foundRange.length == 0) break;
		rangeToCopy = NSMakeRange(rangeInOriginalString.location, foundRange.location - rangeInOriginalString.location);	
		[temp appendString:[self substringWithRange:rangeToCopy]];
		[temp appendString:replaceString];
		rangeInOriginalString.length -= NSMaxRange(foundRange) -
		rangeInOriginalString.location;
		rangeInOriginalString.location = NSMaxRange(foundRange);
		replaced++;
		if (replaced % 100 == 0) {
			[pool release];
			pool = [NSAutoreleasePool new];
		}
	}
	if (rangeInOriginalString.length > 0) [temp appendString:[self substringWithRange:rangeInOriginalString]];
	[pool release];
	
	return [temp autorelease];
}
- (BOOL)containsString:(NSString *)string {
	return ([[self lowercaseString] rangeOfString:[string lowercaseString]].location != NSNotFound);
}
- (NSString *)addPercentEscapes {
	NSString *result = [self stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	CFStringRef escapedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR("!*'();:^@&=+$,/?%#[]|"), kCFStringEncodingUTF8);
	
	if (escapedString!=NULL)
		result = [(NSString *)escapedString autorelease];
	return result;
}

- (NSString *)URLParameterWithName:(NSString *)theName {
	NSArray *parameters = [self componentsSeparatedByString:@"&"];
	for (int i=0; i<[parameters count]; i++) {
		NSArray *parameter = [[parameters objectAtIndex:i] componentsSeparatedByString:@"="];
		if ([[parameter objectAtIndex:0] isEqual:theName])
			return [[parameter objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}
	return nil;
}
- (NSDictionary *)URLParameters {
	NSArray *parameters = [self componentsSeparatedByString:@"&"];
	NSMutableDictionary *returnParameters = [NSMutableDictionary dictionary];
	for (int i=0; i<[parameters count]; i++) {
		NSArray *parameter = [[parameters objectAtIndex:i] componentsSeparatedByString:@"="];
		[returnParameters setObject:[[parameter objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:[[parameter objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	}
	return returnParameters;
}
@end

@implementation NSURL (MGMAddons)
- (NSString *)URLParameterWithName:(NSString *)theName {
	NSArray *parameters = [[self query] componentsSeparatedByString:@"&"];
	for (int i=0; i<[parameters count]; i++) {
		NSArray *parameter = [[parameters objectAtIndex:i] componentsSeparatedByString:@"="];
		if ([[parameter objectAtIndex:0] isEqual:theName])
			return [[parameter objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}
	return nil;
}
- (NSDictionary *)URLParameters {
	NSArray *parameters = [[self query] componentsSeparatedByString:@"&"];
	NSMutableDictionary *returnParameters = [NSMutableDictionary dictionary];
	for (int i=0; i<[parameters count]; i++) {
		NSArray *parameter = [[parameters objectAtIndex:i] componentsSeparatedByString:@"="];
		[returnParameters setObject:[[parameter objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:[[parameter objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	}
	return returnParameters;
}
- (NSURL *)URLByAppendingPathComponent:(NSString *)theComponent {
	NSString *path = [self path];
	path = [path stringByAppendingPathComponent:theComponent];
	NSString *url = [NSString stringWithFormat:@"%@://%@%@?%@", [self scheme], [self host], path, [self query]];
	return [NSURL URLWithString:url];
}
@end

@implementation NSUserDefaults (MGMAddons)
+ (void)registerDefaults {
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults setObject:[NSNumber numberWithInt:0] forKey:MGMMaxQuality];
	[defaults setObject:[NSNumber numberWithInt:0] forKey:MGMWindowMode];
	[defaults setObject:[NSNumber numberWithBool:YES] forKey:MGMAnimations];
	[defaults setObject:[NSNumber numberWithBool:NO] forKey:MGMFSFloat];
	[defaults setObject:[NSNumber numberWithBool:YES] forKey:MGMFSSpaces];
	[defaults setObject:[NSNumber numberWithInt:50] forKey:MGMPageMax];
	[defaults setObject:[NSArray array] forKey:MGMRecentSearches];
	[defaults setObject:[NSNumber numberWithInt:1] forKey:MGMOrderBy];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}
@end