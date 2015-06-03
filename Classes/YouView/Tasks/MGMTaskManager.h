//
//  MGMTaskManager.h
//  YouView
//
//  Created by Mr. Gecko on 4/16/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const MGMURL;
extern NSString * const MGMPreviewURL;
extern NSString * const MGMFilePath;
extern NSString * const MGMYVTaskPath;
extern NSString * const MGMFileName;
extern NSString * const MGMConverting;
extern NSString * const MGMConvertPath;
extern NSString * const MGMConvertFormat;
extern NSString * const MGMDonePath;
extern NSString * const MGMRevealPath;
extern NSString * const MGMTime;

extern NSString * const MGMFExtension;
extern NSString * const MGMFArguments;
extern NSString * const MGMFAudio;

extern NSString * const MGMMediaInfoKey;
extern NSString * const MGMTypeKey;
extern NSString * const MGMTypeGeneralKey;
extern NSString * const MGMTypeVideoKey;
extern NSString * const MGMTypeAudioKey;
extern NSString * const MGMBitrateKey;
extern NSString * const MGMCustomBitrateKey;
extern NSString * const MGMStreamKindIDKey;
extern NSString * const MGMIDKey;
extern NSString * const MGMLanguageKey;
extern NSString * const MGMFormatKey;

extern NSString * const MGMFileSizeKey;
extern NSString * const MGMFormatKey;
extern NSString * const MGMFormatProfileKey;
extern NSString * const MGMOveralBitRateKey;
extern NSString * const MGMPlayTimeKey;

extern NSString * const MGMCodecProfileKey;
extern NSString * const MGMDisplayAspectRatioKey;
extern NSString * const MGMFrameRateKey;
extern NSString * const MGMHeightKey;
extern NSString * const MGMWidthKey;
extern NSString * const MGMCustomHeightKey;
extern NSString * const MGMCustomWidthKey;
extern NSString * const MGMPixelAspectRatioKey;
extern NSString * const MGMScanOrderKey;
extern NSString * const MGMScanTypeKey;

extern NSString * const MGMSamplingRateKey;

extern NSString * const MGMMaxQualityKey;

extern NSString * const MGMInfoPlist;

extern NSString * const MGMYVTaskExt;
extern NSString * const MGMMP4Ext;
extern NSString * const MGMM4VExt;
extern NSString * const MGMMOVExt;
extern NSString * const MGMWMVExt;
extern NSString * const MGMAVIExt;
extern NSString * const MGMFLVExt;
extern NSString * const MGMMKVExt;
extern NSString * const MGMDVExt;
extern NSString * const MGMMPGExt;
extern NSString * const MGMMP3Ext;
extern NSString * const MGMM4AExt;
extern NSString * const MGMWAVExt;
extern NSString * const MGMAIFFExt;
extern NSString * const MGMAIFExt;
extern NSString * const MGMWMAExt;
extern NSString * const MGMJPGExt;

@class MGMTaskView, MGMController;

@interface MGMTaskManager : NSObject {
	IBOutlet MGMController *controller;
	IBOutlet NSView *exportView;
	IBOutlet NSMatrix *maxQuality;
	IBOutlet NSPopUpButton *exportFormat;
	IBOutlet NSPopUpButton *videoFormat;
	IBOutlet NSPopUpButton *audioFormat;
	IBOutlet NSTextField *widthField;
	IBOutlet NSTextField *heightField;
	IBOutlet NSTextField *bitrateField;
	
	IBOutlet NSWindow *mainWindow;
	IBOutlet NSTableView *taskTable;
	IBOutlet NSTextField *numTasks;
	NSMutableArray *tasks;
	NSMutableArray *formats;
}
- (MGMController *)controller;
- (NSArray *)formats;
- (void)updateCount;
- (IBAction)showTaskManager:(id)sender;
- (IBAction)clear:(id)sender;
- (void)addTask:(NSDictionary *)task withVideo:(NSURL *)video;
- (BOOL)ableToConvert:(MGMTaskView *)sender;
- (void)nextConversion;
- (void)saveEntry:(NSURL *)theEntry title:(NSString *)theTitle;
@end
