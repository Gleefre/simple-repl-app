#!/bin/sh
set -e

./build-scripts/copy-sbcl.sh || ./build-scripts/make-sbcl.sh
./build-scripts/install-quicklisp.sh
./build-scripts/push-local-projects.sh
./build-scripts/make-core.sh
./build-scripts/make-c.sh

./gradlew assembleDebug

# cp build/outputs/apk/debug/simple-repl-debug.apk prebuilt-apk/
