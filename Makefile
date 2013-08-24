include theos/makefiles/common.mk

TWEAK_NAME = AAAPowerSoundDisabler
AAAPowerSoundDisabler_FILES = Tweak.xm
AAAPowerSoundDisabler_CFLAGS = -I/Work/SpeakEvents/include
AAAPowerSoundDisabler_LDFLAGS = -lsubstrate -L/Work/SpeakEvents/lib
AAAPowerSoundDisabler_FRAMEWORKS = AudioToolbox

export TARGET=iphone:latest:5.0
export ARCHS = armv7

include $(THEOS_MAKE_PATH)/tweak.mk


distclean:
	rm *.deb || true

test: distclean package install
