
#import "TaplyPositionBar.h"

@implementation TaplyPositionBar

-(void)resetCursorRects {
	[self addCursorRect:[self bounds]
				 cursor:[NSCursor pointingHandCursor]];

}

-(BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return YES;
}

-(void)reset {
	elapsedLength = 0;
	[self setNeedsDisplay:YES];
}

-(void)setPosition:(NSNumber *) thePosition {
	elapsedLength = [self bounds].size.width * [thePosition floatValue] / duration;
	[self setNeedsDisplay:YES];
}

-(void)setDuration:(NSNumber *) theDuration {
	duration = [theDuration floatValue];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		bgColor = [NSColor colorWithCalibratedRed:0.78
											green:0.78
											 blue:0.78
											alpha:1.0];
		fgColor = [NSColor colorWithCalibratedRed:0.27
											green:0.27
											 blue:0.27
											alpha:1.0];	
		[bgColor retain];
		[fgColor retain];
    }
    return self;
}

-(void)dealloc {
	[bgColor release];
	[fgColor release];
    [controller release];
	[super dealloc];
}

-(void)mouseDown:(NSEvent *)theEvent {
	NSPoint localPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	float positionInSeconds = localPoint.x / [self bounds].size.width * duration;
	[controller setNewPlayerPosition:[NSNumber numberWithFloat:positionInSeconds]];
}

- (void)drawRect:(NSRect)rect {
	[bgColor set];
	NSRectFill(NSMakeRect(0, 4, [self bounds].size.width, 4));

	[fgColor set];
	if (elapsedLength > 1) {
		NSRectFill(NSMakeRect(0, 4, elapsedLength, 4));
	} else if (elapsedLength > 0.2) {
		NSRectFill(NSMakeRect(0, 4, 1, 4));
	}
}

- (id)controller {
    return controller; 
}

- (void)setController:(id)aController {
    [aController retain];
    [controller release];
    controller = aController;
}
@end

