#import <AudioToolbox/AudioToolbox.h>
#import <substrate.h>

#include <sys/time.h>

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


- (void)_indicateConnectedToPower {
	
	NSLog(@"PowerSoundDisabler: Ignoring power sound...");
	absTime = GetTimestampMsec();


	return;
	%orig;
}

%end

void (*original_AudioServicesPlaySystemSound) (SystemSoundID inSystemSoundID);

void replaced_AudioServicesPlaySystemSound (SystemSoundID sound)
{
	NSLog(@"PowerSoundDisabler: Playing sound %d", sound);
	if (sound == 1106) 
	{
		NSLog(@"PowerSoundDisabler: Ignoring power sound using 2nd method...");
	    return;
	}
	else if (GetTimestampMsec() - absTime < 1500)
	{
		NSLog(@"PowerSoundDisabler: Ignoring power sound (or something like this) using 3nd method...");
		return;
	}

	original_AudioServicesPlaySystemSound(sound);
}

%ctor
{
	NSLog(@"PowerSoundDisabler: Init");
	MSHookFunction((void*)&AudioServicesPlaySystemSound, (void*)replaced_AudioServicesPlaySystemSound, (void**)&original_AudioServicesPlaySystemSound);
}
