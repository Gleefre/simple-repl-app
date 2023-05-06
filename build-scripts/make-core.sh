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

LISP_FILENAME=repl-launcher.lisp

# Remove previous core
adb shell rm -f /data/local/tmp/$LISP_FILENAME
adb shell rm -f /data/local/tmp/libcore.so

echo "Building core"
adb push lisp/$LISP_FILENAME /data/local/tmp
adb shell "cd /data/local/tmp ; export HOME=\$(pwd); ./sbcl/run-sbcl.sh --load $LISP_FILENAME";
adb pull /data/local/tmp/lib.gleefre.core.so libs/$abi/lib.gleefre.core.so
