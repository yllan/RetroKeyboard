//
//  RetroKeyboardPref.m
//  RetroKeyboard
//
//  Created by Yung-Luen Lan on 2/16/10.
//  Copyright (c) 2010 yllan.org. All rights reserved.
//

#import "OrgYllanRetroKeyboardPref.h"
#import "RKKeyboardProfile.h"
#import "RKBase.h"

static CFStringRef kRetroKeyboardAppID = CFSTR("org.yllan.RetroKeyboard");
static NSString *kRetroKeyboardProfileResourceType = @"KBProfile";

typedef enum {
    RetroKeyboardStartState = NSOffState, RetroKeyboardStopState = NSOnState
} RetroKeyboardButtonState;

@implementation OrgYllanRetroKeyboardPref

@synthesize startAtLogin = _startAtLogin;
@synthesize arrayController = _arrayController;
@synthesize volumeSlider = _volumeSlider;
@synthesize startAtLoginButton = _startAtLoginButton;
@synthesize launchButton = _launchButton;
@synthesize quiting = _quiting;
@synthesize launching = _launching;
@synthesize checkTimer = _checkTimer;
@synthesize profiles = _profiles;
@synthesize volume = _volume;
@synthesize path = _path;

- (void) mainViewDidLoad
{
}

- (void) willSelect
{
	CFPropertyListRef value;
    
	/* start at login button */
	value = CFPreferencesCopyAppValue((CFStringRef)kRKStartAtLoginKey, kRetroKeyboardAppID);
    self.startAtLogin = (value && CFGetTypeID(value) == CFBooleanGetTypeID()) ? CFBooleanGetValue(value) : NO;
    [self.startAtLoginButton setState: self.startAtLogin ? NSOnState : NSOffState];
	if (value) CFRelease(value);
    
	/* volume */
	value = CFPreferencesCopyAppValue((CFStringRef)kRKVolumeKey,  kRetroKeyboardAppID);
    self.volume = (value && CFGetTypeID(value) == CFNumberGetTypeID()) ? (NSNumber *)value : [NSNumber numberWithFloat: 1.0];
	if (value) CFRelease(value);
	
	/* path */
	value = CFPreferencesCopyAppValue((CFStringRef)kRKPathKey,  kRetroKeyboardAppID);
    self.path = (value && CFGetTypeID(value) == CFStringGetTypeID()) ? (NSString *)value : @"";
	if (value) CFRelease(value);
	
	NSArray *builtin = [self.bundle pathsForResourcesOfType: kRetroKeyboardProfileResourceType inDirectory: @"Profiles"];
	
	NSString *extraPath = [@"~/Library/Application Support/RetroKeyboard" stringByExpandingTildeInPath];
	NSArray *extras = [NSBundle pathsForResourcesOfType: kRetroKeyboardProfileResourceType inDirectory: extraPath];
	
	self.profiles = [[RKKeyboardProfile profilesWithPaths: builtin] arrayByAddingObjectsFromArray: [RKKeyboardProfile profilesWithPaths: extras]];
	
    [self.profiles enumerateObjectsUsingBlock: ^(id profile, NSUInteger idx, BOOL *stop) {
        if ([((RKKeyboardProfile *)profile).path isEqualToString: self.path]) {
            [self.arrayController setSelectedObjects: [NSArray arrayWithObject: profile]];
            *stop = YES;
        }
    }];
    	
    CFPreferencesSetAppValue((CFStringRef)kRKStartAtLoginKey, self.startAtLogin ? kCFBooleanTrue : kCFBooleanFalse, kRetroKeyboardAppID);
	CFPreferencesSetAppValue((CFStringRef)kRKVolumeKey, self.volume, kRetroKeyboardAppID);
	CFPreferencesSetAppValue((CFStringRef)kRKPathKey, self.path, kRetroKeyboardAppID);
	CFPreferencesAppSynchronize(kRetroKeyboardAppID);
	[self changePreference];

	self.checkTimer = [NSTimer timerWithTimeInterval: 2 target: self selector: @selector(checkAppRunningState) userInfo: nil repeats: YES];
	[[NSRunLoop currentRunLoop] addTimer: self.checkTimer forMode: NSDefaultRunLoopMode];
    [self checkAppRunningState];
}

- (void) didUnselect
{
	[self.checkTimer invalidate];
    self.checkTimer = nil;
	[self changePreference];
}

- (BOOL) isDaemonRunning
{
    return ([NSConnection connectionWithRegisteredName: RKDaemonName host: nil] != nil);
}

- (void) checkAppRunningState
{
    BOOL executed = [self isDaemonRunning];
	if (self.launching && executed) {
		self.launching = self.quiting = NO;
        self.launchButton.state = RetroKeyboardStopState;
		[self.launchButton setEnabled: YES];
	} else if (self.quiting && !executed) {
		self.launching = self.quiting = NO;
        self.launchButton.state = RetroKeyboardStartState;
		[self.launchButton setEnabled: YES];
	} else if (!self.launching && !self.quiting) {
        self.launchButton.state = executed ? NSOnState : NSOffState;
        [self.launchButton setEnabled: YES];
	}
    else {
        self.launching = self.quiting = NO;
        self.launchButton.state = executed ? NSOnState : NSOffState;
        [self.launchButton setEnabled: YES];
    }
	return;
}

- (IBAction) changeVolume: (id)sender
{
    self.volume = [NSNumber numberWithFloat: [sender floatValue]];
	CFPreferencesSetAppValue((CFStringRef)kRKVolumeKey, self.volume, kRetroKeyboardAppID);
	CFPreferencesAppSynchronize(kRetroKeyboardAppID);
	[self changePreference];
}

- (IBAction) changeProfile: (id)sender
{
	RKKeyboardProfile *profile = [[self.arrayController selectedObjects] objectAtIndex: 0];
	self.path = profile.path;
	CFPreferencesSetAppValue((CFStringRef)kRKPathKey, self.path, kRetroKeyboardAppID);
	CFPreferencesAppSynchronize(kRetroKeyboardAppID);
	[self changePreference];
}

- (IBAction) changeStartAtLogin: (id)sender
{
	BOOL wannaInstall = [sender state];
	
	NSMutableArray* loginItems;
    CFStringRef loginItemKey = CFSTR("AutoLaunchedApplicationDictionary");
    CFStringRef loginWindowName = CFSTR("loginwindow");
	loginItems = (NSMutableArray*) CFPreferencesCopyValue(loginItemKey, loginWindowName, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	loginItems = [[loginItems autorelease] mutableCopy];
	
    NSUInteger retroKeyboardIndexInLoginItems = [loginItems indexOfObjectPassingTest: ^(id item, NSUInteger idx, BOOL *stop) {
        return [[item valueForKey: @"Path"] isEqualToString: [self daemonPath]];
    }];
	
	if (wannaInstall && retroKeyboardIndexInLoginItems == NSNotFound) {
        [loginItems addObject: [NSDictionary dictionaryWithObjectsAndKeys: [self daemonPath], @"Path", [NSNumber numberWithBool: YES], @"Hide", nil]];
	}
	
	if (!wannaInstall && retroKeyboardIndexInLoginItems != NSNotFound) {
		[loginItems removeObjectAtIndex: retroKeyboardIndexInLoginItems];
	}	
	
	CFPreferencesSetValue(loginItemKey, loginItems, loginWindowName, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSynchronize(loginWindowName, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	[loginItems release];
	
    CFPreferencesSetAppValue((CFStringRef)kRKStartAtLoginKey, wannaInstall ? kCFBooleanTrue : kCFBooleanFalse, kRetroKeyboardAppID);
	CFPreferencesAppSynchronize(kRetroKeyboardAppID);	
}

- (IBAction) launchApp: (id)sender
{
	[self.launchButton setEnabled: NO];
    
	if (![self isDaemonRunning]) {
		self.launching = YES, self.quiting = NO;
		[[NSWorkspace sharedWorkspace] launchApplication: [self daemonPath]];
	} else {
		self.quiting = YES, self.launching = NO;
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName: RKDaemonShouldQuitNotificationName object: RKDaemonNotificationSenderIdentifier];
	}
    [self performSelector: @selector(checkAppRunningState) withObject: nil afterDelay: 0.25];
}

- (NSString *) daemonPath
{
    return [[self.bundle sharedSupportPath] stringByAppendingPathComponent: @"RetroKeyboardDaemon.app"];
}

- (void) changePreference
{
	NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
	[center postNotificationName: RKDaemonUpdatePreferenceNotificationName object: RKDaemonNotificationSenderIdentifier];
}

- (void) dealloc
{
    [_checkTimer invalidate];
	[_arrayController release], _arrayController = nil;
	[_volumeSlider release], _volumeSlider = nil;
	[_startAtLoginButton release], _startAtLoginButton = nil;
	[_launchButton release], _launchButton = nil;
	[_checkTimer release], _checkTimer = nil;
	[_profiles release], _profiles = nil;
	[_volume release], _volume = nil;
	[_path release], _path = nil;
	[super dealloc];
}
@end
