//
//  RKKeyboardProfile.h
//  RetroKeyboard
//
//  Created by Yung-Luen Lan on 2/16/10.
//  Copyright 2010 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RKKeyboardProfile : NSObject {
	NSString *_path;
	NSString *_name;
    
    NSDictionary *_soundCache;
	id keyDown[128];
	id keyUp[128];
}

@property (nonatomic, copy) NSDictionary *soundCaches;
@property (copy, readwrite) NSString *path;
@property (copy, readwrite) NSString *name;

+ (NSArray *) profilesWithPaths: (NSArray *)paths;
+ (id) profileWithPath: (NSString *)path;
- (id) initWithPath: (NSString *)path;
- (id) initWithPath: (NSString *)path needQuickTime: (BOOL)needQT;

- (void) setVolume: (float) volume;
- (void) playKeyUp: (int)idx;
- (void) playKeyDown: (int)idx;

@end


