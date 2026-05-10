
#import "Timer.h"

@implementation Timer

-(id)init {
	[super init];
	paused = NO;
	resetTimer = NO;
	currentFile = [[NSString alloc] initWithString:@""];
	return self;	
}

-(void)timerLoop:(id)userInfo {

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	id textField = [userInfo objectForKey:@"textfield"];
	id positionBar = [userInfo objectForKey:@"positionBar"];
	resetTimer = YES;
    double sleepTime;
    float duration = [[userInfo objectForKey:@"duration"] floatValue];
    
    if (duration < 30.0) {
        sleepTime = 0.04;
    } else if (duration < 80.0) {
        sleepTime = 0.08;
    } else if (duration < 180.0) {
        sleepTime = 0.3;
    } else if (duration < 240.0) {
        sleepTime = 0.4;
    } else {
        sleepTime = 0.5;
    }

	while ([currentFile isEqualToString:[userInfo objectForKey:@"file"]]) {

		if (resetTimer) {
			elapsedTime = 0;
			resetTimer = NO;
			[positionBar performSelectorOnMainThread:@selector(setDuration:)
										  withObject:[userInfo objectForKey:@"duration"]
									   waitUntilDone:NO];
			[positionBar reset];
		}
		
		if (!paused) {
			[positionBar performSelectorOnMainThread:@selector(setPosition:)
										  withObject:[NSNumber numberWithFloat:elapsedTime]
									   waitUntilDone:NO];
			
			[textField setTitle:[NSString stringWithFormat:@"%@",
								       CBTimeStringForSeconds(elapsedTime += sleepTime)]];
		}

		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:sleepTime]]; // Initially: 0.2
    }
	
	[pool release];
}

-(void)setElapsedTime:(NSNumber *)elapsedSeconds {
	elapsedTime = [elapsedSeconds floatValue];
}

-(void)setCurrentFile:(NSString *)path {
	if (currentFile != path) {
		[currentFile release];
		currentFile = [path copy];
	}
}

-(void)setPaused:(BOOL)flag {
	paused = flag;
}

-(void)resetTimer {
	resetTimer = YES;
}

-(void)dealloc {
	[currentFile release];
	[super dealloc];
}

@end
