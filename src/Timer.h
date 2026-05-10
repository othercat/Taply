
#import <Cocoa/Cocoa.h>
#import "functions.h"

@interface Timer : NSObject {
	BOOL paused;
	BOOL resetTimer;
	id currentFile;
	float elapsedTime;
}

-(void)timerLoop:(id)textField;
-(void)setCurrentFile:(NSString *)path;
-(void)setElapsedTime:(NSNumber *)elapsedSeconds;


/*!
 * @method resetTimer
 * @abstract Informs the timer that upon next execution loop, both the timer and the progress bar should start from the beginning
 */
-(void)resetTimer;

/*!
 * @method setPaused:
 * @param (BOOL)flag Whether to start a pause or resume playing
 * @abstract Sets the timer to "pause mode" -- timer and progress bar both will halt
 */
-(void)setPaused:(BOOL)flag;


@end
