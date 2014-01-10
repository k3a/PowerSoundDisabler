#import <AudioToolbox/AudioToolbox.h>
#import <substrate.h>

#include <sys/time.h>

static NSDictionary* s_settings = nil;

%hook SBUIController

typedef unsigned int U32;

static U32 absTime = 0;
static U32 GetTimestampMsec()
{
	timeval time;
	gettimeofday(&time, NULL);
	
	U32 elapsed_seconds  = (U32)time.tv_sec;
	U32 elapsed_useconds = time.tv_usec;
	
	return elapsed_seconds * 1000 + elapsed_useconds/1000;	
}

static BOOL is_disabled(unsigned snd)
{
	if (!s_settings) return FALSE;
		
	NSNumber* num = [s_settings objectForKey:[NSString stringWithFormat:@"%u", snd]];
	return num && [num boolValue] == FALSE;
}

- (void)_indicateConnectedToPower {

	if (is_disabled(1106))
	{
		NSLog(@"SystemSoundDisabler: Ignoring power sound...");
		absTime = GetTimestampMsec();
		return;
	}

	%orig;
}

%end

void (*original_AudioServicesPlaySystemSound) (SystemSoundID inSystemSoundID);

void replaced_AudioServicesPlaySystemSound (SystemSoundID sound)
{
	if (sound == 1106 && is_disabled(1106)) 
	{
		NSLog(@"SystemSoundDisabler: Ignoring power sound using 2nd method...");
	    return;
	}
	else if (GetTimestampMsec() - absTime < 1500 && is_disabled(1106))
	{
		NSLog(@"SystemSoundDisabler: Ignoring power sound (or something like this) using 3nd method...");
		return;
	}
	else if (is_disabled(sound))
	{
		NSLog(@"SystemSoundDisabler: Ignoring sound id %u", (unsigned)sound);
		return;
	}

	NSLog(@"SystemSoundDisabler: Playing sound %u", (unsigned int)sound);
	original_AudioServicesPlaySystemSound(sound);
}

static void ReloadSettings()
{
	[s_settings release];
	s_settings = [[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/me.k3a.systemsounddisabler.plist"] retain];
}

static void OnSettingsChangedNotif(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	    ReloadSettings();
}

%ctor
{
	//NSLog(@"SystemSoundDisabler: Init");
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, OnSettingsChangedNotif, CFSTR("me.k3a.systemsounddisabler.change"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	ReloadSettings();

	MSHookFunction((void*)&AudioServicesPlaySystemSound, (void*)replaced_AudioServicesPlaySystemSound, (void**)&original_AudioServicesPlaySystemSound);
}
