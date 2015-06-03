//
//  NSAddons.h
//  YouView
//
//  Created by Mr. Gecko on 3/4/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSString (MGMAddons)
+ (NSString *)stringWithSeconds:(int)seconds;
- (NSString *)flattenHTML;
- (NSString *)replace:(NSString *)targetString with:(NSString *)replaceString;
- (BOOL)containsString:(NSString *)string;
- (NSString *)addPercentEscapes;
- (NSString *)URLParameterWithName:(NSString *)theName;
- (NSDictionary *)URLParameters;
@end

@interface NSURL (MGMAddons)
- (NSString *)URLParameterWithName:(NSString *)theName;
- (NSDictionary *)URLParameters;
- (NSURL *)URLByAppendingPathComponent:(NSString *)theComponent;
@end

@interface NSUserDefaults (MGMAddons)
+ (void)registerDefaults;
@end