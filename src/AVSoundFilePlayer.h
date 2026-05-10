
#import <Foundation/Foundation.h>

@class AVSoundFilePlayer;

@protocol AVSoundFilePlayerDelegate <NSObject>
@optional
- (void)avSoundFilePlayer:(AVSoundFilePlayer *)player didFinishPlaying:(BOOL)success;
@end

@interface AVSoundFilePlayer : NSObject

- (id)initWithContentsOfURL:(NSURL *)url;
- (id)initWithContentsOfFile:(NSString *)path;

- (BOOL)play;
- (BOOL)pause;
- (BOOL)resume;
- (BOOL)stop;

- (BOOL)isPlaying;
- (BOOL)isPaused;

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

- (float)volume;
- (void)setVolume:(float)value;

- (BOOL)shouldLoop;
- (void)setShouldLoop:(BOOL)value;

- (float)duration;
- (float)playbackPosition;
- (void)setPlaybackPosition:(float)value;

@end
