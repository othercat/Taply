
#import <Cocoa/Cocoa.h>
#import <math.h>

/*!
 * @function CBTimeStringForSeconds(int seconds)
 * @abstract Given a number of seconds, returns a "minutes:seconds" time string
 * @param  int Number of seconds
 * @result NSString Time / duration in "mm:ss" format
 */
NSString* CBTimeStringForSeconds(int seconds);
