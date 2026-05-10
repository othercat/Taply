
#import "TaplyGradientBox.h"

@implementation TaplyGradientBox

#pragma mark -
#pragma mark Drag&Drop Methods

-(unsigned int) draggingEntered:(id <NSDraggingInfo>)sender {	
	[[NSCursor dragCopyCursor] set];
	return NSDragOperationGeneric;
}

-(void)draggingExited:(id <NSDraggingInfo>)sender {	
	[[NSCursor arrowCursor] set];
}

- (unsigned int) draggingUpdated:(id <NSDraggingInfo>)sender {	
	[[NSCursor dragCopyCursor] set];
	return NSDragOperationEvery;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	return [controller performDragOperation:sender];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	[[NSCursor arrowCursor] set];	
}

@end
