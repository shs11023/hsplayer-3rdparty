#!/bin/sh

if [ ! `which yasm` ]
	then
    brew install yasm || exit 1
fi

FEATURES="--enable-decoder=h264 \
          --enable-decoder=h264_mediacodec \
          --enable-parser=h264 \
          --enable-demuxer=h264 \
          --enable-demuxer=mov \
          --enable-protocol=file"


function build
{
(
echo "BUILDING: $OUTPUT_DIR..."

cd ffmpeg;

OUTPUT_DIR=../ios-builds/$OUTPUT_DIR

./configure \
    --prefix=$OUTPUT_DIR \
    --disable-shared \
    --enable-static \
    --enable-cross-compile \
    --cc="$CC" \
    --as="$AS" \
    --target-os=darwin \
    --arch=$ARCH \
    --extra-cflags="-Os -fpic $ADDI_CFLAGS" \
    --extra-ldflags="$ADDI_LDFLAGS" \
    --enable-memalign-hack \
    --disable-mediacodec \
    --disable-jni \
    --disable-doc \
    --disable-ffmpeg \
    --disable-ffplay \
    --disable-ffprobe \
    --disable-ffserver \
    --disable-symver \
    --disable-everything \
    $FEATURES \
    $ADDI_CONFIGURE_FLAG;

make clean;
make -j4;
make install $EXPORT

cat <<\EOF > "$OUTPUT_DIR/IOS.mk"
LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE:= libavdevice
LOCAL_SRC_FILES:= lib/libavdevice.a
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE:= libavcodec
LOCAL_SRC_FILES:= lib/libavcodec.a
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE:= libavformat
LOCAL_SRC_FILES:= lib/libavformat.a
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE:= libswscale
LOCAL_SRC_FILES:= lib/libswscale.a
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE:= libavutil
LOCAL_SRC_FILES:= lib/libavutil.a
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE:= libavfilter
LOCAL_SRC_FILES:= lib/libavfilter.a
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE:= libswresample
LOCAL_SRC_FILES:= lib/libswresample.a
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include
include $(PREBUILT_STATIC_LIBRARY)
EOF
)
}

DEPLOYMENT_TARGET="6.0"


#iPhoneSimulator
ADDI_CFLAGS="-mios-simulator-version-min=$DEPLOYMENT_TARGET"
ADDI_LDFLAGS=
ADDI_CONFIGURE_FLAG="--enable-neon"
PLATFORM="iPhoneSimulator"
XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
CC="xcrun -sdk $XCRUN_SDK clang"
AR="xcrun -sdk $XCRUN_SDK ar"

ARCHS="x86_64 i386"

for ARCH in $ARCHS
do
  OUTPUT_DIR="$ARCH"
  build
done


#iPhoneOS
ADDI_CFLAGS="-mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode"
ADDI_LDFLAGS=
ADDI_CONFIGURE_FLAG="--enable-neon"
PLATFORM="iPhoneOS"
XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
AR="xcrun -sdk $XCRUN_SDK ar"

ARCHS="arm64 armv7"

for ARCH in $ARCHS
do
  CC="xcrun -sdk $XCRUN_SDK clang -arch $ARCH"
  OUTPUT_DIR="$ARCH"
  EXPORT=
  if [ "$ARCH" = "arm64" ]
  then
    EXPORT="GASPP_FIX_XCODE5=1"
  fi
  build
done


echo "Finished. Exiting..."
