//
//  RKDaemonController.h
//  RetroKeyboard
//
//  Created by Yung-Luen Lan on 2/16/10.
//  Copyright 2010 yllan.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#import "RKKeyboardProfile.h"
#import "SynthesizeSingleton.h"

@interface RKDaemonController : NSObject {
    RKKeyboardProfile *_profile;
    float _volume;
    CGEventFlags _previousFlags;
}

@property (nonatomic, assign) CGEventFlags previousFlags;
@property (nonatomic, assign) float volume;
@property (nonatomic, retain) RKKeyboardProfile *profile;

+ (RKDaemonController *) sharedRKDaemonController;
- (void) readPreference;
- (void) attachEventTap;
@end


