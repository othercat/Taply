
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface TaplyPlaylist : NSObject {
	NSMutableArray *playlist;
	unsigned int currentSound;
}

// Add object(s) to playlist
-(void)add:(id)object;

-(void)remove:(unsigned int)index;

-(unsigned int)count;

-(NSString *)soundAtIndex:(unsigned int)index;

-(void)removeAllExcept:(int)index;

@end
