//
//  RKKeyboardProfile.m
//  RetroKeyboard
//
//  Created by Yung-Luen Lan on 2/16/10.
//  Copyright 2010 yllan.org. All rights reserved.
//

#import "RKKeyboardProfile.h"
#import <AVKit/AVKit.h>

static NSString *RKKeyboardProfileMappingFileName = @"Mapping.plist";
static NSString *RKKeyboardProfileDisplayNameKey = @"DisplayName";
static NSString *RKKeyboardProfileKeyDownMappingKey = @"KeyDownMapping";
static NSString *RKKeyboardProfileKeyUpMappingKey = @"KeyUpMapping";

@implementation RKKeyboardProfile

@synthesize soundCaches = _soundCache;
@synthesize path = _path;
@synthesize name = _name;

+ (NSArray *) profilesWithPaths: (NSArray *)paths
{
    NSMutableArray *results = [NSMutableArray array];
    
    for (NSString *path in paths) {
        RKKeyboardProfile *profile = [RKKeyboardProfile profileWithPath: path];
        if (profile)
            [results addObject: profile];
    }
    return results;
}

+ (id) profileWithPath: (NSString *)path
{
    return [[[RKKeyboardProfile alloc] initWithPath: path] autorelease];
}

- (id) initWithPath: (NSString *)path needQuickTime: (BOOL)needQT
{
 	if (self = [super init]) {
        NSMutableDictionary *soundCaches = [NSMutableDictionary dictionary];
		NSDictionary *mappingDictionary = [NSDictionary dictionaryWithContentsOfFile: [path stringByAppendingPathComponent: RKKeyboardProfileMappingFileName]];        
        self.name = [mappingDictionary objectForKey: RKKeyboardProfileDisplayNameKey];
        if (!mappingDictionary || !self.name) {
            [self release];
            return nil;
        }
		
        NSArray *keyDownMappings = [mappingDictionary objectForKey: RKKeyboardProfileKeyDownMappingKey];
		NSArray *keyUpMappings = [mappingDictionary objectForKey: RKKeyboardProfileKeyUpMappingKey];
        
		if ([keyDownMappings count] < 128 || [keyUpMappings count] < 128)
			return nil;
		
        void (^setSoundToArray)(NSUInteger, id[128], NSArray *) = ^(NSUInteger idx, id *array, NSArray *mappings) {
			NSString *soundName = [mappings objectAtIndex: idx];
			if ([[soundCaches objectForKey: soundName] isKindOfClass: [NSSound class]]) {
				array[idx] = [soundCaches objectForKey: soundName];
			} else {
				id soundObject;
                if (needQT) {
                    soundObject = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:[path stringByAppendingPathComponent: soundName]]];
                }
				else
					soundObject = [[[NSSound alloc] initWithContentsOfFile: [path stringByAppendingPathComponent: soundName]
                                                               byReference: YES] autorelease];
				if (soundObject)
                    [soundCaches setValue: soundObject forKey: soundName];
				array[idx] = soundObject;
			}
        };
		int i;
		for (i = 0; i < 128; i++) {
            setSoundToArray(i, keyDown, keyDownMappings);
            setSoundToArray(i, keyUp, keyUpMappings);
		}
		self.soundCaches = soundCaches;
        self.path = path;
	}
	return self;
}

- (id) initWithPath: (NSString *)path
{
    return [self initWithPath: path needQuickTime: NO];
}

- (void) setVolume: (float)volume
{	
	int i;
	for (i = 0; i < 128; i++) {
        if ([keyUp[i] respondsToSelector: @selector(setVolume:)]) [keyUp[i] setVolume: volume];
        if ([keyDown[i] respondsToSelector: @selector(setVolume:)]) [keyDown[i] setVolume: volume];
	}
}

- (void) playKeyUp: (int)idx
{
    if (idx > 128) return;
	if ([keyUp[idx] isKindOfClass: [NSSound class]] && [keyUp[idx] isPlaying]) return;
    if ([keyUp[idx] isKindOfClass: [AVPlayer class]] && [keyUp[idx] rate] == 0)
        [keyUp[idx] seekToTime: kCMTimeZero];
	[keyUp[idx] performSelector: @selector(play)];  // Make compiler happy.
}

- (void) playKeyDown: (int)idx
{
    if (idx > 128) return;
	if ([keyDown[idx] isKindOfClass: [NSSound class]] && [keyDown[idx] isPlaying]) return;
    if ([keyDown[idx] isKindOfClass: [AVPlayer class]] && [keyDown[idx] rate] == 0)
        [keyDown[idx] seekToTime: kCMTimeZero];
	[keyDown[idx] performSelector: @selector(play)];	
}


- (void) dealloc
{
    [_soundCache release], _soundCache = nil;
    [_path release], _path = nil;
    [_name release], _name= nil;
    [super dealloc];
}

@end

