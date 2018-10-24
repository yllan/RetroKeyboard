//
//  RKDaemonController.m
//  RetroKeyboard
//
//  Created by Yung-Luen Lan on 2/16/10.
//  Copyright 2010 yllan.org. All rights reserved.
//

#import "RKDaemonController.h"
#import "RKKeyboardProfile.h"
#import "RKBase.h"
#import <ApplicationServices/ApplicationServices.h>

CGEventRef myCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
    if ((type != kCGEventKeyDown) && (type != kCGEventKeyUp) && (type != kCGEventFlagsChanged))
        return NULL;    
    CGKeyCode keycode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);

    if (CGEventGetIntegerValueField(event, kCGKeyboardEventAutorepeat))
        return NULL;
    RKDaemonController *controller = [RKDaemonController sharedRKDaemonController];
    CGEventFlags eventFlags = CGEventGetFlags(event);
    RKKeyboardProfile *profile = controller.profile;
    
    switch (type) {
        case kCGEventKeyUp:
            [profile playKeyUp: keycode];
            break;
        case kCGEventKeyDown:
            [profile playKeyDown: keycode];
            break;
        case kCGEventFlagsChanged:
            
            if (controller.previousFlags < eventFlags) {
                [profile playKeyDown: keycode];
            } else {
                [profile playKeyUp: keycode];
            }
            controller.previousFlags = eventFlags;
            break;            
    }
    
    return NULL;
}

@implementation RKDaemonController
@synthesize previousFlags = _previousFlags;

SYNTHESIZE_SINGLETON_FOR_CLASS(RKDaemonController);

@synthesize volume = _volume;
@synthesize profile = _profile;

- (BOOL) isAuth
{
    NSDictionary *options = @{(id)kAXTrustedCheckOptionPrompt: @YES};
    BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions((CFDictionaryRef)options);
    return accessibilityEnabled;
}

- (void) awakeFromNib
{
    NSConnection *connection = [[NSConnection new] autorelease];
    [connection setRootObject: self];
    
    /* Make sure there is only one app instance */
	if (![connection registerName: RKDaemonName]) {
		[NSApp terminate: self];
		return;
	}
    
    if([self isAuth] == false) {
        [NSApp terminate: self];
    }
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver: self selector: @selector(readPreference) name: RKDaemonUpdatePreferenceNotificationName object: RKDaemonNotificationSenderIdentifier];
	[[NSDistributedNotificationCenter defaultCenter] addObserver: self selector: @selector(shouldQuit) name: RKDaemonShouldQuitNotificationName object: RKDaemonNotificationSenderIdentifier];
	[self readPreference];
	[self attachEventTap];
    
}

- (void) shouldQuit 
{
	[NSApp terminate: self];
}

- (void) readPreference 
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults synchronize];
	NSString *path = [userDefaults stringForKey: kRKPathKey];
	self.volume = [userDefaults floatForKey: kRKVolumeKey];
	
	RKKeyboardProfile *profile = [[RKKeyboardProfile alloc] initWithPath: path needQuickTime: (self.volume < 0.95)];
    self.profile = profile;
    [profile setVolume: self.volume];
    [profile release];
}

- (void) attachEventTap
{
    CFMachPortRef eventTap;
    CGEventMask eventMask;
    CFRunLoopSourceRef runLoopSource;
    // Create an event tap. We are interested in key presses.
    eventMask = CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventFlagsChanged);
    eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionListenOnly, eventMask, myCGEventCallback, NULL);
    if (!eventTap) {
        fprintf(stderr, "failed to create event tap\n");
        exit(1);
    }
    
    // Create a run loop source.
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    
    // Add to the current run loop.
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    
    // Enable the event tap.
    CGEventTapEnable(eventTap, true);
    
    CFRelease(runLoopSource);
    CFRelease(eventTap);
}


- (void) dealloc
{
	[_profile release], _profile = nil;
	[super dealloc];
}
@end




