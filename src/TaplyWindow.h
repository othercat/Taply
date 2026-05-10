
#import <Cocoa/Cocoa.h>

@interface TaplyWindow : NSPanel
{

}

-(id)initWithContentRect:(NSRect)contentRect
			   styleMask:(unsigned int)aStyle
				 backing:(NSBackingStoreType)bufferingType
				   defer:(BOOL)flag;

-(BOOL)canBecomeKeyWindow;

-(void)setAlpha:(float)alpha;

-(void)fadeOut;

@end
