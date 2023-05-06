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

# Check for sbcl-$abi folder
if [ ! -d sbcl-$abi ]; then
    echo "Can't prepare prebuilt sbcl: sbcl-$abi not found";
    exit 1
fi

# Clean
rm -rf sbcl-prebuilt-$abi

# Pack
cp build-scripts/android-pack.sh sbcl-$abi/
(
    cd sbcl-$abi ;
    ./android-pack.sh ;
    mv sbcl-pack ../sbcl-prebuilt-$abi ;
)
