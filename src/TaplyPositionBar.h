
#import <Cocoa/Cocoa.h>

@interface TaplyPositionBar : NSView {

	NSColor *bgColor;
	NSColor *fgColor;
	float duration;
	float elapsedLength; // Current width of the "elapsed" bar
	id controller;
}

-(void)reset;

/*!
 * @method setPosition:
 * @abstract Informs the receiver that playback is at a given number of seconds
 * @discussion (description)
 * @param NSNumber Number of seconds
 */
-(void)setPosition:(NSNumber *) thePosition;

-(void)setDuration:(NSNumber *) theDuration;

/*!
* @method controller
* @abstract the getter corresponding to setController
* @result returns value for controller
*/
- (id)controller;

/*!
* @method setController
* @abstract sets controller to the param
* @discussion
* @param aController
*/
- (void)setController:(id)aController;
@end
