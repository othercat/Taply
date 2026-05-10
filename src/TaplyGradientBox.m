
#import "TaplyGradientBox.h"

@implementation TaplyGradientBox

#pragma mark -
#pragma mark Drag&Drop Methods

-(unsigned int) draggingEntered:(id <NSDraggingInfo>)sender {	
	SetThemeCursor(kThemeCopyArrowCursor);
	return NSDragOperationGeneric;
}

-(void)draggingExited:(id <NSDraggingInfo>)sender {	
	SetThemeCursor(kThemeArrowCursor);
}

- (unsigned int) draggingUpdated:(id <NSDraggingInfo>)sender {	
	SetThemeCursor(kThemeCopyArrowCursor);
	return NSDragOperationEvery;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	return [controller performDragOperation:sender];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	SetThemeCursor(kThemeArrowCursor);	
}

@end
