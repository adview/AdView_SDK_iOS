//
//  AdViewMraidParser.h
//  AdViewHello
//
//  Created by AdView on 15-1-20.
//
//

#import <Foundation/Foundation.h>
// A parser class which validates MRAID commands passed from the creative to the native methods.
// This takes a commandUrl of type "mraid://command?param1=val1&param2=val2&..." and return a
// dictionary of key/value pairs which include command name and all the parameters. It checks
// if the command itself is a valid MRAID command and also a simpler parameters validation.
@interface AdViewMraidParser : NSObject
- (NSDictionary*)parseCommandUrl:(NSString*)commandUrl;
@end
