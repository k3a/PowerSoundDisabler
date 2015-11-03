include theos/makefiles/common.mk

TWEAK_NAME = AAASystemSoundDisabler
AAASystemSoundDisabler_FILES = Tweak.xm
AAASystemSoundDisabler_CFLAGS = -I/Work/SpeakEvents/include
AAASystemSoundDisabler_LDFLAGS = -lsubstrate -L/Work/SpeakEvents/lib
#AAASystemSoundDisabler_FRAMEWORKS = AudioToolbox

export TARGET=iphone:latest:5.0
export ARCHS = armv7 armv7s arm64

include $(THEOS_MAKE_PATH)/tweak.mk


distclean:
	rm *.deb || true

test: distclean package install
