APP_STL := gnustl_static
APP_CPPFLAGS := -frtti -Wno-error=format-security -fsigned-char -Os $(CPPFLAGS)
#APP_ABI := armeabi
#APP_ABI := all
APP_ABI := armeabi armeabi-v7a x86
APP_OPTIM := release
