
#import "functions.h"

NSString* CBTimeStringForSeconds(int seconds) {

	if (seconds > 6000) {
		// Would return more than 100 minutes --> return hh:mm instead of mm:ss
		unsigned int h = floor(seconds / 3600);
		unsigned int remaining = h ? seconds - (h * 3600) : seconds;
		unsigned int m = floor(remaining / 60);		
		return [NSString stringWithFormat:@"%ih:%02i", h, m];
	}

	// Return mm:ss
	unsigned int m = floor(round(seconds) / 60);
	unsigned int s = round(round(seconds) - (m * 60));
	return [NSString stringWithFormat:@"%02i:%02i", m, s];
}
