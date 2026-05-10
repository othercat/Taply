
#import "TaplyWindow.h"

@implementation TaplyWindow

- (id)initWithContentRect:(NSRect)contentRect
				styleMask:(unsigned int)aStyle
				  backing:(NSBackingStoreType)bufferingType
					defer:(BOOL)flag {

	if (self = [super initWithContentRect:contentRect
	                  styleMask:NSTitledWindowMask |
					            NSUtilityWindowMask |
								NSClosableWindowMask |
								NSMiniaturizableWindowMask
	                  backing:NSBackingStoreBuffered
	                  defer:NO]) {

        [self setLevel: NSStatusWindowLevel];
        [self setHasShadow:YES];
        return self;
    }

    return nil;
}

-(void)fadeOut {
	int i;
    for (i = 10; i >= 0; i --) {
        [self setAlpha:(float)i/10];
    }
	[self orderOut:self];
}

-(void)setAlpha:(float)alpha {
	[self setAlphaValue:alpha];
	[self display];
}

-(BOOL)canBecomeKeyWindow {
    return YES;
}

@end
