
#import <Foundation/Foundation.h>

@class MIDISoundFilePlayer;

@protocol MIDISoundFilePlayerDelegate <NSObject>
@optional
- (void)midiSoundFilePlayer:(MIDISoundFilePlayer *)player didFinishPlaying:(BOOL)success;
@end

@interface MIDISoundFilePlayer : NSObject

- (id)initWithContentsOfFile:(NSString *)path soundBankURL:(NSURL *)soundBankURL;

- (BOOL)play;
- (BOOL)pause;
- (BOOL)resume;
- (BOOL)stop;

- (BOOL)isPlaying;
- (BOOL)isPaused;

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

- (float)duration;
- (float)playbackPosition;
- (void)setPlaybackPosition:(float)value;

- (BOOL)shouldLoop;
- (void)setShouldLoop:(BOOL)value;

@end
