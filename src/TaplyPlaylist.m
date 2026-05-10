
#import "TaplyPlaylist.h"

@implementation TaplyPlaylist

-(id)init {
	if ([super init]) {
		playlist = [[NSMutableArray alloc] initWithCapacity:32];
		currentSound = 0;
		return self;
	}
	return nil;
}

-(void)removeAllExcept:(int)index {
	[playlist setArray:[NSArray arrayWithObject:[playlist objectAtIndex:index]]];
}

-(void)add:(id)object {
	if ([object isKindOfClass:[NSString class]]) {
		// Single item
		if (![playlist containsObject:object]) {
			// This item is not in the playlist yet >> Add
			[playlist addObject:object];
		}
	} else {
		unsigned int i;
		for (i = 0; i < [object count]; i ++) {
			if (![playlist containsObject:[object objectAtIndex:i]]) {
				// This item is not in the playlist yet >> Add
				[playlist addObject:[object objectAtIndex:i]];
			}
		}
	}
}

-(void)remove:(unsigned int)index {
	[playlist removeObjectAtIndex:index];
}

-(NSString *)soundAtIndex:(unsigned int)index {
	if (index > [playlist count]) {
		return nil;
	}
	return [playlist objectAtIndex:index];
}

-(unsigned int)count {
	return [playlist count];
}

-(void)dealloc {
	[playlist release];
	[super dealloc];
}

@end
