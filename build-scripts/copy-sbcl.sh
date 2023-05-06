#!/bin/sh
set -e

# Guessing architecture.
uname_arch=`adb shell uname -m`
case $uname_arch in
    x86_64) abi=x86_64 ;;
    aarch64) abi=arm64-v8a ;;
    *) echo "Architecture $uname_arch is not supported."
       exit 1 ;;
esac
echo "Architecture $abi determined."

# Check for sbcl-prebuilt-$abi folder
if [ ! -d sbcl-prebuilt-$abi ]; then
    echo "Can't copy sbcl: sbcl-prebuilt-$abi not found";
    exit 1
fi

# Clean and push to android
adb shell rm -rf /data/local/tmp/sbcl
adb push sbcl-$abi/ /data/local/tmp/sbcl/

# Copy .so file
cp sbcl-prebuilt-$abi/src/runtime/libsbcl.so libs/$abi/libsbcl.so
