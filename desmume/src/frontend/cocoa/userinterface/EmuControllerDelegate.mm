/*
	Copyright (C) 2013-2017 DeSmuME Team

	This file is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 2 of the License, or
	(at your option) any later version.

	This file is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with the this software.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "EmuControllerDelegate.h"
#import "DisplayWindowController.h"
#import "InputManager.h"
#import "cheatWindowDelegate.h"
#import "Slot2WindowDelegate.h"

#import "cocoa_globals.h"
#import "cocoa_cheat.h"
#import "cocoa_core.h"
#import "cocoa_file.h"
#import "cocoa_firmware.h"
#import "cocoa_GPU.h"
#import "cocoa_input.h"
#import "cocoa_output.h"
#import "cocoa_rom.h"
#import "cocoa_slot2.h"

@implementation EmuControllerDelegate

@synthesize inputManager;

@synthesize currentRom;
@dynamic cdsFirmware;
@dynamic cdsSpeaker;
@synthesize cdsCheats;

@synthesize cheatWindowDelegate;
@synthesize firmwarePanelController;
@synthesize romInfoPanelController;
@synthesize cdsCoreController;
@synthesize cdsSoundController;
@synthesize cheatWindowController;
@synthesize cheatListController;
@synthesize cheatDatabaseController;
@synthesize slot2WindowController;

@synthesize displayRotationPanel;
@synthesize displaySeparationPanel;
@synthesize displayVideoSettingsPanel;

@synthesize executionControlWindow;
@synthesize slot1ManagerWindow;
@synthesize saveFileMigrationSheet;
@synthesize saveStatePrecloseSheet;
@synthesize exportRomSavePanelAccessoryView;

@synthesize iconExecute;
@synthesize iconPause;
@synthesize iconSpeedNormal;
@synthesize iconSpeedDouble;

@synthesize lastSetSpeedScalar;

@synthesize isWorking;
@synthesize isRomLoading;
@synthesize statusText;
@synthesize isHardwareMicAvailable;
@synthesize currentMicGainValue;
@dynamic currentVolumeValue;
@synthesize currentMicStatusIcon;
@synthesize currentVolumeIcon;

@synthesize isShowingSaveStateDialog;
@synthesize isShowingFileMigrationDialog;
@synthesize isUserInterfaceBlockingExecution;

@synthesize currentSaveStateURL;
@synthesize selectedExportRomSaveID;
@synthesize selectedRomSaveTypeID;

@synthesize mainWindow;
@synthesize windowList;


-(id)init
{
	self = [super init];
	if(self == nil)
	{
		return nil;
	}
	
	spinlockFirmware = OS_SPINLOCK_INIT;
	spinlockSpeaker = OS_SPINLOCK_INIT;
	
	mainWindow = nil;
	windowList = [[NSMutableArray alloc] initWithCapacity:32];
	
	displayRotationPanelTitle = nil;
	displaySeparationPanelTitle = nil;
	displayVideoSettingsPanelTitle = nil;
	
	currentRom = nil;
	cdsFirmware = nil;
	cdsSpeaker = nil;
	dummyCheatList = nil;
	
	isSaveStateEdited = NO;
	isShowingSaveStateDialog = NO;
	isShowingFileMigrationDialog = NO;
	isUserInterfaceBlockingExecution = NO;
	
	currentSaveStateURL = nil;
	selectedRomSaveTypeID = ROMSAVETYPE_AUTOMATIC;
	selectedExportRomSaveID = 0;
	
	lastSetSpeedScalar = 1.0f;
	isHardwareMicAvailable = NO;
	currentMicGainValue = 0.0f;
	isSoundMuted = NO;
	lastSetVolumeValue = MAX_VOLUME;
	
	iconExecute				= [[NSImage imageNamed:@"Icon_Execute_420x420"] retain];
	iconPause				= [[NSImage imageNamed:@"Icon_Pause_420x420"] retain];
	iconSpeedNormal			= [[NSImage imageNamed:@"Icon_Speed1x_420x420"] retain];
	iconSpeedDouble			= [[NSImage imageNamed:@"Icon_Speed2x_420x420"] retain];
	
	iconMicDisabled			= [[NSImage imageNamed:@"Icon_MicrophoneBlack_256x256"] retain];
	iconMicIdle				= [[NSImage imageNamed:@"Icon_MicrophoneDarkGreen_256x256"] retain];
	iconMicActive			= [[NSImage imageNamed:@"Icon_MicrophoneGreen_256x256"] retain];
	iconMicInClip			= [[NSImage imageNamed:@"Icon_MicrophoneRed_256x256"] retain];
	iconMicManualOverride	= [[NSImage imageNamed:@"Icon_MicrophoneGray_256x256"] retain];
	
	iconVolumeFull			= [[NSImage imageNamed:@"Icon_VolumeFull_16x16"] retain];
	iconVolumeTwoThird		= [[NSImage imageNamed:@"Icon_VolumeTwoThird_16x16"] retain];
	iconVolumeOneThird		= [[NSImage imageNamed:@"Icon_VolumeOneThird_16x16"] retain];
	iconVolumeMute			= [[NSImage imageNamed:@"Icon_VolumeMute_16x16"] retain];
	
	isWorking = NO;
	isRomLoading = NO;
	statusText = NSSTRING_STATUS_READY;
	currentVolumeValue = MAX_VOLUME;
	currentMicStatusIcon = [iconMicDisabled retain];
	currentVolumeIcon = [iconVolumeFull retain];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(loadRomDidFinish:)
												 name:@"org.desmume.DeSmuME.loadRomDidFinish"
											   object:nil];
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[iconExecute release];
	[iconPause release];
	[iconSpeedNormal release];
	[iconSpeedDouble release];
	
	[iconMicDisabled release];
	[iconMicIdle release];
	[iconMicActive release];
	[iconMicInClip release];
	[iconMicManualOverride release];
	
	[iconVolumeFull release];
	[iconVolumeTwoThird release];
	[iconVolumeOneThird release];
	[iconVolumeMute release];
	
	[[self currentRom] release];
	[self setCurrentRom:nil];
	
	[self setCdsCheats:nil];
	[self setCdsSpeaker:nil];
	
	[self setIsWorking:NO];
	[self setStatusText:@""];
	[self setCurrentVolumeValue:0.0f];
	[self setCurrentVolumeIcon:nil];
	
	[romInfoPanelController setContent:[CocoaDSRom romNotLoadedBindings]];
	[cdsSoundController setContent:nil];
	[firmwarePanelController setContent:nil];
	
	[self setMainWindow:nil];
	[windowList release];
	
	[super dealloc];
}

#pragma mark Dynamic Property Methods

- (void) setCdsFirmware:(CocoaDSFirmware *)theFirmware
{
	OSSpinLockLock(&spinlockFirmware);
	
	if (theFirmware == cdsFirmware)
	{
		OSSpinLockUnlock(&spinlockFirmware);
		return;
	}
	
	if (theFirmware != nil)
	{
		[theFirmware retain];
	}
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[cdsCore setCdsFirmware:theFirmware];
	[firmwarePanelController setContent:theFirmware];
	
	[cdsFirmware release];
	cdsFirmware = theFirmware;
	
	OSSpinLockUnlock(&spinlockFirmware);
}

- (CocoaDSFirmware *) cdsFirmware
{
	OSSpinLockLock(&spinlockFirmware);
	CocoaDSFirmware *theFirmware = cdsFirmware;
	OSSpinLockUnlock(&spinlockFirmware);
	
	return theFirmware;
}

- (void) setCdsSpeaker:(CocoaDSSpeaker *)theSpeaker
{
	OSSpinLockLock(&spinlockSpeaker);
	
	if (theSpeaker == cdsSpeaker)
	{
		OSSpinLockUnlock(&spinlockSpeaker);
		return;
	}
	
	if (theSpeaker != nil)
	{
		[theSpeaker retain];
	}
	
	[cdsSoundController setContent:[theSpeaker property]];
	
	[cdsSpeaker release];
	cdsSpeaker = theSpeaker;
	
	OSSpinLockUnlock(&spinlockSpeaker);
}

- (CocoaDSSpeaker *) cdsSpeaker
{
	OSSpinLockLock(&spinlockSpeaker);
	CocoaDSSpeaker *theSpeaker = cdsSpeaker;
	OSSpinLockUnlock(&spinlockSpeaker);
	
	return theSpeaker;
}

- (void) setCurrentVolumeValue:(float)vol
{
	currentVolumeValue = vol;
	
	// Update the icon.
	NSImage *currentImage = [self currentVolumeIcon];
	NSImage *newImage = nil;
	if (vol <= 0.0f)
	{
		newImage = iconVolumeMute;
	}
	else if (vol > 0.0f && vol <= VOLUME_THRESHOLD_LOW)
	{
		newImage = iconVolumeOneThird;
		isSoundMuted = NO;
		lastSetVolumeValue = vol;
	}
	else if (vol > VOLUME_THRESHOLD_LOW && vol <= VOLUME_THRESHOLD_HIGH)
	{
		newImage = iconVolumeTwoThird;
		isSoundMuted = NO;
		lastSetVolumeValue = vol;
	}
	else
	{
		newImage = iconVolumeFull;
		isSoundMuted = NO;
		lastSetVolumeValue = vol;
	}
	
	if (newImage != currentImage)
	{
		[self setCurrentVolumeIcon:newImage];
	}
}

- (float) currentVolumeValue
{
	return currentVolumeValue;
}

#pragma mark IBActions

- (IBAction) newDisplayWindow:(id)sender
{
	DisplayWindowController *newWindowController = [[DisplayWindowController alloc] initWithWindowNibName:@"DisplayWindow" emuControlDelegate:self];
	
	[newWindowController window]; // Just reference the window to force the nib to load.
	[[newWindowController view] setAllowViewUpdates:YES];
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	const BOOL useVerticalSync = ([[newWindowController view] layer] != nil) || [cdsCore isFrameSkipEnabled] || (([cdsCore speedScalar] < 1.03f) && [cdsCore isSpeedLimitEnabled]);
	[[newWindowController view] setUseVerticalSync:useVerticalSync];
	
	[[[newWindowController view] cdsVideoOutput] handleReloadReprocessRedraw];
	[[newWindowController window] makeKeyAndOrderFront:self];
	[[newWindowController window] makeMainWindow];
}

- (IBAction) openRom:(id)sender
{
	if ([self isRomLoading])
	{
		return;
	}
	
	NSURL *selectedFile = nil;
	
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:NO];
	[panel setCanChooseFiles:YES];
	[panel setResolvesAliases:YES];
	[panel setAllowsMultipleSelection:NO];
	[panel setTitle:NSSTRING_TITLE_OPEN_ROM_PANEL];
	NSArray *fileTypes = [NSArray arrayWithObjects:@FILE_EXT_ROM_DS, @FILE_EXT_ROM_GBA, nil]; 
	
	// The NSOpenPanel method -(NSInt)runModalForDirectory:file:types:
	// is deprecated in Mac OS X v10.6.
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
	[panel setAllowedFileTypes:fileTypes];
	const NSInteger buttonClicked = [panel runModal];
#else
	const NSInteger buttonClicked = [panel runModalForDirectory:nil file:nil types:fileTypes];
#endif
	
	if (buttonClicked == NSFileHandlingPanelOKButton)
	{
		selectedFile = [[panel URLs] lastObject];
		if(selectedFile == nil)
		{
			return;
		}
		
		[self handleLoadRomByURL:selectedFile];
	}
}

- (IBAction) loadRecentRom:(id)sender
{
	// Dummy selector, used for UI validation only.
}

- (IBAction) closeRom:(id)sender
{
	[self handleUnloadRom:REASONFORCLOSE_NORMAL romToLoad:nil];
}

- (IBAction) revealRomInFinder:(id)sender
{
	NSURL *romURL = [[self currentRom] fileURL];
	
	if (romURL != nil)
	{
		[[NSWorkspace sharedWorkspace] selectFile:[romURL path] inFileViewerRootedAtPath:@""];
	}
}

- (IBAction) revealGameDataFolderInFinder:(id)sender
{
	NSURL *folderURL = [CocoaDSFile userAppSupportURL:nil version:nil];
	[[NSWorkspace sharedWorkspace] selectFile:[folderURL path] inFileViewerRootedAtPath:@""];
}

- (IBAction) openEmuSaveState:(id)sender
{
	NSURL *selectedFile = nil;
	
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:NO];
	[panel setCanChooseFiles:YES];
	[panel setResolvesAliases:YES];
	[panel setAllowsMultipleSelection:NO];
	[panel setTitle:NSSTRING_TITLE_OPEN_STATE_FILE_PANEL];
	NSArray *fileTypes = [NSArray arrayWithObjects:@FILE_EXT_SAVE_STATE, nil];
	
	// The NSOpenPanel method -(NSInt)runModalForDirectory:file:types:
	// is deprecated in Mac OS X v10.6.
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
	[panel setAllowedFileTypes:fileTypes];
	const NSInteger buttonClicked = [panel runModal];
#else
	const NSInteger buttonClicked = [panel runModalForDirectory:nil file:nil types:fileTypes];
#endif
	
	if (buttonClicked == NSFileHandlingPanelOKButton)
	{
		selectedFile = [[panel URLs] lastObject];
		if(selectedFile == nil)
		{
			return;
		}
	}
	else
	{
		return;
	}
	
	[self pauseCore];
	
	const BOOL isStateLoaded = [CocoaDSFile loadState:selectedFile];
	if (!isStateLoaded)
	{
		[self setStatusText:NSSTRING_STATUS_SAVESTATE_LOADING_FAILED];
		[self restoreCoreState];
		return;
	}
	
	isSaveStateEdited = YES;
	for (DisplayWindowController *windowController in windowList)
	{
		[[windowController window] setDocumentEdited:isSaveStateEdited];
	}
	
	[self setStatusText:NSSTRING_STATUS_SAVESTATE_LOADED];
	[self restoreCoreState];
	
	[self setCurrentSaveStateURL:selectedFile];
}

- (IBAction) saveEmuSaveState:(id)sender
{
	if (isSaveStateEdited && [self currentSaveStateURL] != nil)
	{
		[self pauseCore];
		
		const BOOL isStateSaved = [CocoaDSFile saveState:[self currentSaveStateURL]];
		if (!isStateSaved)
		{
			[self setStatusText:NSSTRING_STATUS_SAVESTATE_SAVING_FAILED];
			return;
		}
		
		isSaveStateEdited = YES;
		for (DisplayWindowController *windowController in windowList)
		{
			[[windowController window] setDocumentEdited:isSaveStateEdited];
		}
		
		[self setStatusText:NSSTRING_STATUS_SAVESTATE_SAVED];
		[self restoreCoreState];
	}
	else
	{
		[self saveEmuSaveStateAs:sender];
	}
}

- (IBAction) saveEmuSaveStateAs:(id)sender
{
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setCanCreateDirectories:YES];
	[panel setTitle:NSSTRING_TITLE_SAVE_STATE_FILE_PANEL];
	
	// The NSSavePanel method -(void)setRequiredFileType:
	// is deprecated in Mac OS X v10.6.
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
	NSArray *fileTypes = [NSArray arrayWithObjects:@FILE_EXT_SAVE_STATE, nil];
	[panel setAllowedFileTypes:fileTypes];
#else
	[panel setRequiredFileType:@FILE_EXT_SAVE_STATE];
#endif
	
	const NSInteger buttonClicked = [panel runModal];
	if(buttonClicked == NSOKButton)
	{
		NSURL *saveFileURL = [panel URL];
		
		[self pauseCore];
		
		const BOOL isStateSaved = [CocoaDSFile saveState:saveFileURL];
		if (!isStateSaved)
		{
			[self setStatusText:NSSTRING_STATUS_SAVESTATE_SAVING_FAILED];
			return;
		}
		
		isSaveStateEdited = YES;
		for (DisplayWindowController *windowController in windowList)
		{
			[[windowController window] setDocumentEdited:isSaveStateEdited];
		}
		
		[self setStatusText:NSSTRING_STATUS_SAVESTATE_SAVED];
		[self restoreCoreState];
		
		[self setCurrentSaveStateURL:saveFileURL];
	}
}

- (IBAction) revertEmuSaveState:(id)sender
{
	if (!isSaveStateEdited || [self currentSaveStateURL] == nil)
	{
		return;
	}
	
	[self pauseCore];
	
	const BOOL isStateLoaded = [CocoaDSFile loadState:[self currentSaveStateURL]];
	if (!isStateLoaded)
	{
		[self setStatusText:NSSTRING_STATUS_SAVESTATE_REVERTING_FAILED];
		return;
	}
	
	isSaveStateEdited = YES;
	for (DisplayWindowController *windowController in windowList)
	{
		[[windowController window] setDocumentEdited:isSaveStateEdited];
	}
	
	[self setStatusText:NSSTRING_STATUS_SAVESTATE_REVERTED];
	[self restoreCoreState];
}

- (IBAction) loadEmuSaveStateSlot:(id)sender
{
	[inputManager dispatchCommandUsingIBAction:_cmd sender:sender];
}

- (IBAction) saveEmuSaveStateSlot:(id)sender
{
	[inputManager dispatchCommandUsingIBAction:_cmd sender:sender];
}

- (IBAction) openReplay:(id)sender
{
	NSURL *selectedFile = nil;
	
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:NO];
	[panel setCanChooseFiles:YES];
	[panel setResolvesAliases:YES];
	[panel setAllowsMultipleSelection:NO];
	[panel setTitle:@"Load Replay"];
	NSArray *fileTypes = [NSArray arrayWithObjects:@"dsm", nil];
	
	// The NSOpenPanel method -(NSInt)runModalForDirectory:file:types:
	// is deprecated in Mac OS X v10.6.
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
	[panel setAllowedFileTypes:fileTypes];
	const NSInteger buttonClicked = [panel runModal];
#else
	const NSInteger buttonClicked = [panel runModalForDirectory:nil file:nil types:fileTypes];
#endif
	
	if (buttonClicked == NSFileHandlingPanelOKButton)
	{
		selectedFile = [[panel URLs] lastObject];
		if(selectedFile == nil)
		{
			return;
		}
		
		[self pauseCore];
		const BOOL isMovieLoaded = [CocoaDSFile loadReplay:selectedFile];
		[self setStatusText:(isMovieLoaded) ? @"Replay loaded successfully." : @"Replay loading failed!"];
		[self restoreCoreState];
	}
}

- (IBAction) recordReplay:(id)sender
{
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setCanCreateDirectories:YES];
	[panel setTitle:@"Record Replay"];
	
	// The NSSavePanel method -(void)setRequiredFileType:
	// is deprecated in Mac OS X v10.6.
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
	NSArray *fileTypes = [NSArray arrayWithObjects:@"dsm", nil];
	[panel setAllowedFileTypes:fileTypes];
#else
	[panel setRequiredFileType:@"dsm"];
#endif
	
	const NSInteger buttonClicked = [panel runModal];
	if (buttonClicked == NSFileHandlingPanelOKButton)
	{
		NSURL *fileURL = [panel URL];
		if(fileURL == nil)
		{
			return;
		}
		
		[self pauseCore];
		CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
		NSURL *sramURL = [CocoaDSFile fileURLFromRomURL:[[self currentRom] fileURL] toKind:@"ROM Save"];
		
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		const BOOL exists = [fileManager isReadableFileAtPath:[sramURL path]];
		[fileManager release];
		
		const BOOL isMovieStarted = [cdsCore startReplayRecording:fileURL sramURL:sramURL];
		[self setStatusText:(isMovieStarted) ? @"Replay recording started." : @"Replay creation failed!"];
		[self restoreCoreState];
	}
}

- (IBAction) stopReplay:(id)sender
{
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	
	[self pauseCore];
	[cdsCore stopReplay];
	[self setStatusText:@"Replay stopped."];
	[self restoreCoreState];
}

- (IBAction) importRomSave:(id)sender
{
	NSURL *selectedFile = nil;
	
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:NO];
	[panel setCanChooseFiles:YES];
	[panel setResolvesAliases:YES];
	[panel setAllowsMultipleSelection:NO];
	[panel setTitle:NSSTRING_TITLE_IMPORT_ROM_SAVE_PANEL];
	NSArray *fileTypes = [NSArray arrayWithObjects:
						  @FILE_EXT_ROM_SAVE_RAW,
						  @FILE_EXT_ACTION_REPLAY_SAVE,
						  @FILE_EXT_ACTION_REPLAY_MAX_SAVE,
						  nil];
	
	// The NSOpenPanel method -(NSInt)runModalForDirectory:file:types:
	// is deprecated in Mac OS X v10.6.
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
	[panel setAllowedFileTypes:fileTypes];
	const NSInteger buttonClicked = [panel runModal];
#else
	const NSInteger buttonClicked = [panel runModalForDirectory:nil file:nil types:fileTypes];
#endif
	
	if (buttonClicked == NSFileHandlingPanelOKButton)
	{
		selectedFile = [[panel URLs] lastObject];
		if(selectedFile == nil)
		{
			return;
		}
		
		const BOOL isRomSaveImported = [CocoaDSFile importRomSave:selectedFile];
		[self setStatusText:(isRomSaveImported) ? NSSTRING_STATUS_ROM_SAVE_IMPORTED : NSSTRING_STATUS_ROM_SAVE_IMPORT_FAILED];
	}
}

- (IBAction) exportRomSave:(id)sender
{
	[self pauseCore];
	
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setTitle:NSSTRING_TITLE_EXPORT_ROM_SAVE_PANEL];
	[panel setCanCreateDirectories:YES];
	[panel setAccessoryView:exportRomSavePanelAccessoryView];
	
	const NSInteger buttonClicked = [panel runModal];
	if(buttonClicked == NSOKButton)
	{
		NSURL *romSaveURL = [CocoaDSFile fileURLFromRomURL:[[self currentRom] fileURL] toKind:@"ROM Save"];
		if (romSaveURL != nil)
		{
			const BOOL isRomSaveExported = [CocoaDSFile exportRomSaveToURL:[panel URL] romSaveURL:romSaveURL fileType:[self selectedExportRomSaveID]];
			[self setStatusText:(isRomSaveExported) ? NSSTRING_STATUS_ROM_SAVE_EXPORTED : NSSTRING_STATUS_ROM_SAVE_EXPORT_FAILED];
		}
	}
	
	[self restoreCoreState];
}

- (IBAction) toggleExecutePause:(id)sender
{
	[inputManager dispatchCommandUsingIBAction:_cmd sender:sender];
}

- (IBAction) coreExecute:(id)sender
{
	[inputManager dispatchCommandUsingIBAction:_cmd sender:sender];
}

- (IBAction) corePause:(id)sender
{
	[inputManager dispatchCommandUsingIBAction:_cmd sender:sender];
}

- (IBAction) frameAdvance:(id)sender
{
	[inputManager dispatchCommandUsingIBAction:_cmd sender:sender];
}

- (IBAction) frameJump:(id)sender
{
	[inputManager dispatchCommandUsingIBAction:_cmd sender:sender];
}

- (IBAction) reset:(id)sender
{
	[inputManager dispatchCommandUsingIBAction:_cmd sender:sender];
}

- (IBAction) toggleSpeedLimiter:(id)sender
{
	[inputManager dispatchCommandUsingIBAction:_cmd sender:sender];
}

- (IBAction) toggleAutoFrameSkip:(id)sender
{
	[inputManager dispatchCommandUsingIBAction:_cmd sender:sender];
}

- (IBAction) toggleGPUState:(id)sender
{
	[inputManager dispatchCommandUsingIBAction:_cmd sender:sender];
}

- (IBAction) toggleGDBStubActivate:(id)sender
{
	// Force end of editing of any text fields.
	[[(NSControl *)sender window] makeFirstResponder:nil];
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	const BOOL willStart = ([cdsCore isGdbStubStarted]) ? NO : YES;
	[cdsCore setIsGdbStubStarted:willStart];
	[(NSButton *)sender setTitle:([cdsCore isGdbStubStarted]) ? @"Stop" : @"Start"];
}

- (IBAction) changeRomSaveType:(id)sender
{
	const NSInteger saveTypeID = [CocoaDSUtil getIBActionSenderTag:sender];
	[self setSelectedRomSaveTypeID:saveTypeID];
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[cdsCore changeRomSaveType:saveTypeID];
}

- (IBAction) toggleCheats:(id)sender
{
	[inputManager dispatchCommandUsingIBAction:_cmd sender:sender];
}

- (IBAction) changeCoreSpeed:(id)sender
{
	if ([sender isKindOfClass:[NSSlider class]])
	{
		lastSetSpeedScalar = [(NSSlider *)sender floatValue];
	}
	else
	{
		const CGFloat newSpeedScalar = (CGFloat)[CocoaDSUtil getIBActionSenderTag:sender] / 100.0f;
		[self changeCoreSpeedWithDouble:newSpeedScalar];
	}
	
	[self setVerticalSyncForNonLayerBackedViews:sender];
}

- (IBAction) changeFirmwareSettings:(id)sender
{
	// Force end of editing of any text fields.
	[[(NSControl *)sender window] makeFirstResponder:nil];
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[[cdsCore cdsFirmware] update];
}

- (IBAction) changeHardwareMicGain:(id)sender
{
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[[cdsCore cdsController] setHardwareMicGain:([self currentMicGainValue]/100.0f)];
}

- (IBAction) changeHardwareMicMute:(id)sender
{
	const BOOL muteState = [CocoaDSUtil getIBActionSenderButtonStateBool:sender];
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[[cdsCore cdsController] setHardwareMicMute:muteState];
	[[cdsCore cdsController] setHardwareMicPause:([cdsCore coreState] != ExecutionBehavior_Run)];
	[self updateMicStatusIcon];
}

- (IBAction) changeVolume:(id)sender
{
	const float vol = [self currentVolumeValue];
	[self setCurrentVolumeValue:vol];
	[CocoaDSUtil messageSendOneWayWithFloat:[cdsSpeaker receivePort] msgID:MESSAGE_SET_VOLUME floatValue:vol];
}

- (IBAction) changeAudioEngine:(id)sender
{
	[CocoaDSUtil messageSendOneWayWithInteger:[cdsSpeaker receivePort] msgID:MESSAGE_SET_AUDIO_PROCESS_METHOD integerValue:[CocoaDSUtil getIBActionSenderTag:sender]];
}

- (IBAction) changeSpuAdvancedLogic:(id)sender
{
	[CocoaDSUtil messageSendOneWayWithBool:[cdsSpeaker receivePort] msgID:MESSAGE_SET_SPU_ADVANCED_LOGIC boolValue:[CocoaDSUtil getIBActionSenderButtonStateBool:sender]];
}

- (IBAction) changeSpuInterpolationMode:(id)sender
{
	[CocoaDSUtil messageSendOneWayWithInteger:[cdsSpeaker receivePort] msgID:MESSAGE_SET_SPU_INTERPOLATION_MODE integerValue:[CocoaDSUtil getIBActionSenderTag:sender]];
}

- (IBAction) changeSpuSyncMode:(id)sender
{
	[CocoaDSUtil messageSendOneWayWithInteger:[cdsSpeaker receivePort] msgID:MESSAGE_SET_SPU_SYNC_MODE integerValue:[CocoaDSUtil getIBActionSenderTag:sender]];
}

- (IBAction) changeSpuSyncMethod:(id)sender
{
	[CocoaDSUtil messageSendOneWayWithInteger:[cdsSpeaker receivePort] msgID:MESSAGE_SET_SPU_SYNC_METHOD integerValue:[CocoaDSUtil getIBActionSenderTag:sender]];
}

- (IBAction) toggleAllDisplays:(id)sender
{
	[inputManager dispatchCommandUsingIBAction:_cmd sender:sender];
}

- (IBAction) autoholdSet:(id)sender
{
	[inputManager dispatchCommandUsingIBAction:_cmd sender:sender];
}

- (IBAction) autoholdClear:(id)sender
{
	[inputManager dispatchCommandUsingIBAction:_cmd sender:sender];
}

- (IBAction) setVerticalSyncForNonLayerBackedViews:(id)sender
{
	if ( ([[(DisplayWindowController *)[windowList objectAtIndex:0] view] layer] == nil) && ([windowList count] > 0) )
	{
		CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
		const BOOL useVerticalSync = [cdsCore isFrameSkipEnabled] || (([cdsCore speedScalar] < 1.03f) && [cdsCore isSpeedLimitEnabled]);
		
		for (DisplayWindowController *windowController in windowList)
		{
			[[windowController view] setUseVerticalSync:useVerticalSync];
		}
	}
}

- (IBAction) chooseSlot1R4Directory:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:NO];
	[panel setResolvesAliases:YES];
	[panel setAllowsMultipleSelection:NO];
	[panel setTitle:@"Select R4 Directory"];
	
	// The NSOpenPanel/NSSavePanel method -(void)beginSheetForDirectory:file:types:modalForWindow:modalDelegate:didEndSelector:contextInfo
	// is deprecated in Mac OS X v10.6.
#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_5
	[panel beginSheetModalForWindow:slot1ManagerWindow
				  completionHandler:^(NSInteger result) {
					  [self didEndChooseSlot1R4Directory:panel returnCode:result contextInfo:nil];
				  } ];
#else
	[panel beginSheetForDirectory:nil
							 file:nil
							types:nil
				   modalForWindow:slot1ManagerWindow
					modalDelegate:self
				   didEndSelector:@selector(didEndChooseSlot1R4Directory:returnCode:contextInfo:)
					  contextInfo:nil];
#endif
}

- (IBAction) slot1Eject:(id)sender
{
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[cdsCore slot1Eject];
}

- (IBAction) writeDefaults3DRenderingSettings:(id)sender
{
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	
	// Force end of editing of any text fields.
	[[(NSControl *)sender window] makeFirstResponder:nil];
	
	[[NSUserDefaults standardUserDefaults] setInteger:[[cdsCore cdsGPU] render3DRenderingEngine] forKey:@"Render3D_RenderingEngine"];
	[[NSUserDefaults standardUserDefaults] setBool:[[cdsCore cdsGPU] render3DHighPrecisionColorInterpolation] forKey:@"Render3D_HighPrecisionColorInterpolation"];
	[[NSUserDefaults standardUserDefaults] setBool:[[cdsCore cdsGPU] render3DEdgeMarking] forKey:@"Render3D_EdgeMarking"];
	[[NSUserDefaults standardUserDefaults] setBool:[[cdsCore cdsGPU] render3DFog] forKey:@"Render3D_Fog"];
	[[NSUserDefaults standardUserDefaults] setBool:[[cdsCore cdsGPU] render3DTextures] forKey:@"Render3D_Textures"];
	[[NSUserDefaults standardUserDefaults] setInteger:[[cdsCore cdsGPU] render3DThreads] forKey:@"Render3D_Threads"];
	[[NSUserDefaults standardUserDefaults] setBool:[[cdsCore cdsGPU] render3DLineHack] forKey:@"Render3D_LineHack"];
	[[NSUserDefaults standardUserDefaults] setBool:[[cdsCore cdsGPU] render3DMultisample] forKey:@"Render3D_Multisample"];
	[[NSUserDefaults standardUserDefaults] setInteger:[[cdsCore cdsGPU] render3DTextureScalingFactor] forKey:@"Render3D_TextureScalingFactor"];
	[[NSUserDefaults standardUserDefaults] setBool:[[cdsCore cdsGPU] render3DTextureDeposterize] forKey:@"Render3D_TextureDeposterize"];
	[[NSUserDefaults standardUserDefaults] setBool:[[cdsCore cdsGPU] render3DTextureSmoothing] forKey:@"Render3D_TextureSmoothing"];
	[[NSUserDefaults standardUserDefaults] setBool:[[cdsCore cdsGPU] render3DFragmentSamplingHack] forKey:@"Render3D_FragmentSamplingHack"];
	[[NSUserDefaults standardUserDefaults] setInteger:[[cdsCore cdsGPU] gpuScale] forKey:@"Render3D_ScalingFactor"];
	[[NSUserDefaults standardUserDefaults] setInteger:[[cdsCore cdsGPU] gpuColorFormat] forKey:@"Render3D_ColorFormat"];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction) writeDefaultsEmulationSettings:(id)sender
{
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	NSDictionary *firmwareDict = [(CocoaDSFirmware *)[firmwarePanelController content] dataDictionary];
	
	// Force end of editing of any text fields.
	[[(NSControl *)sender window] makeFirstResponder:nil];
	
	[[NSUserDefaults standardUserDefaults] setBool:[cdsCore emuFlagAdvancedBusLevelTiming] forKey:@"Emulation_AdvancedBusLevelTiming"];
	[[NSUserDefaults standardUserDefaults] setBool:[cdsCore emuFlagRigorousTiming] forKey:@"Emulation_RigorousTiming"];
	[[NSUserDefaults standardUserDefaults] setBool:[cdsCore emuFlagUseGameSpecificHacks] forKey:@"Emulation_UseGameSpecificHacks"];
	[[NSUserDefaults standardUserDefaults] setInteger:[cdsCore cpuEmulationEngine] forKey:@"Emulation_CPUEmulationEngine"];
	[[NSUserDefaults standardUserDefaults] setInteger:[cdsCore maxJITBlockSize] forKey:@"Emulation_MaxJITBlockSize"];
	[[NSUserDefaults standardUserDefaults] setBool:[cdsCore emuFlagUseExternalBios] forKey:@"Emulation_UseExternalBIOSImages"];
	[[NSUserDefaults standardUserDefaults] setBool:[cdsCore emuFlagEmulateBiosInterrupts] forKey:@"Emulation_BIOSEmulateSWI"];
	[[NSUserDefaults standardUserDefaults] setBool:[cdsCore emuFlagPatchDelayLoop] forKey:@"Emulation_BIOSPatchDelayLoopSWI"];
	[[NSUserDefaults standardUserDefaults] setBool:[cdsCore emuFlagUseExternalFirmware] forKey:@"Emulation_UseExternalFirmwareImage"];
	[[NSUserDefaults standardUserDefaults] setBool:[cdsCore emuFlagFirmwareBoot] forKey:@"Emulation_FirmwareBoot"];
	[[NSUserDefaults standardUserDefaults] setBool:[cdsCore emuFlagEmulateEnsata] forKey:@"Emulation_EmulateEnsata"];
	[[NSUserDefaults standardUserDefaults] setBool:[cdsCore emuFlagDebugConsole] forKey:@"Emulation_UseDebugConsole"];
	
	[[NSUserDefaults standardUserDefaults] setObject:[firmwareDict valueForKey:@"Nickname"] forKey:@"FirmwareConfig_Nickname"];
	[[NSUserDefaults standardUserDefaults] setObject:[firmwareDict valueForKey:@"Message"] forKey:@"FirmwareConfig_Message"];
	[[NSUserDefaults standardUserDefaults] setObject:[firmwareDict valueForKey:@"FavoriteColor"] forKey:@"FirmwareConfig_FavoriteColor"];
	[[NSUserDefaults standardUserDefaults] setObject:[firmwareDict valueForKey:@"Birthday"] forKey:@"FirmwareConfig_Birthday"];
	[[NSUserDefaults standardUserDefaults] setObject:[firmwareDict valueForKey:@"Language"] forKey:@"FirmwareConfig_Language"];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction) writeDefaultsSlot1Settings:(id)sender
{
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	
	[[NSUserDefaults standardUserDefaults] setInteger:[cdsCore slot1DeviceType] forKey:@"EmulationSlot1_DeviceType"];
	[[NSUserDefaults standardUserDefaults] setObject:[[cdsCore slot1R4URL] path] forKey:@"EmulationSlot1_R4StoragePath"];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction) writeDefaultsSoundSettings:(id)sender
{
	NSMutableDictionary *speakerBindings = (NSMutableDictionary *)[cdsSoundController content];
	
	[[NSUserDefaults standardUserDefaults] setFloat:[[speakerBindings valueForKey:@"volume"] floatValue] forKey:@"Sound_Volume"];
	[[NSUserDefaults standardUserDefaults] setInteger:[[speakerBindings valueForKey:@"audioOutputEngine"] integerValue] forKey:@"Sound_AudioOutputEngine"];
	[[NSUserDefaults standardUserDefaults] setBool:[[speakerBindings valueForKey:@"spuAdvancedLogic"] boolValue] forKey:@"SPU_AdvancedLogic"];
	[[NSUserDefaults standardUserDefaults] setInteger:[[speakerBindings valueForKey:@"spuInterpolationMode"] integerValue] forKey:@"SPU_InterpolationMode"];
	[[NSUserDefaults standardUserDefaults] setInteger:[[speakerBindings valueForKey:@"spuSyncMode"] integerValue] forKey:@"SPU_SyncMode"];
	[[NSUserDefaults standardUserDefaults] setInteger:[[speakerBindings valueForKey:@"spuSyncMethod"] integerValue] forKey:@"SPU_SyncMethod"];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction) writeDefaultsStylusSettings:(id)sender
{
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	CocoaDSController *cdsController = [cdsCore cdsController];
	
	[[NSUserDefaults standardUserDefaults] setInteger:[cdsController stylusPressure] forKey:@"Emulation_StylusPressure"];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction) closeSheet:(id)sender
{
	NSWindow *sheet = [(NSControl *)sender window];
	const NSInteger code = [(NSControl *)sender tag];
	
    [NSApp endSheet:sheet returnCode:code];
}

#pragma mark Class Methods

- (void) cmdUpdateDSController:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	const BOOL theState = (cmdAttr.input.state == ClientInputDeviceState_On) ? YES : NO;
	const NSUInteger controlID = cmdAttr.intValue[0];
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[[cdsCore cdsController] setControllerState:theState controlID:controlID];
	
	for (DisplayWindowController *windowController in windowList)
	{
		[[[windowController view] cdsVideoOutput] setNDSFrameInfo:[cdsCore execControl]->GetNDSFrameInfo()];
		[[[windowController view] cdsVideoOutput] hudUpdate];
		
		if ([[windowController view] isHUDInputVisible])
		{
			[[windowController view] clientDisplay3DView]->UpdateView();
		}
	}
}

- (void) cmdUpdateDSControllerWithTurbo:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	const BOOL theState = (cmdAttr.input.state == ClientInputDeviceState_On) ? YES : NO;
	const NSUInteger controlID = cmdAttr.intValue[0];
	const BOOL isTurboEnabled = (BOOL)cmdAttr.intValue[1];
	const uint32_t turboPattern = (uint32_t)cmdAttr.intValue[2];
	const uint32_t turboPatternLength = (uint32_t)cmdAttr.intValue[3];
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[[cdsCore cdsController] setControllerState:theState controlID:controlID turbo:isTurboEnabled turboPattern:turboPattern turboPatternLength:turboPatternLength];
	
	for (DisplayWindowController *windowController in windowList)
	{
		[[[windowController view] cdsVideoOutput] setNDSFrameInfo:[cdsCore execControl]->GetNDSFrameInfo()];
		[[[windowController view] cdsVideoOutput] hudUpdate];
		
		if ([[windowController view] isHUDInputVisible])
		{
			[[windowController view] clientDisplay3DView]->UpdateView();
		}
	}
}

- (void) cmdUpdateDSTouch:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	const BOOL theState = (cmdAttr.input.state == ClientInputDeviceState_On) ? YES : NO;
	
	const NSPoint touchLoc = (cmdAttr.useInputForIntCoord) ? NSMakePoint(cmdAttr.input.intCoordX, cmdAttr.input.intCoordY) : NSMakePoint(cmdAttr.intValue[1], cmdAttr.intValue[2]);
	if (touchLoc.x >= 0.0 && touchLoc.y >= 0.0)
	{
		CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
		[[cdsCore cdsController] setTouchState:theState location:touchLoc];
		
		for (DisplayWindowController *windowController in windowList)
		{
			[[[windowController view] cdsVideoOutput] setNDSFrameInfo:[cdsCore execControl]->GetNDSFrameInfo()];
			[[[windowController view] cdsVideoOutput] hudUpdate];
			
			if ([[windowController view] isHUDInputVisible])
			{
				[[windowController view] clientDisplay3DView]->UpdateView();
			}
		}
	}
}

- (void) cmdUpdateDSMicrophone:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	const BOOL theState = (cmdAttr.input.state == ClientInputDeviceState_On) ? YES : NO;
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	CocoaDSController *cdsController = [cdsCore cdsController];
	
	const NSInteger micMode = cmdAttr.intValue[1];
	[cdsController setSoftwareMicState:theState mode:micMode];
	
	const float sineWaveFrequency = cmdAttr.floatValue[0];
	[cdsController setSineWaveGeneratorFrequency:sineWaveFrequency];
	
	NSString *audioFilePath = (NSString *)cmdAttr.object[0];
	[cdsController setSelectedAudioFileGenerator:[inputManager audioFileGeneratorFromFilePath:audioFilePath]];
}

- (void) cmdUpdateDSPaddle:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	
	if (cmdAttr.input.isAnalog)
	{
		const float paddleSensitivity = cmdAttr.floatValue[0];
		const float paddleScalar = cmdAttr.input.scalar;
		float paddleAdjust = (paddleScalar * 2.0f) - 1.0f;
		
		// Clamp the paddle value.
		if (paddleAdjust < -1.0f)
		{
			paddleAdjust = -1.0f;
		}
		
		if (paddleAdjust > 1.0f)
		{
			paddleAdjust = 1.0f;
		}
		
		// Normalize the input value for the paddle.
		paddleAdjust *= paddleSensitivity;
		[[cdsCore cdsController] setPaddleAdjust:(NSInteger)(paddleAdjust + 0.5f)];
	}
	else
	{
		const BOOL theState = (cmdAttr.input.state == ClientInputDeviceState_On) ? YES : NO;
		const NSInteger paddleAdjust = (theState) ? cmdAttr.intValue[1] : 0;
		[[cdsCore cdsController] setPaddleAdjust:paddleAdjust];
	}
}

- (void) cmdAutoholdSet:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	const BOOL theState = (cmdAttr.input.state == ClientInputDeviceState_On) ? YES : NO;
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[[cdsCore cdsController] setAutohold:theState];
	[self setStatusText:(theState) ? NSSTRING_STATUS_AUTOHOLD_SET : NSSTRING_STATUS_AUTOHOLD_SET_RELEASE];
}

- (void) cmdAutoholdClear:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	
	if (cmdAttr.input.state == ClientInputDeviceState_Off)
	{
		return;
	}
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[[cdsCore cdsController] clearAutohold];
	[self setStatusText:NSSTRING_STATUS_AUTOHOLD_CLEAR];
	
}

- (void) cmdLoadEmuSaveStateSlot:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	
	if (cmdAttr.input.state == ClientInputDeviceState_Off)
	{
		return;
	}
	
	NSString *saveStatePath = [[CocoaDSFile saveStateURL] path];
	if (saveStatePath == nil)
	{
		// Should throw an error message here...
		return;
	}
	
	const NSInteger slotNumber = (cmdAttr.useInputForSender) ? [CocoaDSUtil getIBActionSenderTag:(id)cmdAttr.input.object] : cmdAttr.intValue[0];
	if (slotNumber < 0 || slotNumber > MAX_SAVESTATE_SLOTS)
	{
		return;
	}
	
	NSURL *currentRomURL = [[self currentRom] fileURL];
	NSString *fileName = [CocoaDSFile saveSlotFileName:currentRomURL slotNumber:(NSUInteger)(slotNumber + 1)];
	if (fileName == nil)
	{
		return;
	}
	
	[self pauseCore];
	
	const BOOL isStateLoaded = [CocoaDSFile loadState:[NSURL fileURLWithPath:[saveStatePath stringByAppendingPathComponent:fileName]]];
	[self setStatusText:(isStateLoaded) ? NSSTRING_STATUS_SAVESTATE_LOADED : NSSTRING_STATUS_SAVESTATE_LOADING_FAILED];
	
	[self restoreCoreState];
}

- (void) cmdSaveEmuSaveStateSlot:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	
	if (cmdAttr.input.state == ClientInputDeviceState_Off)
	{
		return;
	}
	
	NSString *saveStatePath = [[CocoaDSFile saveStateURL] path];
	if (saveStatePath == nil)
	{
		[self setStatusText:NSSTRING_STATUS_CANNOT_GENERATE_SAVE_PATH];
		return;
	}
	
	const BOOL isDirectoryCreated = [CocoaDSFile createUserAppSupportDirectory:@"States"];
	if (!isDirectoryCreated)
	{
		[self setStatusText:NSSTRING_STATUS_CANNOT_CREATE_SAVE_DIRECTORY];
		return;
	}
	
	const NSInteger slotNumber = (cmdAttr.useInputForSender) ? [CocoaDSUtil getIBActionSenderTag:(id)cmdAttr.input.object] : cmdAttr.intValue[0];
	if (slotNumber < 0 || slotNumber > MAX_SAVESTATE_SLOTS)
	{
		return;
	}
	
	NSURL *currentRomURL = [[self currentRom] fileURL];
	NSString *fileName = [CocoaDSFile saveSlotFileName:currentRomURL slotNumber:(NSUInteger)(slotNumber + 1)];
	if (fileName == nil)
	{
		return;
	}
	
	[self pauseCore];
	
	const BOOL isStateSaved = [CocoaDSFile saveState:[NSURL fileURLWithPath:[saveStatePath stringByAppendingPathComponent:fileName]]];
	[self setStatusText:(isStateSaved) ? NSSTRING_STATUS_SAVESTATE_SAVED : NSSTRING_STATUS_SAVESTATE_SAVING_FAILED];
	
	[self restoreCoreState];
}

- (void) cmdCopyScreen:(NSValue *)cmdAttrValue
{
	[mainWindow copy:nil];
}

- (void) cmdRotateDisplayRelative:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	
	if (cmdAttr.input.state == ClientInputDeviceState_Off)
	{
		return;
	}
	
	const double relativeDegrees = (cmdAttr.useInputForSender) ? (double)[CocoaDSUtil getIBActionSenderTag:(id)cmdAttr.input.object] : (double)cmdAttr.intValue[0];
	const double angleDegrees = [mainWindow displayRotation] + relativeDegrees;
	[mainWindow setDisplayRotation:angleDegrees];
}

- (void) cmdToggleAllDisplays:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	
	if (cmdAttr.input.state == ClientInputDeviceState_Off)
	{
		return;
	}
	
	for (DisplayWindowController *theWindow in windowList)
	{
		const NSInteger displayMode = [theWindow displayMode];
		switch (displayMode)
		{
			case ClientDisplayMode_Main:
				[theWindow setDisplayMode:ClientDisplayMode_Touch];
				break;
				
			case ClientDisplayMode_Touch:
				[theWindow setDisplayMode:ClientDisplayMode_Main];
				break;
				
			case ClientDisplayMode_Dual:
			{
				const NSInteger displayOrder = [theWindow displayOrder];
				if (displayOrder == ClientDisplayOrder_MainFirst)
				{
					[theWindow setDisplayOrder:ClientDisplayOrder_TouchFirst];
				}
				else
				{
					[theWindow setDisplayOrder:ClientDisplayOrder_MainFirst];
				}
				break;
			}
				
			default:
				break;
		}
	}
}

- (void) cmdHoldToggleSpeedScalar:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	const float inputSpeedScalar = (cmdAttr.useInputForScalar) ? cmdAttr.input.scalar : cmdAttr.floatValue[0];
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	
	[cdsCore setSpeedScalar:(cmdAttr.input.state == ClientInputDeviceState_Off) ? lastSetSpeedScalar : inputSpeedScalar];
	[self setVerticalSyncForNonLayerBackedViews:nil];
}

- (void) cmdToggleSpeedLimiter:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	
	if (cmdAttr.input.state == ClientInputDeviceState_Off)
	{
		return;
	}
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	
	if ([cdsCore isSpeedLimitEnabled])
	{
		[cdsCore setIsSpeedLimitEnabled:NO];
		[self setStatusText:NSSTRING_STATUS_SPEED_LIMIT_DISABLED];
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CoreControl_EnableSpeedLimit"];
	}
	else
	{
		[cdsCore setIsSpeedLimitEnabled:YES];
		[self setStatusText:NSSTRING_STATUS_SPEED_LIMIT_ENABLED];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CoreControl_EnableSpeedLimit"];
	}
	
	[self setVerticalSyncForNonLayerBackedViews:nil];
}

- (void) cmdToggleAutoFrameSkip:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	
	if (cmdAttr.input.state == ClientInputDeviceState_Off)
	{
		return;
	}
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	
	if ([cdsCore isFrameSkipEnabled])
	{
		[cdsCore setIsFrameSkipEnabled:NO];
		[self setStatusText:NSSTRING_STATUS_AUTO_FRAME_SKIP_DISABLED];
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CoreControl_EnableAutoFrameSkip"];
	}
	else
	{
		[cdsCore setIsFrameSkipEnabled:YES];
		[self setStatusText:NSSTRING_STATUS_AUTO_FRAME_SKIP_ENABLED];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CoreControl_EnableAutoFrameSkip"];
	}
	
	[self setVerticalSyncForNonLayerBackedViews:nil];
}

- (void) cmdToggleCheats:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	
	if (cmdAttr.input.state == ClientInputDeviceState_Off)
	{
		return;
	}
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	
	if ([cdsCore isCheatingEnabled])
	{
		[cdsCore setIsCheatingEnabled:NO];
		[self setStatusText:NSSTRING_STATUS_CHEATS_DISABLED];
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"CoreControl_EnableCheats"];
	}
	else
	{
		[cdsCore setIsCheatingEnabled:YES];
		[self setStatusText:NSSTRING_STATUS_CHEATS_ENABLED];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CoreControl_EnableCheats"];
	}
}

- (void) cmdToggleExecutePause:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	
	if ( (cmdAttr.input.state == ClientInputDeviceState_Off) || ([self currentRom] == nil) )
	{
		return;
	}
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	
	if ([cdsCore coreState] == ExecutionBehavior_Pause)
	{
		[self executeCore];
	}
	else
	{
		[self pauseCore];
	}
}

- (void) cmdCoreExecute:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	
	if ( (cmdAttr.input.state == ClientInputDeviceState_Off) || ([self currentRom] == nil) )
	{
		return;
	}
	
	[self executeCore];
}

- (void) cmdCorePause:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	
	if ( (cmdAttr.input.state == ClientInputDeviceState_Off) || ([self currentRom] == nil) )
	{
		return;
	}
	
	[self pauseCore];
}

- (void) cmdFrameAdvance:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	
	if ( (cmdAttr.input.state == ClientInputDeviceState_Off) ||
	     ([cdsCore coreState] != ExecutionBehavior_Pause) ||
	     ([self currentRom] == nil) )
	{
		return;
	}
	
	[cdsCore setCoreState:ExecutionBehavior_FrameAdvance];
}

- (void) cmdFrameJump:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	
	if ( (cmdAttr.input.state == ClientInputDeviceState_Off) || ([self currentRom] == nil) )
	{
		return;
	}
	
	[executionControlWindow makeFirstResponder:nil];
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[cdsCore setCoreState:ExecutionBehavior_FrameJump];
}

- (void) cmdReset:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	
	if ( (cmdAttr.input.state == ClientInputDeviceState_Off) || ([self currentRom] == nil) )
	{
		return;
	}
	
	[self setStatusText:NSSTRING_STATUS_EMULATOR_RESETTING];
	[self setIsWorking:YES];
	
	for (DisplayWindowController *windowController in windowList)
	{
		[[windowController window] displayIfNeeded];
	}
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[cdsCore reset];
	
	for (DisplayWindowController *windowController in windowList)
	{
		[CocoaDSUtil messageSendOneWay:[[[windowController view] cdsVideoOutput] receivePort] msgID:MESSAGE_RELOAD_REPROCESS_REDRAW];
	}
	
	[self setStatusText:NSSTRING_STATUS_EMULATOR_RESET];
	[self setIsWorking:NO];
	[self writeDefaultsSlot1Settings:nil];
	
	for (DisplayWindowController *windowController in windowList)
	{
		[[windowController window] displayIfNeeded];
	}
}

- (void) cmdToggleMute:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	
	if (cmdAttr.input.state == ClientInputDeviceState_Off)
	{
		return;
	}
	
	float vol = 0.0f;
	
	if (isSoundMuted)
	{
		isSoundMuted = NO;
		vol = lastSetVolumeValue;
		[self setStatusText:@"Sound unmuted."];
	}
	else
	{
		isSoundMuted = YES;
		[self setStatusText:@"Sound muted."];
	}

	[self setCurrentVolumeValue:vol];
	[CocoaDSUtil messageSendOneWayWithFloat:[cdsSpeaker receivePort] msgID:MESSAGE_SET_VOLUME floatValue:vol];
}

- (void) cmdToggleGPUState:(NSValue *)cmdAttrValue
{
	CommandAttributes cmdAttr;
	[cmdAttrValue getValue:&cmdAttr];
	
	if (cmdAttr.input.state == ClientInputDeviceState_Off)
	{
		return;
	}
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	const NSInteger bitNumber = (cmdAttr.useInputForSender) ? [CocoaDSUtil getIBActionSenderTag:(id)cmdAttr.input.object] : cmdAttr.intValue[0];
	const UInt32 flagBit = [cdsCore.cdsGPU gpuStateFlags] ^ (1 << bitNumber);
	
	[cdsCore.cdsGPU setGpuStateFlags:flagBit];
}

- (BOOL) handleLoadRomByURL:(NSURL *)fileURL
{
	BOOL result = NO;
	
	if (fileURL == nil || [self isRomLoading])
	{
		return result;
	}
	
	if ([self currentRom] != nil)
	{
		const BOOL closeResult = [self handleUnloadRom:REASONFORCLOSE_OPEN romToLoad:fileURL];
		if ([self isShowingSaveStateDialog])
		{
			return result;
		}
		
		if (![self isShowingFileMigrationDialog] && !closeResult)
		{
			return result;
		}
	}
	
	// Check for the v0.9.7 ROM Save File
	if ([CocoaDSFile romSaveExistsWithRom:fileURL] && ![CocoaDSFile romSaveExists:fileURL])
	{
		[fileURL retain];
		[self setIsUserInterfaceBlockingExecution:YES];
		[self setIsShowingFileMigrationDialog:YES];
		
		[NSApp beginSheet:saveFileMigrationSheet
		   modalForWindow:[[windowList objectAtIndex:0] window]
            modalDelegate:self
		   didEndSelector:@selector(didEndFileMigrationSheet:returnCode:contextInfo:)
			  contextInfo:fileURL];
	}
	else
	{
		result = [self loadRomByURL:fileURL asynchronous:YES];
	}
	
	return result;
}

- (BOOL) handleUnloadRom:(NSInteger)reasonID romToLoad:(NSURL *)romURL
{
	BOOL result = NO;
	
	if ([self isRomLoading] || [self currentRom] == nil)
	{
		return result;
	}
	
	[self pauseCore];
	
	if (isSaveStateEdited && [self currentSaveStateURL] != nil)
	{
		SEL endSheetSelector = @selector(didEndSaveStateSheet:returnCode:contextInfo:);
		
		switch (reasonID)
		{
			case REASONFORCLOSE_OPEN:
				[romURL retain];
				endSheetSelector = @selector(didEndSaveStateSheetOpen:returnCode:contextInfo:);
				break;	
				
			case REASONFORCLOSE_TERMINATE:
				endSheetSelector = @selector(didEndSaveStateSheetTerminate:returnCode:contextInfo:);
				break;
				
			default:
				break;
		}
		
		[self setIsUserInterfaceBlockingExecution:YES];
		[self setIsShowingSaveStateDialog:YES];
		
		[NSApp beginSheet:saveStatePrecloseSheet
		   modalForWindow:(NSWindow *)[[windowList objectAtIndex:0] window]
            modalDelegate:self
		   didEndSelector:endSheetSelector
			  contextInfo:romURL];
	}
	else
	{
		result = [self unloadRom];
	}
	
	return result;
}

- (BOOL) loadRomByURL:(NSURL *)romURL asynchronous:(BOOL)willLoadAsync
{
	BOOL result = NO;
	
	if (romURL == nil)
	{
		return result;
	}
	
	[self setStatusText:NSSTRING_STATUS_ROM_LOADING];
	[self setIsWorking:YES];
	
	for (DisplayWindowController *windowController in windowList)
	{
		[[windowController window] displayIfNeeded];
	}
	
	// Need to pause the core before loading the ROM.
	[self pauseCore];
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[cdsCore execControl]->ApplySettingsOnReset();
	[cdsCore updateSlot1DeviceStatus];
	[self writeDefaultsSlot1Settings:nil];
	
	CocoaDSRom *newRom = [[CocoaDSRom alloc] init];
	if (newRom != nil)
	{
		[self setIsRomLoading:YES];
		[romURL retain];
		[newRom setSaveType:selectedRomSaveTypeID];
		[newRom setWillStreamLoadData:[[NSUserDefaults standardUserDefaults] boolForKey:@"General_StreamLoadRomData"]];
		
		if (willLoadAsync)
		{
			[NSThread detachNewThreadSelector:@selector(loadDataOnThread:) toTarget:newRom withObject:romURL];
		}
		else
		{
			[newRom loadData:romURL];
		}
		
		[romURL release];
	}
	
	result = YES;
	
	return result;
}

- (void) loadRomDidFinish:(NSNotification *)aNotification
{
	CocoaDSRom *theRom = [aNotification object];
	NSDictionary *userInfo = [aNotification userInfo];
	const BOOL didLoad = [(NSNumber *)[userInfo valueForKey:@"DidLoad"] boolValue];
	
	if ( theRom == nil || !didLoad || (![theRom willStreamLoadData] && ![theRom isDataLoaded]) )
	{
		// If ROM loading fails, restore the core state, but only if a ROM is already loaded.
		if([self currentRom] != nil)
		{
			[self restoreCoreState];
		}
		
		[self setStatusText:NSSTRING_STATUS_ROM_LOADING_FAILED];
		[self setIsWorking:NO];
		[self setIsRomLoading:NO];
		
		return;
	}
	
	// Set the core's ROM to our newly allocated ROM object.
	[self setCurrentRom:theRom];
	[romInfoPanelController setContent:[theRom bindings]];
	
	// If the ROM has an associated cheat file, load it now.
	NSString *cheatsPath = [[CocoaDSFile fileURLFromRomURL:[theRom fileURL] toKind:@"Cheat"] path];
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	CocoaDSCheatManager *newCheatList = [[[CocoaDSCheatManager alloc] initWithFileURL:[NSURL fileURLWithPath:cheatsPath]] autorelease];
	if (newCheatList != nil)
	{
		NSMutableDictionary *cheatWindowBindings = (NSMutableDictionary *)[cheatWindowController content];
		
		[CocoaDSCheatManager setMasterCheatList:newCheatList];
		[cheatListController setContent:[newCheatList list]];
		[self setCdsCheats:newCheatList];
		[cheatWindowBindings setValue:newCheatList forKey:@"cheatList"];
		
		NSString *filePath = [[NSUserDefaults standardUserDefaults] stringForKey:@"R4Cheat_DatabasePath"];
		if (filePath != nil)
		{
			NSURL *fileURL = [NSURL fileURLWithPath:filePath];
			NSInteger error = 0;
			NSMutableArray *dbList = [[self cdsCheats] cheatListFromDatabase:fileURL errorCode:&error];
			if (dbList != nil)
			{
				[cheatDatabaseController setContent:dbList];
				
				NSString *titleString = [[self cdsCheats] dbTitle];
				NSString *dateString = [[self cdsCheats] dbDate];
				
				[cheatWindowBindings setValue:titleString forKey:@"cheatDBTitle"];
				[cheatWindowBindings setValue:dateString forKey:@"cheatDBDate"];
				[cheatWindowBindings setValue:[NSString stringWithFormat:@"%ld", (unsigned long)[dbList count]] forKey:@"cheatDBItemCount"];
			}
			else
			{
				[cheatWindowBindings setValue:@"---" forKey:@"cheatDBItemCount"];
				
				switch (error)
				{
					case CHEATEXPORT_ERROR_FILE_NOT_FOUND:
						NSLog(@"R4 Cheat Database read failed! Could not load the database file!");
						[cheatWindowBindings setValue:@"Database not loaded." forKey:@"cheatDBTitle"];
						[cheatWindowBindings setValue:@"CANNOT LOAD FILE" forKey:@"cheatDBDate"];
						break;
						
					case CHEATEXPORT_ERROR_WRONG_FILE_FORMAT:
						NSLog(@"R4 Cheat Database read failed! Wrong file format!");
						[cheatWindowBindings setValue:@"Database load error." forKey:@"cheatDBTitle"];
						[cheatWindowBindings setValue:@"FAILED TO LOAD FILE" forKey:@"cheatDBDate"];
						break;
						
					case CHEATEXPORT_ERROR_SERIAL_NOT_FOUND:
						NSLog(@"R4 Cheat Database read failed! Could not find the serial number for this game in the database!");
						[cheatWindowBindings setValue:@"ROM not found in database." forKey:@"cheatDBTitle"];
						[cheatWindowBindings setValue:@"ROM not found." forKey:@"cheatDBDate"];
						break;
						
					case CHEATEXPORT_ERROR_EXPORT_FAILED:
						NSLog(@"R4 Cheat Database read failed! Could not read the database file!");
						[cheatWindowBindings setValue:@"Database read error." forKey:@"cheatDBTitle"];
						[cheatWindowBindings setValue:@"CANNOT READ FILE" forKey:@"cheatDBDate"];
						break;
						
					default:
						break;
				}
			}
		}
		
		[cheatWindowDelegate setCdsCheats:newCheatList];
		[[cheatWindowDelegate cdsCheatSearch] setRwlockCoreExecute:[cdsCore rwlockCoreExecute]];
		[cheatWindowDelegate setCheatSearchViewByStyle:CHEATSEARCH_SEARCHSTYLE_EXACT_VALUE];
	}
	
	// Add the last loaded ROM to the Recent ROMs list.
	[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[theRom fileURL]];
	
	// Update the UI to indicate that a ROM has indeed been loaded.
	[self updateAllWindowTitles];
	
	for (DisplayWindowController *windowController in windowList)
	{
		[CocoaDSUtil messageSendOneWay:[[[windowController view] cdsVideoOutput] receivePort] msgID:MESSAGE_RELOAD_REPROCESS_REDRAW];
	}
	
	[self setStatusText:NSSTRING_STATUS_ROM_LOADED];
	[self setIsWorking:NO];
	[self setIsRomLoading:NO];
	
	Slot2WindowDelegate *slot2WindowDelegate = (Slot2WindowDelegate *)[slot2WindowController content];
	[slot2WindowDelegate setAutoSelectedDeviceText:[[slot2WindowDelegate deviceManager] autoSelectedDeviceName]];
	[[slot2WindowDelegate deviceManager] updateStatus];
		
	for (DisplayWindowController *windowController in windowList)
	{
		[[windowController window] displayIfNeeded];
	}
	
	// After the ROM loading is complete, send an execute message to the Cocoa DS per
	// user preferences.
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"General_ExecuteROMOnLoad"])
	{
		[self executeCore];
	}
}

- (BOOL) unloadRom
{
	BOOL result = NO;
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[self setCurrentSaveStateURL:nil];
	
	isSaveStateEdited = NO;
	for (DisplayWindowController *windowController in windowList)
	{
		[[windowController window] setDocumentEdited:isSaveStateEdited];
	}
	
	// Save the ROM's cheat list before unloading.
	[[self cdsCheats] save];
	
	// Update the UI to indicate that the ROM has started the process of unloading.
	[self setStatusText:NSSTRING_STATUS_ROM_UNLOADING];
	[romInfoPanelController setContent:[CocoaDSRom romNotLoadedBindings]];
	[cheatListController setContent:nil];
	[cheatWindowDelegate resetSearch:nil];
	[cheatWindowDelegate setCdsCheats:nil];
	[cheatDatabaseController setContent:nil];
	
	NSMutableDictionary *cheatWindowBindings = (NSMutableDictionary *)[cheatWindowController content];
	[cheatWindowBindings setValue:@"No ROM loaded." forKey:@"cheatDBTitle"];
	[cheatWindowBindings setValue:@"No ROM loaded." forKey:@"cheatDBDate"];
	[cheatWindowBindings setValue:@"---" forKey:@"cheatDBItemCount"];
	[cheatWindowBindings setValue:nil forKey:@"cheatList"];
	
	[self setIsWorking:YES];
	
	for (DisplayWindowController *windowController in windowList)
	{
		[[windowController window] displayIfNeeded];
	}
	
	// Unload the ROM.
	[[self currentRom] release];
	[self setCurrentRom:nil];
	
	// Release the current cheat list and assign the empty list.
	[self setCdsCheats:nil];
	if (dummyCheatList == nil)
	{
		dummyCheatList = [[CocoaDSCheatManager alloc] init];
	}
	[CocoaDSCheatManager setMasterCheatList:dummyCheatList];
	
	// Update the UI to indicate that the ROM has finished unloading.
	[self updateAllWindowTitles];
	
	[[cdsCore cdsGPU] clearWithColor:0x8000];
	for (DisplayWindowController *windowController in windowList)
	{
		[CocoaDSUtil messageSendOneWay:[[[windowController view] cdsVideoOutput] receivePort] msgID:MESSAGE_RELOAD_REPROCESS_REDRAW];
	}
	
	[self setStatusText:NSSTRING_STATUS_ROM_UNLOADED];
	[self setIsWorking:NO];
	
	Slot2WindowDelegate *slot2WindowDelegate = (Slot2WindowDelegate *)[slot2WindowController content];
	[slot2WindowDelegate setAutoSelectedDeviceText:[[slot2WindowDelegate deviceManager] autoSelectedDeviceName]];
	[[slot2WindowDelegate deviceManager] updateStatus];
	
	for (DisplayWindowController *windowController in windowList)
	{
		[[windowController window] displayIfNeeded];
	}
	
	[cdsCore setSlot1StatusText:NSSTRING_STATUS_EMULATION_NOT_RUNNING];
	[[cdsCore cdsController] reset];
	[[cdsCore cdsController] updateMicLevel];
	
	result = YES;
	
	return result;
}

- (void) addOutputToCore:(CocoaDSOutput *)theOutput
{
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[cdsCore addOutput:theOutput];
}

- (void) removeOutputFromCore:(CocoaDSOutput *)theOutput
{
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[cdsCore removeOutput:theOutput];
}

- (void) changeCoreSpeedWithDouble:(double)newSpeedScalar
{
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[cdsCore setSpeedScalar:newSpeedScalar];
	lastSetSpeedScalar = newSpeedScalar;
}

- (void) executeCore
{
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[cdsCore setCoreState:ExecutionBehavior_Run];
	[self updateMicStatusIcon];
}

- (void) pauseCore
{
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[cdsCore setCoreState:ExecutionBehavior_Pause];
	[self updateMicStatusIcon];
}

- (void) restoreCoreState
{
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[cdsCore restoreCoreState];
	[self updateMicStatusIcon];
}

- (void) updateMicStatusIcon
{
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	CocoaDSController *cdsController = [cdsCore cdsController];
	NSImage *micIcon = iconMicDisabled;
	
	if ([cdsController softwareMicState])
	{
		micIcon = iconMicManualOverride;
	}
	else
	{
		if ([cdsController isHardwareMicAvailable])
		{
			if ([cdsController isHardwareMicInClip])
			{
				micIcon = iconMicInClip;
			}
			else if ([cdsController isHardwareMicIdle])
			{
				micIcon = iconMicIdle;
			}
			else
			{
				micIcon = iconMicActive;
			}
		}
	}
	
	if (micIcon != [self currentMicStatusIcon])
	{
		[self performSelectorOnMainThread:@selector(setCurrentMicStatusIcon:) withObject:micIcon waitUntilDone:NO];
	}
}

- (AudioSampleBlockGenerator *) selectedAudioFileGenerator
{
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	return [[cdsCore cdsController] selectedAudioFileGenerator];
}

- (void) setSelectedAudioFileGenerator:(AudioSampleBlockGenerator *)theGenerator
{
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[[cdsCore cdsController] setSelectedAudioFileGenerator:theGenerator];
}

- (void) didEndFileMigrationSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSURL *romURL = (NSURL *)contextInfo;
	NSURL *romSaveURL = [CocoaDSFile romSaveURLFromRomURL:romURL];
	
    [sheet orderOut:self];	
	
	switch (returnCode)
	{
		case NSOKButton:
			[CocoaDSFile moveFileToCurrentDirectory:romSaveURL];
			break;
			
		default:
			break;
	}
	
	[self setIsUserInterfaceBlockingExecution:NO];
	[self setIsShowingFileMigrationDialog:NO];
	[self loadRomByURL:romURL asynchronous:YES];
	
	// We retained this when we initially put up the sheet, so we need to release it now.
	[romURL release];
}

- (void) didEndSaveStateSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:self];
	
	switch (returnCode)
	{
		case NSCancelButton: // Cancel
			[self restoreCoreState];
			[self setIsUserInterfaceBlockingExecution:NO];
			[self setIsShowingSaveStateDialog:NO];
			return;
			break;
			
		case COCOA_DIALOG_DEFAULT: // Save
		{
			const BOOL isStateSaved = [CocoaDSFile saveState:[self currentSaveStateURL]];
			if (!isStateSaved)
			{
				// Throw an error here...
				[self setStatusText:NSSTRING_STATUS_SAVESTATE_SAVING_FAILED];
				return;
			}
			break;
		}
			
		case COCOA_DIALOG_OPTION: // Don't Save
			break;
			
		default:
			break;
	}
	
	[self unloadRom];
	[self setIsUserInterfaceBlockingExecution:NO];
	[self setIsShowingSaveStateDialog:NO];
}

- (void) didEndSaveStateSheetOpen:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[self didEndSaveStateSheet:sheet returnCode:returnCode contextInfo:contextInfo];
	
	NSURL *romURL = (NSURL *)contextInfo;
	[self handleLoadRomByURL:romURL];
	[romURL release];
}

- (void) didEndSaveStateSheetTerminate:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[self didEndSaveStateSheet:sheet returnCode:returnCode contextInfo:contextInfo];
	
	if (returnCode == NSCancelButton)
	{
		[NSApp replyToApplicationShouldTerminate:NO];
	}
	else
	{
		if ([self currentSaveStateURL] == nil)
		{
			[NSApp replyToApplicationShouldTerminate:YES];
		}
	}
}

- (void) didEndChooseSlot1R4Directory:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:self];
	
	if (returnCode == NSCancelButton)
	{
		return;
	}
	
	NSURL *selectedDirURL = [[sheet URLs] lastObject]; //hopefully also the first object
	if(selectedDirURL == nil)
	{
		return;
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:[selectedDirURL path] forKey:@"EmulationSlot1_R4StoragePath"];
	
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	[cdsCore setSlot1R4URL:selectedDirURL];
}

- (void) updateAllWindowTitles
{
	if ([windowList count] < 1)
	{
		return;
	}
	
	NSString *romName = nil;
	NSURL *repURL = nil;
	NSImage *titleIcon = nil;
	
	if ([self currentRom] == nil)
	{
		romName = (NSString *)[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
	}
	else
	{
		romName = [currentRom internalName];
		repURL = [currentRom fileURL];
		titleIcon = [currentRom icon];
	}
	
	if ([windowList count] > 1)
	{
		for (DisplayWindowController *windowController in windowList)
		{
			NSString *newWindowTitle = [romName stringByAppendingFormat:@":%ld", (unsigned long)([windowList indexOfObject:windowController] + 1)];
			
			[[windowController masterWindow] setTitle:newWindowTitle];
			[[windowController masterWindow] setRepresentedURL:repURL];
			[[[windowController masterWindow] standardWindowButton:NSWindowDocumentIconButton] setImage:titleIcon];
		}
	}
	else
	{
		NSWindow *theWindow = [[windowList objectAtIndex:0] masterWindow];
		[theWindow setTitle:romName];
		[theWindow setRepresentedURL:repURL];
		[[theWindow standardWindowButton:NSWindowDocumentIconButton] setImage:titleIcon];
	}
}

- (void) updateDisplayPanelTitles
{
	// If the original panel titles haven't been saved yet, then save them now.
	if (displayRotationPanelTitle == nil)
	{
		displayRotationPanelTitle = [[displayRotationPanel title] copy];
		displaySeparationPanelTitle = [[displaySeparationPanel title] copy];
		displayVideoSettingsPanelTitle = [[displayVideoSettingsPanel title] copy];
	}
	
	// Set the panel titles to the window number.
	if ([windowList count] <= 1)
	{
		[displayRotationPanel setTitle:displayRotationPanelTitle];
		[displaySeparationPanel setTitle:displaySeparationPanelTitle];
		[displayVideoSettingsPanel setTitle:displayVideoSettingsPanelTitle];
	}
	else
	{
		unsigned long windowNumber = (unsigned long)[windowList indexOfObject:mainWindow] + 1;
		[displayRotationPanel setTitle:[displayRotationPanelTitle stringByAppendingFormat:@":%ld", windowNumber]];
		[displaySeparationPanel setTitle:[displaySeparationPanelTitle stringByAppendingFormat:@":%ld", windowNumber]];
		[displayVideoSettingsPanel setTitle:[displayVideoSettingsPanelTitle stringByAppendingFormat:@":%ld", windowNumber]];
	}
}

- (void) setupUserDefaults
{
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	
	// Set the microphone settings per user preferences.
	[[cdsCore cdsController] setHardwareMicMute:[[NSUserDefaults standardUserDefaults] boolForKey:@"Microphone_HardwareMicMute"]];
	
	// Set the SPU settings per user preferences.
	[self setCurrentVolumeValue:[[NSUserDefaults standardUserDefaults] floatForKey:@"Sound_Volume"]];
	[[self cdsSpeaker] setVolume:[[NSUserDefaults standardUserDefaults] floatForKey:@"Sound_Volume"]];
	[[self cdsSpeaker] setAudioOutputEngine:[[NSUserDefaults standardUserDefaults] integerForKey:@"Sound_AudioOutputEngine"]];
	[[self cdsSpeaker] setSpuAdvancedLogic:[[NSUserDefaults standardUserDefaults] boolForKey:@"SPU_AdvancedLogic"]];
	[[self cdsSpeaker] setSpuInterpolationMode:[[NSUserDefaults standardUserDefaults] integerForKey:@"SPU_InterpolationMode"]];
	[[self cdsSpeaker] setSpuSyncMode:[[NSUserDefaults standardUserDefaults] integerForKey:@"SPU_SyncMode"]];
	[[self cdsSpeaker] setSpuSyncMethod:[[NSUserDefaults standardUserDefaults] integerForKey:@"SPU_SyncMethod"]];
	
	// Set the 3D rendering options per user preferences.
	[[cdsCore cdsGPU] setRender3DThreads:(NSUInteger)[[NSUserDefaults standardUserDefaults] integerForKey:@"Render3D_Threads"]];
	[[cdsCore cdsGPU] setRender3DRenderingEngine:[[NSUserDefaults standardUserDefaults] integerForKey:@"Render3D_RenderingEngine"]];
	[[cdsCore cdsGPU] setRender3DHighPrecisionColorInterpolation:[[NSUserDefaults standardUserDefaults] boolForKey:@"Render3D_HighPrecisionColorInterpolation"]];
	[[cdsCore cdsGPU] setRender3DEdgeMarking:[[NSUserDefaults standardUserDefaults] boolForKey:@"Render3D_EdgeMarking"]];
	[[cdsCore cdsGPU] setRender3DFog:[[NSUserDefaults standardUserDefaults] boolForKey:@"Render3D_Fog"]];
	[[cdsCore cdsGPU] setRender3DTextures:[[NSUserDefaults standardUserDefaults] boolForKey:@"Render3D_Textures"]];
	[[cdsCore cdsGPU] setRender3DLineHack:[[NSUserDefaults standardUserDefaults] boolForKey:@"Render3D_LineHack"]];
	[[cdsCore cdsGPU] setRender3DMultisample:[[NSUserDefaults standardUserDefaults] boolForKey:@"Render3D_Multisample"]];
	[[cdsCore cdsGPU] setRender3DTextureScalingFactor:(NSUInteger)[[NSUserDefaults standardUserDefaults] integerForKey:@"Render3D_TextureScalingFactor"]];
	[[cdsCore cdsGPU] setRender3DTextureDeposterize:[[NSUserDefaults standardUserDefaults] boolForKey:@"Render3D_TextureDeposterize"]];
	[[cdsCore cdsGPU] setRender3DTextureSmoothing:[[NSUserDefaults standardUserDefaults] boolForKey:@"Render3D_TextureSmoothing"]];
	[[cdsCore cdsGPU] setRender3DFragmentSamplingHack:[[NSUserDefaults standardUserDefaults] boolForKey:@"Render3D_FragmentSamplingHack"]];
	[[cdsCore cdsGPU] setGpuScale:(NSUInteger)[[NSUserDefaults standardUserDefaults] integerForKey:@"Render3D_ScalingFactor"]];
	[[cdsCore cdsGPU] setGpuColorFormat:(NSUInteger)[[NSUserDefaults standardUserDefaults] integerForKey:@"Render3D_ColorFormat"]];
	
	// Set the stylus options per user preferences.
	[[cdsCore cdsController] setStylusPressure:[[NSUserDefaults standardUserDefaults] integerForKey:@"Emulation_StylusPressure"]];
}

#pragma mark NSUserInterfaceValidations Protocol

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)theItem
{
	BOOL enable = YES;
    const SEL theAction = [theItem action];
	CocoaDSCore *cdsCore = (CocoaDSCore *)[cdsCoreController content];
	
	if (theAction == @selector(importRomSave:) ||
		theAction == @selector(exportRomSave:))
    {
		if ([self currentRom] == nil)
		{
			enable = NO;
		}
    }
    else if (theAction == @selector(toggleExecutePause:))
    {
		if (![cdsCore masterExecute] ||
			[self currentRom] == nil ||
			[self isUserInterfaceBlockingExecution])
		{
			enable = NO;
		}
		
		if ([(id)theItem isMemberOfClass:[NSMenuItem class]])
		{
			if ([cdsCore coreState] == ExecutionBehavior_Pause)
			{
				[(NSMenuItem*)theItem setTitle:NSSTRING_TITLE_EXECUTE_CONTROL];
			}
			else if ([cdsCore coreState] == ExecutionBehavior_Run)
			{
				[(NSMenuItem*)theItem setTitle:NSSTRING_TITLE_PAUSE_CONTROL];
			}
		}
		else if ([(id)theItem isMemberOfClass:[NSToolbarItem class]])
		{
			if ([cdsCore coreState] == ExecutionBehavior_Pause)
			{
				[(NSToolbarItem*)theItem setLabel:NSSTRING_TITLE_EXECUTE_CONTROL];
				[(NSToolbarItem*)theItem setImage:iconExecute];
			}
			else if ([cdsCore coreState] == ExecutionBehavior_Run)
			{
				[(NSToolbarItem*)theItem setLabel:NSSTRING_TITLE_PAUSE_CONTROL];
				[(NSToolbarItem*)theItem setImage:iconPause];
			}
		}
    }
	else if (theAction == @selector(frameAdvance:))
	{
		if ([cdsCore coreState] != ExecutionBehavior_Pause ||
			![cdsCore masterExecute] ||
			[self currentRom] == nil ||
			[self isShowingSaveStateDialog])
		{
			enable = NO;
		}
	}
	else if (theAction == @selector(frameJump:))
	{
		if (![cdsCore masterExecute] ||
			[self currentRom] == nil ||
			[self isShowingSaveStateDialog])
		{
			enable = NO;
		}
	}
	else if (theAction == @selector(coreExecute:))
    {
		if ([cdsCore coreState] == ExecutionBehavior_Run ||
			[cdsCore coreState] == ExecutionBehavior_FrameAdvance ||
			![cdsCore masterExecute] ||
			[self currentRom] == nil ||
			[self isShowingSaveStateDialog])
		{
			enable = NO;
		}
    }
	else if (theAction == @selector(corePause:))
    {
		if ([cdsCore coreState] == ExecutionBehavior_Pause ||
			![cdsCore masterExecute] ||
			[self currentRom] == nil ||
			[self isShowingSaveStateDialog])
		{
			enable = NO;
		}
    }
	else if (theAction == @selector(reset:))
	{
		if ([self currentRom] == nil || [self isUserInterfaceBlockingExecution] || [cdsCore isInDebugTrap])
		{
			enable = NO;
		}
	}
	else if (theAction == @selector(loadRecentRom:))
	{
		if ([self isRomLoading] || [self isShowingSaveStateDialog] || [cdsCore isInDebugTrap])
		{
			enable = NO;
		}
	}
	else if (theAction == @selector(openRom:))
	{
		if ([self isRomLoading] || [self isShowingSaveStateDialog] || [cdsCore isInDebugTrap])
		{
			enable = NO;
		}
	}
	else if (theAction == @selector(closeRom:))
	{
		if ([self currentRom] == nil || [self isRomLoading] || [self isShowingSaveStateDialog] || [cdsCore isInDebugTrap])
		{
			enable = NO;
		}
	}
	else if (theAction == @selector(revealRomInFinder:))
	{
		if ([self currentRom] == nil || [self isRomLoading])
		{
			enable = NO;
		}
	}
	else if (theAction == @selector(loadEmuSaveStateSlot:))
	{
		if ([self currentRom] == nil ||
			[self isShowingSaveStateDialog] ||
			![CocoaDSFile saveStateExistsForSlot:[[self currentRom] fileURL] slotNumber:[theItem tag] + 1] ||
			[cdsCore isInDebugTrap])
		{
			enable = NO;
		}
	}
	else if (theAction == @selector(saveEmuSaveStateSlot:))
	{
		if ([self currentRom] == nil || [self isShowingSaveStateDialog])
		{
			enable = NO;
		}
		
		if ([(id)theItem isMemberOfClass:[NSMenuItem class]])
		{
			if ([CocoaDSFile saveStateExistsForSlot:[[self currentRom] fileURL] slotNumber:[theItem tag] + 1])
			{
				[(NSMenuItem*)theItem setState:NSOnState];
			}
			else
			{
				[(NSMenuItem*)theItem setState:NSOffState];
			}
		}
	}
	else if (theAction == @selector(openReplay:))
	{
		if ([self currentRom] == nil || [self isRomLoading] || [self isShowingSaveStateDialog])
		{
			enable = NO;
		}
	}
	else if (theAction == @selector(recordReplay:))
	{
		if ([self currentRom] == nil || [self isRomLoading] || [self isShowingSaveStateDialog])
		{
			enable = NO;
		}
	}
	else if (theAction == @selector(stopReplay:))
	{
		if ([self currentRom] == nil || [self isRomLoading] || [self isShowingSaveStateDialog])
		{
			enable = NO;
		}
	}
	else if (theAction == @selector(changeCoreSpeed:))
	{
		NSInteger speedScalar = (NSInteger)([cdsCore speedScalar] * 100.0);
		
		if ([(id)theItem isMemberOfClass:[NSMenuItem class]])
		{
			if ([theItem tag] == -1)
			{
				if (speedScalar == (NSInteger)(SPEED_SCALAR_HALF * 100.0) ||
					speedScalar == (NSInteger)(SPEED_SCALAR_NORMAL * 100.0) ||
					speedScalar == (NSInteger)(SPEED_SCALAR_DOUBLE * 100.0))
				{
					[(NSMenuItem*)theItem setState:NSOffState];
				}
				else
				{
					[(NSMenuItem*)theItem setState:NSOnState];
				}
			}
			else
			{
				[(NSMenuItem*)theItem setState:(speedScalar == [theItem tag]) ? NSOnState : NSOffState];
			}
		}
		else if ([(id)theItem isMemberOfClass:[NSToolbarItem class]])
		{
			if (speedScalar == (NSInteger)(SPEED_SCALAR_DOUBLE * 100.0))
			{
				[(NSToolbarItem*)theItem setLabel:NSSTRING_TITLE_SPEED_1X];
				[(NSToolbarItem*)theItem setTag:100];
				[(NSToolbarItem*)theItem setImage:iconSpeedNormal];
			}
			else
			{
				[(NSToolbarItem*)theItem setLabel:NSSTRING_TITLE_SPEED_2X];
				[(NSToolbarItem*)theItem setTag:200];
				[(NSToolbarItem*)theItem setImage:iconSpeedDouble];
			}
		}
	}
	else if (theAction == @selector(toggleSpeedLimiter:))
	{
		if ([(id)theItem isMemberOfClass:[NSMenuItem class]])
		{
			[(NSMenuItem*)theItem setTitle:([cdsCore isSpeedLimitEnabled]) ? NSSTRING_TITLE_DISABLE_SPEED_LIMIT : NSSTRING_TITLE_ENABLE_SPEED_LIMIT];
		}
	}
	else if (theAction == @selector(toggleAutoFrameSkip:))
	{
		if ([(id)theItem isMemberOfClass:[NSMenuItem class]])
		{
			[(NSMenuItem*)theItem setTitle:([cdsCore isFrameSkipEnabled]) ? NSSTRING_TITLE_DISABLE_AUTO_FRAME_SKIP : NSSTRING_TITLE_ENABLE_AUTO_FRAME_SKIP];
		}
	}
	else if (theAction == @selector(toggleCheats:))
	{
		if ([(id)theItem isMemberOfClass:[NSMenuItem class]])
		{
			[(NSMenuItem*)theItem setTitle:([cdsCore isCheatingEnabled]) ? NSSTRING_TITLE_DISABLE_CHEATS : NSSTRING_TITLE_ENABLE_CHEATS];
		}
	}
	else if (theAction == @selector(changeRomSaveType:))
	{
		if ([(id)theItem isMemberOfClass:[NSMenuItem class]])
		{
			[(NSMenuItem*)theItem setState:([self selectedRomSaveTypeID] == [theItem tag]) ? NSOnState : NSOffState];
		}
	}
	else if (theAction == @selector(openEmuSaveState:) ||
			 theAction == @selector(saveEmuSaveState:) ||
			 theAction == @selector(saveEmuSaveStateAs:))
	{
		if ([self currentRom] == nil || [self isShowingSaveStateDialog] || [cdsCore isInDebugTrap])
		{
			enable = NO;
		}
	}
	else if (theAction == @selector(revertEmuSaveState:))
	{
		if ([self currentRom] == nil ||
			[self isShowingSaveStateDialog] ||
			[self currentSaveStateURL] == nil ||
			[cdsCore isInDebugTrap])
		{
			enable = NO;
		}
	}
	else if (theAction == @selector(toggleGPUState:))
	{
		if ([(id)theItem isMemberOfClass:[NSMenuItem class]])
		{
			[(NSMenuItem*)theItem setState:([cdsCore.cdsGPU gpuStateByBit:[theItem tag]]) ? NSOnState : NSOffState];
		}
	}
	
	return enable;
}

#pragma mark CocoaDSControllerDelegate Protocol

- (void) doMicLevelUpdateFromController:(CocoaDSController *)cdsController
{
	[self updateMicStatusIcon];
}

- (void) doMicHardwareStateChangedFromController:(CocoaDSController *)cdsController
									   isEnabled:(BOOL)isHardwareEnabled
										isLocked:(BOOL)isHardwareLocked
{
	const BOOL hwMicAvailable = (isHardwareEnabled && !isHardwareLocked);
	[self setIsHardwareMicAvailable:hwMicAvailable];
	[self updateMicStatusIcon];
}

- (void) doMicHardwareGainChangedFromController:(CocoaDSController *)cdsController gain:(float)gainValue
{
	[self setCurrentMicGainValue:gainValue*100.0f];
}

@end
