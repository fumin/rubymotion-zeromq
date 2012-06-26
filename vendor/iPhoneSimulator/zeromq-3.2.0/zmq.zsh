#!/usr/bin/env zsh

make clean &>>|/dev/null

BUILD_DIR=`pwd`/build

if [[ -d $BUILD_DIR ]]; then
  rm -fr $BUILD_DIR
fi

mkdir -p $BUILD_DIR

ZMQ_BUILD_LOG_FILE=$BUILD_DIR/build.log

echo "-- Configuring with prefix $BUILD_DIR"
SDK_ROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer"
export CPP="cpp"
export CXXCPP="cpp"
export CXX="${SDK_ROOT}/usr/bin/i686-apple-darwin11-llvm-g++-4.2"
export CXXFLAGS="-O -isysroot $SDK_ROOT/SDKs/iPhoneSimulator5.1.sdk"
export CC="${SDK_ROOT}/usr/bin/i686-apple-darwin11-llvm-gcc-4.2"
export CFLAGS="-O -isysroot $SDK_ROOT/SDKs/iPhoneSimulator5.1.sdk"
export AR=$SDK_ROOT"/usr/bin/ar"
export AS=$SDK_ROOT"/usr/bin/as"
export LD=$SDK_ROOT"/usr/bin/ld"
export LDFLAGS="-lstdc++ -isysroot $SDK_ROOT/SDKs/iPhoneSimulator5.1.sdk"
export LIBTOOL=$SDK_ROOT"/usr/bin/libtool"
export STRIP=$SDK_ROOT"/usr/bin/strip"
export RANLIB=$SDKROOT"/usr/bin/ranlib"

#./configure --disable-dependency-tracking --enable-static --disable-shared --host=arm-apple-darwin10 --prefix=$BUILD_DIR &>>| $ZMQ_BUILD_LOG_FILE
./configure --disable-dependency-tracking --enable-static --disable-shared --host=i686-apple-darwin11 --prefix=$BUILD_DIR &>>| $ZMQ_BUILD_LOG_FILE

echo "-- Building"
make &>>| $ZMQ_BUILD_LOG_FILE

echo "-- Installing to $BUILD_DIR"
make install &>>| $ZMQ_BUILD_LOG_FILE

echo "-- Cleaning up"
make clean &>>| /dev/null

echo "-- Copying headers"
mkdir $BUILD_DIR/usr && cp -R include $BUILD_DIR/usr
