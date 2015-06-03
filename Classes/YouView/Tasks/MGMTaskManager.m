//
//  MGMTaskManager.m
//  YouView
//
//  Created by Mr. Gecko on 4/16/09.
//  Copyright (c) 2015 Mr. Gecko's Media (James Coleman). https://mrgeckosmedia.com/ All rights reserved.
//

#import "MGMTaskManager.h"
#import "MGMTaskView.h"
#import "MGMController.h"
#import "MGMViewCell.h"
#import <GeckoReporter/GeckoReporter.h>

NSString * const MGMURL = @"TaskURL";
NSString * const MGMPreviewURL = @"TaskPreviewURL";
NSString * const MGMFilePath = @"TaskFilePath";
NSString * const MGMYVTaskPath = @"TaskYVTaskPath";
NSString * const MGMFileName = @"TaskFileName";
NSString * const MGMConverting = @"TaskConverting";
NSString * const MGMConvertPath = @"TaskConvertPath";
NSString * const MGMConvertFormat = @"TaskConvertFormat";
NSString * const MGMDonePath = @"TaskDonePath";
NSString * const MGMRevealPath = @"TaskRevealPath";
NSString * const MGMTime = @"TaskTime";

NSString * const MGMFExtension = @"FormatExtension";
NSString * const MGMFArguments = @"FormatArguments";
NSString * const MGMFAudio = @"FormatAudio";

NSString * const MGMMediaInfoKey = @"MediaInfo";
NSString * const MGMTypeKey = @"Type";
NSString * const MGMTypeGeneralKey = @"General";
NSString * const MGMTypeVideoKey = @"Video";
NSString * const MGMTypeAudioKey = @"Audio";
NSString * const MGMBitrateKey = @"Bitrate";
NSString * const MGMCustomBitrateKey = @"CustomBitrate";
NSString * const MGMStreamKindIDKey = @"StreamKindID";
NSString * const MGMIDKey = @"ID";
NSString * const MGMLanguageKey = @"Language";
NSString * const MGMFormatKey = @"Format";

NSString * const MGMFileSizeKey = @"FileSize";
NSString * const MGMFormatProfileKey = @"Format_Profile";
NSString * const MGMOveralBitRateKey = @"OveralBitrate";
NSString * const MGMPlayTimeKey = @"PlayTime";

NSString * const MGMCodecProfileKey = @"Codec_Profile";
NSString * const MGMDisplayAspectRatioKey = @"DisplayAspectRatio";
NSString * const MGMFrameRateKey = @"FrameRate";
NSString * const MGMHeightKey = @"Height";
NSString * const MGMWidthKey = @"Width";
NSString * const MGMCustomHeightKey = @"CustomHeight";
NSString * const MGMCustomWidthKey = @"CustomWidth";
NSString * const MGMPixelAspectRatioKey = @"PixelAspectRatio";
NSString * const MGMScanOrderKey = @"ScanOrder";
NSString * const MGMScanTypeKey = @"ScanType";

NSString * const MGMSamplingRateKey = @"SamplingRate";

NSString * const MGMMaxQualityKey = @"MaxQuality";

NSString * const MGMInfoPlist = @"info.plist";

NSString * const MGMYVTaskExt = @"yvtask";
NSString * const MGMMP4Ext = @"mp4";
NSString * const MGMM4VExt = @"m4v";
NSString * const MGMMOVExt = @"mov";
NSString * const MGMWMVExt = @"wmv";
NSString * const MGMAVIExt = @"avi";
NSString * const MGMFLVExt = @"flv";
NSString * const MGMMKVExt = @"mkv";
NSString * const MGMDVExt = @"dv";
NSString * const MGMMPGExt = @"mpg";
NSString * const MGMMP3Ext = @"mp3";
NSString * const MGMM4AExt = @"m4a";
NSString * const MGMWAVExt = @"wav";
NSString * const MGMAIFFExt = @"aiff";
NSString * const MGMAIFExt = @"aif";
NSString * const MGMWMAExt = @"wma";
NSString * const MGMJPGExt = @"jpg";

@protocol NSSavePanelProtocol <NSObject>
- (NSInteger)runModalForDirectory:(NSString *)path file:(NSString *)filename;
- (void)setNameFieldStringValue:(NSString *)value;
- (void)setDirectoryURL:(NSURL *)url;
@end


@implementation MGMTaskManager
- (void)awakeFromNib {
	formats = [NSMutableArray new];
	[formats addObject:[NSDictionary dictionaryWithObjectsAndKeys:MGMMP4Ext, MGMFExtension, [NSArray arrayWithObjects:@"-vcodec", @"mpeg4", @"-acodec", @"libfaac", nil], MGMFArguments, [NSNumber numberWithBool:NO], MGMFAudio, nil]];
	[formats addObject:[NSDictionary dictionaryWithObjectsAndKeys:MGMMOVExt, MGMFExtension, [NSArray arrayWithObjects:@"-vcodec", @"libx264", @"-acodec", @"libfaac", nil], MGMFArguments, [NSNumber numberWithBool:NO], MGMFAudio, nil]];
	[formats addObject:[NSDictionary dictionaryWithObjectsAndKeys:MGMFLVExt, MGMFExtension, [NSArray arrayWithObjects:@"-vcodec", @"flv", @"-acodec", @"libmp3lame", nil], MGMFArguments, [NSNumber numberWithBool:NO], MGMFAudio, nil]];
	[formats addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"swf", MGMFExtension, [NSArray arrayWithObjects:@"-vcodec", @"flv", @"-acodec", @"libmp3lame", nil], MGMFArguments, [NSNumber numberWithBool:NO], MGMFAudio, nil]];
	[formats addObject:[NSDictionary dictionaryWithObjectsAndKeys:MGMAVIExt, MGMFExtension, [NSArray arrayWithObjects:@"-vcodec", @"mpeg4", @"-acodec", @"libmp3lame", nil], MGMFArguments, [NSNumber numberWithBool:NO], MGMFAudio, nil]];
	[formats addObject:[NSDictionary dictionaryWithObjectsAndKeys:MGMAVIExt, MGMFExtension, [NSArray arrayWithObjects:@"-vcodec", @"msmpeg4v2", @"-acodec", @"libmp3lame", nil], MGMFArguments, [NSNumber numberWithBool:NO], MGMFAudio, nil]];
	[formats addObject:[NSDictionary dictionaryWithObjectsAndKeys:MGMM4VExt, MGMFExtension, [NSArray arrayWithObjects:@"-vcodec", @"libx264", @"-acodec", @"libfaac", nil], MGMFArguments, [NSNumber numberWithBool:NO], MGMFAudio, nil]];
	[formats addObject:[NSDictionary dictionaryWithObjectsAndKeys:MGMMPGExt, MGMFExtension, [NSArray arrayWithObjects:@"-vcodec", @"mpeg1video", @"-acodec", @"mp2", nil], MGMFArguments, [NSNumber numberWithBool:NO], MGMFAudio, nil]];
	[formats addObject:[NSDictionary dictionaryWithObjectsAndKeys:MGMWMVExt, MGMFExtension, [NSArray arrayWithObjects:@"-vcodec", @"wmv2", @"-acodec", @"wmav2", nil], MGMFArguments, [NSNumber numberWithBool:NO], MGMFAudio, nil]];
	[formats addObject:[NSDictionary dictionaryWithObjectsAndKeys:MGMMP3Ext, MGMFExtension, [NSArray arrayWithObjects:@"-vn", @"-acodec", @"libmp3lame", nil], MGMFArguments, [NSNumber numberWithBool:YES], MGMFAudio, nil]];
	[formats addObject:[NSDictionary dictionaryWithObjectsAndKeys:MGMM4AExt, MGMFExtension, [NSArray arrayWithObjects:@"-vn", @"-acodec", @"libfaac", nil], MGMFArguments, [NSNumber numberWithBool:YES], MGMFAudio, nil]];
	[formats addObject:[NSDictionary dictionaryWithObjectsAndKeys:MGMWAVExt, MGMFExtension, [NSArray arrayWithObjects:@"-vn", @"-acodec", @"pcm_s16le", nil], MGMFArguments, [NSNumber numberWithBool:YES], MGMFAudio, nil]];
	[formats addObject:[NSDictionary dictionaryWithObjectsAndKeys:MGMAIFFExt, MGMFExtension, [NSArray arrayWithObjects:@"-vn", @"-acodec", @"pcm_s16be", nil], MGMFArguments, [NSNumber numberWithBool:YES], MGMFAudio, nil]];
	[formats addObject:[NSDictionary dictionaryWithObjectsAndKeys:MGMWMAExt, MGMFExtension, [NSArray arrayWithObjects:@"-vn", @"-acodec", @"wmav2", nil], MGMFArguments, [NSNumber numberWithBool:YES], MGMFAudio, nil]];
	[[[taskTable tableColumns] objectAtIndex:0] setDataCell:[[MGMViewCell new] autorelease]];
	tasks = [NSMutableArray new];
}
- (void)dealloc {
#if releaseDebug
	MGMLog(@"%s Releasing", __PRETTY_FUNCTION__);
#endif
	[tasks release];
	[formats release];
	[super dealloc];
}
- (MGMController *)controller {
	return controller;
}
- (NSArray *)formats {
	return formats;
}
- (void)reloadData {
	while ([[taskTable subviews] count] > 0) {
		[[[taskTable subviews] lastObject] removeFromSuperviewWithoutNeedingDisplay];
    }
    
    [taskTable reloadData];
}
- (void)updateCount {
	[numTasks setStringValue:[NSString stringWithFormat:@"Tasks %d", [tasks count]]];
}
- (IBAction)showTaskManager:(id)sender {
	[self updateCount];
	[mainWindow makeKeyAndOrderFront:sender];
}
- (IBAction)clear:(id)sender {
	for (int i = [tasks count]-1; i>=0; i--) {
		if (![[tasks objectAtIndex:i] working]) {
			[tasks removeObjectAtIndex:i];
		}
	}
	[self reloadData];
	[self updateCount];
}
- (void)addTask:(NSDictionary *)task withVideo:(NSURL *)video {
	[tasks addObject:[MGMTaskView taskViewWithTask:task withVideo:video manager:self]];
	[self reloadData];
	[mainWindow makeKeyAndOrderFront:self];
	[self updateCount];
}

- (BOOL)ableToConvert:(MGMTaskView *)sender {
	for (int i=0; i<[tasks count]; i++) {
		if ([tasks objectAtIndex:i] != sender) {
			if ([[tasks objectAtIndex:i] converting]) {
				return NO;
			}
		}
	}
	return YES;
}

- (void)nextConversion {
	for (int i=0; i<[tasks count]; i++) {
		if ([[tasks objectAtIndex:i] waitingToConvert]) {
			[[tasks objectAtIndex:i] startConverson];
			break;
		}
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [tasks count];
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return nil;
}
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    [(MGMViewCell *)cell addSubview:[tasks objectAtIndex:row]];
}
- (void)saveEntry:(NSURL *)theEntry title:(NSString *)theTitle {
	[maxQuality selectCellAtRow:0 column:[[NSUserDefaults standardUserDefaults] integerForKey:MGMMaxQuality]];
    NSSavePanel<NSSavePanelProtocol> *panel = [NSSavePanel savePanel];
    [panel setAccessoryView:exportView];
    int returnCode;
    if ([[[MGMSystemInfo new] autorelease] isAfterSnowLeopard]) {
        [panel setNameFieldStringValue:theTitle];
        returnCode = [panel runModal];
    } else {
        returnCode = [panel runModalForDirectory:nil file:theTitle];
    }
    if (returnCode==NSOKButton) {
        NSString *file = [[panel URL] path];
        NSMutableDictionary *taskInfo = [NSMutableDictionary dictionary];
        NSString *extension = MGMMP4Ext;
        if ([exportFormat indexOfSelectedItem]!=0) {
            [taskInfo setObject:[NSNumber numberWithInt:[exportFormat indexOfSelectedItem]-1] forKey:MGMConvertFormat];
            extension = [[formats objectAtIndex:[[taskInfo objectForKey:MGMConvertFormat] intValue]] objectForKey:MGMFExtension];
        }
        [taskInfo setObject:[file stringByAppendingPathExtension:extension] forKey:MGMDonePath];
        [taskInfo setObject:[NSNumber numberWithInt:[maxQuality selectedColumn]] forKey:MGMMaxQualityKey];
        if (![[widthField stringValue] isEqual:@""])
            [taskInfo setObject:[widthField stringValue] forKey:MGMCustomWidthKey];
        if (![[heightField stringValue] isEqual:@""])
            [taskInfo setObject:[heightField stringValue] forKey:MGMCustomHeightKey];
        if (![[bitrateField stringValue] isEqual:@""])
            [taskInfo setObject:[bitrateField stringValue] forKey:MGMCustomBitrateKey];
        [self addTask:taskInfo withVideo:theEntry];
    }
}
- (void)application:(NSApplication *)sender openFiles:(NSArray *)files {
	for (int i=0; i<[files count]; i++) {
        NSString *file = [files objectAtIndex:i];
        NSString *extension = [[file pathExtension] lowercaseString];
        if ([extension isEqual:MGMYVTaskExt]) {
            BOOL open = YES;
            for (int f=0; f<[tasks count]; f++) {
                if ([[[tasks objectAtIndex:f] YVTaskPath] isEqual:file]) {
                    open = NO;
                    break;
                }
            }
            if (open) {
                [tasks addObject:[MGMTaskView taskViewWithTask:[NSDictionary dictionaryWithObject:file forKey:MGMYVTaskPath] withVideo:nil manager:self]];
            }
        } else {
            BOOL isVideo;
            NSRect frame = [exportFormat frame];
            if ([extension isEqual:MGMMP4Ext] || [extension isEqual:MGMM4VExt] || [extension isEqual:MGMMOVExt] || [extension isEqual:MGMWMVExt] || [extension isEqual:MGMAVIExt] || [extension isEqual:MGMFLVExt] || [extension isEqual:MGMMKVExt] || [extension isEqual:MGMDVExt] || [extension isEqual:MGMMPGExt]) {
                isVideo = YES;
                [maxQuality setEnabled:NO];
                [exportFormat removeFromSuperview];
                [exportView addSubview:videoFormat];
                [videoFormat setFrame:frame];
            } else if ([extension isEqual:MGMMP3Ext] || [extension isEqual:MGMM4AExt] || [extension isEqual:MGMWAVExt] || [extension isEqual:MGMAIFFExt] || [extension isEqual:MGMAIFExt] || [extension isEqual:MGMWMAExt]) {
                isVideo = NO;
                [maxQuality setEnabled:NO];
                [exportFormat removeFromSuperview];
                [exportView addSubview:audioFormat];
                [audioFormat setFrame:frame];
            } else {
                NSBeep();
                return;
            }
            
            NSSavePanel<NSSavePanelProtocol> *panel = [NSSavePanel savePanel];
            [panel setAccessoryView:exportView];
            int returnCode;
            if ([panel respondsToSelector:@selector(runModalForDirectory:file:)]) {
                returnCode = [panel runModalForDirectory:[file stringByDeletingLastPathComponent] file:[[file lastPathComponent] stringByDeletingPathExtension]];
            } else {
                [panel setNameFieldStringValue:[[file lastPathComponent] stringByDeletingPathExtension]];
                [panel setDirectoryURL:[NSURL fileURLWithPath:[file stringByDeletingLastPathComponent]]];
                returnCode = [panel runModal];
            }
            if (returnCode==NSOKButton) {
                NSString *exportFile = [[panel URL] path];
                NSMutableDictionary *taskInfo = [NSMutableDictionary dictionary];
                [taskInfo setObject:file forKey:MGMFilePath];
                [taskInfo setObject:[NSNumber numberWithInt:(isVideo ? [videoFormat indexOfSelectedItem] : [audioFormat indexOfSelectedItem]+9)] forKey:MGMConvertFormat];
                [taskInfo setObject:[exportFile stringByAppendingPathExtension:[[formats objectAtIndex:[[taskInfo objectForKey:MGMConvertFormat] intValue]] objectForKey:MGMFExtension]] forKey:MGMDonePath];
                [taskInfo setObject:[NSNumber numberWithInt:[maxQuality selectedColumn]] forKey:MGMMaxQualityKey];
                if (![[widthField stringValue] isEqual:@""])
                    [taskInfo setObject:[widthField stringValue] forKey:MGMCustomWidthKey];
                if (![[heightField stringValue] isEqual:@""])
                    [taskInfo setObject:[heightField stringValue] forKey:MGMCustomHeightKey];
                if (![[bitrateField stringValue] isEqual:@""])
                    [taskInfo setObject:[bitrateField stringValue] forKey:MGMCustomBitrateKey];
                [taskInfo setObject:[NSNumber numberWithBool:YES] forKey:MGMConverting];
                [tasks addObject:[MGMTaskView taskViewWithTask:taskInfo withVideo:nil manager:self]];
                [[tasks lastObject] restart:self];
            }
            
            if (isVideo)
                [videoFormat removeFromSuperview];
            else
                [audioFormat removeFromSuperview];
            [exportView addSubview:exportFormat];
            [exportFormat setFrame:frame];
        }
    }
    [self reloadData];
    [mainWindow makeKeyAndOrderFront:sender];
    [self updateCount];
}
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	for (int i=0; i<[tasks count]; i++) {
		if ([[tasks objectAtIndex:i] working]) {
			NSBeginAlertSheet(@"Warning", nil, nil, nil, mainWindow, nil, nil, nil, nil, @"You are still downloading/converting files, please cancel them before you quit.");
			return NSTerminateCancel;
		}
	}
	return NSTerminateNow;
}
@end
