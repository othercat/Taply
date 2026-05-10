
#import "AVSoundFilePlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface AVSoundFilePlayer () <AVAudioPlayerDelegate>
@end

@implementation AVSoundFilePlayer {
    AVAudioPlayer *audioPlayer;
    id nonretainedDelegate;
    BOOL looping;
}

- (id)initWithContentsOfURL:(NSURL *)url {
    self = [super init];
    if (self) {
        NSError *error = nil;
        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        if (error) {
            NSLog(@"AVSoundFilePlayer: failed to init with URL %@: %@", url, error);
            [self release];
            return nil;
        }
        audioPlayer.delegate = self;
        looping = NO;
    }
    return self;
}

- (id)initWithContentsOfFile:(NSString *)path {
    return [self initWithContentsOfURL:[NSURL fileURLWithPath:path]];
}

- (BOOL)play {
    if (!audioPlayer) return NO;
    return [audioPlayer play];
}

- (BOOL)pause {
    if (!audioPlayer) return NO;
    [audioPlayer pause];
    return YES;
}

- (BOOL)resume {
    if (!audioPlayer) return NO;
    return [audioPlayer play];
}

- (BOOL)stop {
    if (!audioPlayer) return NO;
    [audioPlayer stop];
    audioPlayer.currentTime = 0.0;
    return YES;
}

- (BOOL)isPlaying {
    if (!audioPlayer) return NO;
    return [audioPlayer isPlaying];
}

- (BOOL)isPaused {
    if (!audioPlayer) return NO;
    return ![audioPlayer isPlaying] && audioPlayer.currentTime > 0.0;
}

- (id)delegate {
    return nonretainedDelegate;
}

- (void)setDelegate:(id)aDelegate {
    nonretainedDelegate = aDelegate;
}

- (float)volume {
    if (!audioPlayer) return 0.0;
    return [audioPlayer volume];
}

- (void)setVolume:(float)value {
    if (!audioPlayer) return;
    if (value < 0.0) value = 0.0;
    if (value > 1.0) value = 1.0;
    [audioPlayer setVolume:value];
}

- (BOOL)shouldLoop {
    return looping;
}

- (void)setShouldLoop:(BOOL)value {
    looping = value;
    if (audioPlayer) {
        audioPlayer.numberOfLoops = value ? -1 : 0;
    }
}

- (float)duration {
    if (!audioPlayer) return 0.0;
    return (float)[audioPlayer duration];
}

- (float)playbackPosition {
    if (!audioPlayer) return 0.0;
    return (float)[audioPlayer currentTime];
}

- (void)setPlaybackPosition:(float)value {
    if (!audioPlayer) return;
    audioPlayer.currentTime = value;
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (nonretainedDelegate && [nonretainedDelegate respondsToSelector:@selector(avSoundFilePlayer:didFinishPlaying:)]) {
        [nonretainedDelegate avSoundFilePlayer:self didFinishPlaying:flag];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"AVSoundFilePlayer: decode error: %@", error);
    if (nonretainedDelegate && [nonretainedDelegate respondsToSelector:@selector(avSoundFilePlayer:didFinishPlaying:)]) {
        [nonretainedDelegate avSoundFilePlayer:self didFinishPlaying:NO];
    }
}

- (void)dealloc {
    [audioPlayer setDelegate:nil];
    [audioPlayer stop];
    [audioPlayer release];
    [super dealloc];
}

@end
