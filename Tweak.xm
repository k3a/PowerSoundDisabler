#import <AudioToolbox/AudioToolbox.h>
#import <substrate.h>

#include <dlfcn.h>
#include <dispatch/dispatch.h>

static NSDictionary* s_settings = nil;

static BOOL is_disabled(unsigned snd)
{
	NSNumber* num = [s_settings objectForKey:[[NSNumber numberWithInt:snd] stringValue]];
	if (!num && snd == 1106) num = [NSNumber numberWithBool:FALSE];
	return num && [num boolValue] == FALSE;
}

static BOOL should_play(SystemSoundID sound)
{
	if (sound == 1106 && is_disabled(1106)) 
	{
		NSLog(@"SystemSoundDisabler: Ignoring power sound using 2nd method");
	    return FALSE;
	}
	else if (is_disabled(sound))
	{
		NSLog(@"SystemSoundDisabler: Ignoring sound id %u", (unsigned)sound);
		return FALSE;
	}
	return TRUE;
}

%hook SBUIController
- (void)_indicateConnectedToPower {

	if (is_disabled(1106))
	{
		NSLog(@"SystemSoundDisabler: Ignoring power sound using 1st method");
		return;
	}

	%orig;
}
%end

void AudioServicesPlaySystemSoundWithVibration(SystemSoundID inSystemSoundID,id arg,NSDictionary* vibratePattern);
void (*original_AudioServicesPlaySystemSound)(SystemSoundID inSystemSoundID);
void (*original_AudioServicesPlaySystemSoundWithVibration)(SystemSoundID inSystemSoundID,id arg,NSDictionary* vibratePattern);

void replaced_AudioServicesPlaySystemSound (SystemSoundID sound)
{
	if (should_play(sound)) 
	{
		NSLog(@"SystemSoundDisabler: Playing sound %u", (unsigned int)sound);
		original_AudioServicesPlaySystemSound(sound);
	}
}

void replaced_AudioServicesPlaySystemSoundWithVibration(SystemSoundID inSystemSoundID,id arg,NSDictionary* vibratePattern)
{
	if (should_play(inSystemSoundID)) 
	{
		NSLog(@"SystemSoundDisabler: Playing vibr sound %u", (unsigned int)inSystemSoundID);
		original_AudioServicesPlaySystemSoundWithVibration(inSystemSoundID, arg, vibratePattern);
	}
}

static void ReloadSettings()
{
	[s_settings release];
	s_settings = [[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/me.k3a.systemsounddisabler.plist"] retain];
}

static void OnSettingsChangedNotif(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	NSLog(@"SystemSoundDisabler: Reloading prefs");
	ReloadSettings();
}

%ctor
{
	NSLog(@"SystemSoundDisabler: Init");
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, OnSettingsChangedNotif, CFSTR("me.k3a.systemsounddisabler.change"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	ReloadSettings();

	void* handle = dlopen(0, RTLD_GLOBAL | RTLD_NOW);
	
	void* ptr = dlsym(handle, "AudioServicesPlaySystemSound");
	if (ptr) MSHookFunction(ptr, (void*)replaced_AudioServicesPlaySystemSound, (void**)&original_AudioServicesPlaySystemSound);
	
	ptr = dlsym(handle, "AudioServicesPlaySystemSoundWithVibration");
	if (ptr) MSHookFunction(ptr, (void*)replaced_AudioServicesPlaySystemSoundWithVibration, (void**)&original_AudioServicesPlaySystemSoundWithVibration);
	
	dlclose(handle);
}
