//
//  MGMParentalControls.h
//  YouView
//
//  Created by Mr. Gecko on 4/25/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGMParentalControls : NSObject {
	NSMutableDictionary *parentalControls;
	NSString *masterKey;
}
+ (id)standardParentalControls;
- (NSString *)path;
- (NSData *)encrypt:(NSString *)string withKey:(NSString *)key;
- (NSString *)decrypt:(NSData *)encryptedData withKey:(NSString *)key;
- (void)setString:(NSString *)object forKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key;
- (void)setBool:(BOOL)object forKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
- (void)save;
@end
