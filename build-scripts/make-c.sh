#!/bin/sh
set -e

# Guessing architecture.
if [ -z $ARCH ]; then
    uname_arch=`adb shell uname -m`
else
    uname_arch=$ARCH
fi

case $uname_arch in
    x86_64) abi=x86_64 ;;
    aarch64) abi=arm64-v8a ;;
    *) echo "Architecture $uname_arch is not supported."
       exit 1 ;;
esac
echo "Architecture $abi determined."

CC=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$uname_arch-linux-android21-clang

$CC -fPIC -shared -o libs/$abi/lib.gleefre.wrap.so c/wrap.c -lsbcl -llog -Llibs/$abi
