
#import <Cocoa/Cocoa.h>
#import "TaplyWindow.h"
#import "TaplyPlaylist.h"
#import "AVSoundFilePlayer.h"
#import "TaplyPositionBar.h"
#import "functions.h"

@interface AppController : NSObject {
    IBOutlet id buttonPlay;
    IBOutlet id buttonPrevious;
    IBOutlet id buttonNext;
    IBOutlet id buttonLoop;
    IBOutlet id filename;
    IBOutlet id elapsedSeconds;
    IBOutlet id fileLength;
    IBOutlet id playlistInfo;
    IBOutlet NSPanel *prefsPanel;
    IBOutlet id window;
    IBOutlet id fileIcon;
	IBOutlet TaplyPositionBar *positionBar;
	IBOutlet id volumeSlider;
    IBOutlet NSMenu *cMenu;
    IBOutlet NSButton *prefsRememberVolume;
    IBOutlet NSButton *prefsRandomOrder;
	AVSoundFilePlayer *player;
	unsigned int currentIndex;
	TaplyPlaylist *playlist;
	NSTimer *uiTimer;
	BOOL playing;
}

#pragma mark Instance methods

-(void)awakeFromNib;
-(BOOL)canOpenFile:(NSString *)path;
-(IBAction)clearPlaylist:(id)sender;
-(void)chooseSound:(id)sender;
-(IBAction)playOrResume:(id)sender;
-(void)avSoundFilePlayer:(AVSoundFilePlayer *)avPlayer didFinishPlaying:(BOOL)success;
-(IBAction)revealFile:(id)sender;
-(void)setNewPlayerPosition:(NSNumber *)numberOfSeconds;
-(IBAction)setVolume:(id)sender;
-(IBAction)showReadMe:(id)sender;
-(void)startPlay;
-(void)setFilename;
-(void)updateButtons;
-(IBAction)openPrefs:(id)sender;
-(IBAction)closePrefs:(id)sender;
-(IBAction)restartTrack:(id)sender;
-(IBAction)decreaseVolume:(id)sender;
-(IBAction)increaseVolume:(id)sender;
-(void)startUITimer;
-(void)stopUITimer;
-(void)updatePlaybackUI:(NSTimer *)theTimer;

#pragma mark D&D methods
-(void)handleDraggedPath:(id)pathsArray;


@end
