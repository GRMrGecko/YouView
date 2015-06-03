//
//  MGMYVToolProtocol.h
//  YouView
//
//  Created by Mr. Gecko on 5/28/10.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol MGMYVToolProtocol
- (void)changePremissionsForPath:(NSString *)thePath to:(NSString *)thePermissions;
- (void)changeOwnerForPath:(NSString *)thePath to:(NSString *)theOwner;
- (void)quit;
@end