
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
    }
    return self;
}

-(void)dealloc {
    [controller release];
	[super dealloc];
}

-(void)mouseDown:(NSEvent *)theEvent {
	NSPoint localPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	float positionInSeconds = localPoint.x / [self bounds].size.width * duration;
	[controller setNewPlayerPosition:[NSNumber numberWithFloat:positionInSeconds]];
}

- (void)drawRect:(NSRect)rect {
	// Use system colors that adapt to dark/light mode
	[[NSColor separatorColor] set];
	NSRectFill(NSMakeRect(0, 4, [self bounds].size.width, 4));

	[[NSColor controlTextColor] set];
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

