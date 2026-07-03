TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = Locket
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LocketNotify

LocketNotify_FILES = Tweak.x
LocketNotify_CFLAGS = -fobjc-arc
LocketNotify_FRAMEWORKS = UIKit CoreGraphics QuartzCore
LocketNotify_PRIVATE_FRAMEWORKS = SpringBoardServices

include $(THEOS_MAKE_PATH)/tweak.mk
