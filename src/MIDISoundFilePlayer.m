
#import "MIDISoundFilePlayer.h"
#import <AVFoundation/AVFoundation.h>

@implementation MIDISoundFilePlayer {
    AVMIDIPlayer *midiPlayer;
    id nonretainedDelegate;
    BOOL looping;
    BOOL paused;
    BOOL playing;
    NSURL *fileURL;
    NSURL *bankURL;
}

- (id)initWithContentsOfFile:(NSString *)path soundBankURL:(NSURL *)soundBankURL {
    self = [super init];
    if (self) {
        fileURL = [[NSURL fileURLWithPath:path] retain];
        bankURL = [soundBankURL retain];
        midiPlayer = nil;
        nonretainedDelegate = nil;
        looping = NO;
        paused = NO;
        playing = NO;

        NSError *error = nil;
        midiPlayer = [[AVMIDIPlayer alloc] initWithContentsOfURL:fileURL
                                                   soundBankURL:bankURL
                                                          error:&error];
        if (error) {
            NSLog(@"MIDISoundFilePlayer: failed to init with %@: %@", path, error);
            [midiPlayer release];
            midiPlayer = nil;
            [self release];
            return nil;
        }
        [midiPlayer prepareToPlay];
    }
    return self;
}

- (void)notifyDelegate:(BOOL)success {
    if (nonretainedDelegate && [nonretainedDelegate respondsToSelector:@selector(midiSoundFilePlayer:didFinishPlaying:)]) {
        [nonretainedDelegate midiSoundFilePlayer:self didFinishPlaying:success];
    }
}

- (BOOL)play {
    if (!midiPlayer) return NO;
    playing = YES;
    paused = NO;
    __block typeof(self) weakSelf = self;
    [midiPlayer play:^(void) {
        // Completion handler runs on arbitrary thread — dispatch to main
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf) {
                weakSelf->playing = NO;
                [weakSelf notifyDelegate:YES];
            }
        });
    }];
    return YES;
}

- (BOOL)pause {
    if (!midiPlayer) return NO;
    // AVMIDIPlayer has no native pause. Stop and remember position.
    // play will resume from currentPosition.
    paused = YES;
    playing = NO;
    [midiPlayer stop];
    return YES;
}

- (BOOL)resume {
    if (!midiPlayer) return NO;
    if (paused) {
        paused = NO;
        // Resume from current position (stop didn't reset it)
        return [self play];
    }
    return [self play];
}

- (BOOL)stop {
    if (!midiPlayer) return NO;
    [midiPlayer stop];
    midiPlayer.currentPosition = 0.0;
    playing = NO;
    paused = NO;
    return YES;
}

- (BOOL)isPlaying {
    return playing;
}

- (BOOL)isPaused {
    return paused;
}

- (id)delegate {
    return nonretainedDelegate;
}

- (void)setDelegate:(id)aDelegate {
    nonretainedDelegate = aDelegate;
}

- (float)duration {
    if (!midiPlayer) return 0.0;
    return (float)[midiPlayer duration];
}

- (float)playbackPosition {
    if (!midiPlayer) return 0.0;
    return (float)[midiPlayer currentPosition];
}

- (void)setPlaybackPosition:(float)value {
    if (!midiPlayer) return;
    midiPlayer.currentPosition = (NSTimeInterval)value;
}

- (BOOL)shouldLoop {
    return looping;
}

- (void)setShouldLoop:(BOOL)value {
    looping = value;
    // AVMIDIPlayer does not natively support loop.
    // Looping is handled by the delegate: AppController checks loop state
    // in didFinishPlaying and calls play again.
}

- (void)dealloc {
    [midiPlayer stop];
    [midiPlayer release];
    [fileURL release];
    [bankURL release];
    [super dealloc];
}

@end
