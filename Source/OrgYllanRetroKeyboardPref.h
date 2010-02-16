//
//  RetroKeyboardPref.h
//  RetroKeyboard
//
//  Created by Yung-Luen Lan on 2/16/10.
//  Copyright (c) 2010 yllan.org. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface OrgYllanRetroKeyboardPref : NSPreferencePane 
{
	NSString *_path;
	NSNumber *_volume;
    BOOL _startAtLogin;
    
	NSArray *_profiles;
	NSTimer *_checkTimer;
	
	BOOL _launching;
	BOOL _quiting;
	
	NSButton *_launchButton;
	NSButton *_startAtLoginButton;
	NSSlider *_volumeSlider;
	NSArrayController *_arrayController;
}

@property (nonatomic, assign) BOOL startAtLogin;
@property (nonatomic, retain) IBOutlet NSArrayController *arrayController;
@property (nonatomic, retain) IBOutlet NSSlider *volumeSlider;
@property (nonatomic, retain) IBOutlet NSButton *startAtLoginButton;
@property (nonatomic, retain) IBOutlet NSButton *launchButton;

@property (nonatomic, assign) BOOL quiting;
@property (nonatomic, assign) BOOL launching;

@property (nonatomic, retain) NSTimer *checkTimer;
@property (nonatomic, copy) NSArray *profiles;
@property (nonatomic, retain) NSNumber *volume;
@property (nonatomic, copy) NSString *path;

- (void) mainViewDidLoad;

- (BOOL) isDaemonRunning;
- (void) checkAppRunningState;

- (NSString *) daemonPath;

- (IBAction) changeVolume: (id)sender;
- (IBAction) changeProfile: (id)sender;
- (IBAction) changeStartAtLogin: (id)sender;
- (IBAction) launchApp: (id)sender;

- (void) changePreference;
@end


