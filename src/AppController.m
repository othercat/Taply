
#import "AppController.h"
#include <stdlib.h>

@implementation AppController

-(void)awakeFromNib {

	playing = NO;
	
	playlist = [[TaplyPlaylist alloc] init];
	[NSApp setDelegate:self];

	currentIndex = 0;

	// Set buttons' tags
	[buttonPrevious setTag:CTRL_BTNPREV_TAG];
	[buttonNext setTag:CTRL_BTNNEXT_TAG];

	// Set contexual menu
	[[window contentView] setMenu:cMenu];
	[[filename cell] setMenu:cMenu];

	// Register for Drag&Drop
	[window setDelegate:self];
	[window registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];

    [prefsRememberVolume setTitle:STR_REMBR_VOL];
    [prefsRandomOrder setTitle:STR_RANDOM];
    
	timer = [Timer new];

    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:@"rememberVolume"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"rememberVolume"];
    }

    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:@"shuffle"]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"shuffle"];
    }

    if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:@"volume"] ||
        ![[NSUserDefaults standardUserDefaults] boolForKey:@"rememberVolume"]
    ) {
        [[NSUserDefaults standardUserDefaults] setFloat:1.0 forKey:@"volume"];
    }
}

-(BOOL)canOpenFile:(NSString *)path {

	NSArray *docTypes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDocumentTypes"];
	NSMutableArray *acceptedExtensions = [[[NSMutableArray alloc] initWithCapacity:32] autorelease];
	NSMutableArray *acceptedHFSTypes = [[[NSMutableArray alloc] initWithCapacity:32] autorelease];
	unsigned int i;
	
	// Get an array of all extensions and an array of all
	// HFS types this application claims to be able to open
	for (i = 0; i < [docTypes count]; i ++) {
		NSArray *typeExtensions = [[docTypes objectAtIndex:i] objectForKey:@"CFBundleTypeExtensions"];
		NSArray *typeHFSTypes = [[docTypes objectAtIndex:i] objectForKey:@"CFBundleTypeOSTypes"];
		[acceptedExtensions addObjectsFromArray:typeExtensions];
		[acceptedHFSTypes addObjectsFromArray:typeHFSTypes];
	}

	if ([acceptedExtensions containsObject:[[path pathExtension] lowercaseString]]) {
		// Document can be identified as "openable" by its extension
		return YES;
	}

	NSString *hfstype = NSHFSTypeOfFile(path);
	if ([hfstype isEqualToString:@"''"]) {
		return NO;
	}

	if ([acceptedHFSTypes containsObject:[hfstype substringWithRange:NSMakeRange(1, 4)]]) {
		// Document can be identified as "openable" by its HFSType
		return YES;
	}

	return NO;
}

-(IBAction)decreaseVolume:(id)sender {
	float newVolume = [volumeSlider floatValue] - VOLUME_STEP;
	if (newVolume < 0.0) {
		newVolume = 0.0;
	}
	[player setVolume:newVolume];	
	[volumeSlider setFloatValue: newVolume];	
}

-(IBAction)increaseVolume:(id)sender {
	float newVolume = [volumeSlider floatValue] + VOLUME_STEP;
	if (newVolume > 1.0) {
		newVolume = 1.0;
	}
	[player setVolume:newVolume];	
	[volumeSlider setFloatValue: newVolume];	
}

-(IBAction)setVolume:(id)sender {
	[player setVolume:[sender floatValue]];
}

-(IBAction)restartTrack:(id)sender {
	[self setNewPlayerPosition:[NSNumber numberWithFloat:0]];
}

-(void)setNewPlayerPosition:(NSNumber *)numberOfSeconds {
	[player setPlaybackPosition:[numberOfSeconds floatValue]];
	[positionBar setPosition:numberOfSeconds];
	[timer setElapsedTime:numberOfSeconds];
	if (!playing) {
		[self playOrResume:self];
		[buttonPlay setState:NSOffState];
	}
}

-(void)startPlay {

	QTSoundFilePlayer *qtPlayer;
	
	if (currentIndex >= [playlist count]) {
		// Nothing more to play >> Quit
		[NSApp terminate:self];
	}

	qtPlayer = [[QTSoundFilePlayer alloc] initWithContentsOfFile:[playlist soundAtIndex:currentIndex]];
	[qtPlayer setDelegate:self];
	[qtPlayer setVolume:[volumeSlider floatValue]];
	[qtPlayer play];

	if ([qtPlayer isPlaying]) {
		float duration;
		playing = YES;
		[buttonPlay setState: NSOffState];

		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[playlist soundAtIndex:currentIndex]];
		[icon setSize:NSMakeSize(32, 32)];
		[icon setScalesWhenResized:YES];
		[fileIcon setImage:icon];

		[self setFilename];
		duration = [qtPlayer duration];
		player = qtPlayer;
		[self updateButtons];
		
		// Display the track's length
		[fileLength setStringValue:CBTimeStringForSeconds(duration)];
		
		// Start the timer thread and pass the NSTextField to use as argument
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:elapsedSeconds, @"textfield",
		                                                                 positionBar, @"positionBar",
		                                         [NSNumber numberWithFloat:duration], @"duration",
			                                    [playlist soundAtIndex:currentIndex], @"file",
			                                                                          nil];

		[timer setCurrentFile:[playlist soundAtIndex:currentIndex]];
		[NSThread detachNewThreadSelector:@selector(timerLoop:)
								 toTarget:timer
							   withObject:userInfo];
	} else {
		// Unusable format >> Proceed to next
		playing = NO;
		[buttonPlay setState: NSOnState];
		NSString *_filename = [NSString stringWithString:[[playlist soundAtIndex:currentIndex] lastPathComponent]];
		[qtPlayer release];
		[elapsedSeconds setTitle:@""];
		[playlist remove:currentIndex];
		NSBeginAlertSheet(nil, @"OK", nil, nil, window, self,
		                  @selector(alertDidEnd:returnCode:contextInfo:), nil, nil,
						  STR_ERRORPLAYING, _filename);
	}
}

-(void)setFilename {
	NSString *filenameString = [[playlist soundAtIndex:currentIndex] lastPathComponent];
	[filename setStringValue:filenameString];
	[filename setToolTip:filenameString];
}

-(void)updateButtons {

	unsigned int num = 0;
	unsigned int i;
	NSEnumerator *enumerator = [[cMenu itemArray] objectEnumerator];
	NSMenuItem *menuItem;

	if (currentIndex > 0) {
		[buttonPrevious setToolTip:STR_BTN_PREV];
		[buttonPrevious setEnabled:YES];
	} else {
		[buttonPrevious setEnabled:NO];
		[buttonPrevious setToolTip:@""];
	}
	
	if ((currentIndex + 1)  < [playlist count]) {
		[buttonNext setToolTip:STR_BTN_NEXT];
		[buttonNext setEnabled:YES];
	} else {
		[buttonNext setToolTip:@""];
		[buttonNext setEnabled:NO];
	}

	// Set button tooltips
	[buttonPlay setToolTip:STR_BTN_PAUSE];
	[buttonLoop setToolTip:STR_BTN_REPEAT];
	
    [playlistInfo setStringValue:[NSString stringWithFormat:STR_FILEXOFY, currentIndex + 1, [playlist count]]];

	[playlistInfo sizeToFit];
	[window display];

	// Remove old items from contextual menu
	while (menuItem = [enumerator nextObject]) {
		[cMenu removeItem:menuItem];
	}

	// Add tracks to contextual menu
	for (i = 0; i < [playlist count]; i ++) {
		[cMenu insertItemWithTitle:[[playlist soundAtIndex:i] lastPathComponent]
			   action:@selector(chooseSound:)
			   keyEquivalent:@""
			   atIndex:i];
		[[cMenu itemAtIndex:i] setTag:i];
		num ++;
	}

	if (![playlist count]) {
		// No items in playlist, nothing to do
		[NSApp terminate:self];
	}

	// Make the current file selected
	[[cMenu itemAtIndex:currentIndex] setState:NSOnState];

	// Add separator
	[cMenu insertItem:[NSMenuItem separatorItem] atIndex: num];
	
	[cMenu insertItemWithTitle:STR_OPENPREFS
                        action:@selector(openPrefs:)
                 keyEquivalent:@""
                       atIndex: num + 1];
    
	[cMenu insertItemWithTitle:STR_CLEARPLLIST
                        action:@selector(clearPlaylist:)
                 keyEquivalent:@""
                       atIndex: num + 2];
		  
	[cMenu insertItemWithTitle:STR_QUIT
                        action:@selector(terminate:)
                 keyEquivalent:@""
                       atIndex: num + 3];
}

-(IBAction)revealFile:(id)sender {
	[[NSWorkspace sharedWorkspace] selectFile:[playlist soundAtIndex:currentIndex] inFileViewerRootedAtPath:@""];
}

-(IBAction)openPrefs:(id)sender {
    [NSApp beginSheet:prefsPanel
	   modalForWindow:window
		modalDelegate:self
	   didEndSelector:nil
		  contextInfo:nil];

}

-(IBAction)closePrefs:(id)sender {
    [NSApp endSheet:prefsPanel];
    [prefsPanel orderOut:nil];
}

-(IBAction)clearPlaylist:(id)sender {
	[playlist removeAllExcept:currentIndex];
	currentIndex = 0;
	[self updateButtons];
}

-(void)chooseSound:(id)sender {

	if ([sender tag] == CTRL_BTNPREV_TAG) {
		// Previous file
		currentIndex --;
	}
	else if ([sender tag] == CTRL_BTNNEXT_TAG) {
		// Next file
		currentIndex ++;
	}
	else {
		// Arbitrary file from the playlist
		if ([sender tag] == currentIndex) {
			// Restart current track
			[player setPlaybackPosition:0.0];
			[timer resetTimer];
			return;
		}
		currentIndex = [sender tag];
	}

	[player setDelegate: nil];

	if (playing) {
		playing = NO;
	}

	[timer setCurrentFile:nil];
	[player stop];

	[self startPlay];
}

-(IBAction)playOrResume:(id)sender {
	if (playing) {
		playing = NO;
		[player pause];
		[timer setPaused:YES];
	}
	else {
		playing = YES;
		[player resume];
		[timer setPaused:NO];
	}
}

- (void)windowWillClose:(NSNotification *)aNotification {

	// Stop player
	[player setDelegate: nil];
	[player stop];
	
	// Close the window
	[window fadeOut];

	// Terminate the application
	[NSApp terminate:self];
}

-(BOOL)application:(NSApplication*)sender openFile:(NSString*)path {
	[self handleDraggedPath:[NSArray arrayWithObject:path]];
	[self updateButtons];
	return YES;
}


-(IBAction)showReadMe:(id)sender {
	[[NSWorkspace sharedWorkspace]openFile:[[NSBundle mainBundle] pathForResource:@"Read me" ofType:@"html"]];
}


#pragma mark -
#pragma mark Delegate Methods

- (void)qtSoundFilePlayer:(QTSoundFilePlayer *)qtPlayer
		 didFinishPlaying:(BOOL)success {

	if (success && [buttonLoop state] == NSOnState) {
		// LOOP
		[timer resetTimer];
		[qtPlayer play];		
		return;
	}

	[timer setCurrentFile:nil];
	[filename setStringValue:@""];
	player = nil;

	if (success) {
		// Sound finished completely
        currentIndex ++;
	}

	[self startPlay];
}

-(void)alertDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[self startPlay];
}

-(void)applicationDidFinishLaunching:(id)sender {
	
	[NSApp activateIgnoringOtherApps:YES];
	
	if ([playlist count] == 0) {
		// Nothing to play
		NSOpenPanel *p = [NSOpenPanel openPanel];
		[p setAllowsMultipleSelection:YES];
		[p setCanChooseDirectories:YES];
		[p setCanChooseFiles:YES];
		[p setResolvesAliases:YES];
		[p setTitle:STR_CHOOSESOUNDSTOPLAY];
		if (NSOKButton == [p runModalForTypes:[NSArray arrayWithObjects:FILETYPES, nil]]) {
			[self handleDraggedPath:[p filenames]];
		}
		else {
			[NSApp terminate:self];
		}
	}
	
	[window makeKeyAndOrderFront:self];
	[window setDelegate:self];
	[positionBar setController:self];
	
	[self startPlay];
}


#pragma mark -
#pragma mark Drag&Drop Methods

-(unsigned int) draggingEntered:(id <NSDraggingInfo>)sender {	
	SetThemeCursor(kThemeCopyArrowCursor);
	return NSDragOperationGeneric;
}

-(void)draggingExited:(id <NSDraggingInfo>)sender {	
	SetThemeCursor(kThemeArrowCursor);
}

- (unsigned int) draggingUpdated:(id <NSDraggingInfo>)sender {	
	SetThemeCursor(kThemeCopyArrowCursor);
	return NSDragOperationEvery;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	
	// Get the pasteboard involved in the drag
	NSPasteboard *p = [sender draggingPasteboard];
	
	// Make sure a filename can be extracted and return, if not
	if (![[p types] containsObject:@"NSFilenamesPboardType"]) {
		NSBeep();
		return NO;
	}
	
	// Let Taply decide which of the dropped file(s) can be used
	[self handleDraggedPath:[p propertyListForType:NSFilenamesPboardType]];
	
	// Update buttons and contextual menu
	[self updateButtons];
	
	// Otherwise: OK
	return YES;
}

-(void)handleDraggedPath:(id)object {
	
	unsigned int i, ii;

    NSMutableArray *addableItems = [NSMutableArray arrayWithCapacity:50];
    
	for (i = 0; i < [object count]; i ++) {
		
		// Check whether this is a directory
		BOOL isDir = NO;
		NSArray *subpaths;
		NSFileManager *manager = [NSFileManager defaultManager];
		
		if ([manager fileExistsAtPath:[object objectAtIndex:i] isDirectory:&isDir] && isDir) {
			// This is a directory
			subpaths = [manager subpathsAtPath:[object objectAtIndex:i]];
			
			for (ii = 0; ii < [subpaths count]; ii ++) {
				NSString *subPathItem = [[object objectAtIndex:i]
											stringByAppendingPathComponent:[subpaths objectAtIndex:ii]];
				if ([self canOpenFile:subPathItem]) {
                    [addableItems addObject:subPathItem];
				}
			}
		}
		else {
			// This is a regular file
			if ([self canOpenFile:[object objectAtIndex:i]]) {
                [addableItems addObject:[object objectAtIndex:i]];
			}
		}
	}
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"shuffle"]) {
        // Shuffle the array
        NSUInteger count = [addableItems count];
        if (count > 1) {
            for (NSUInteger i = count - 1; i > 0; --i) {
                NSUInteger randomIndex = (NSUInteger) (arc4random() % count);
                if (i != randomIndex) {
                    [addableItems exchangeObjectAtIndex:i withObjectAtIndex:randomIndex];
                }
            }
        }
    }
    
    [playlist add:addableItems];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	SetThemeCursor(kThemeArrowCursor);	
}

@end
