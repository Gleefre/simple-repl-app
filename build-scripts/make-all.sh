#!/bin/sh
set -e

./build-scripts/make-env.sh
./build-scripts/make-app.sh

# cp build/outputs/apk/debug/simple-repl-app-debug.apk prebuilt/apk/
# ./gradlew installDebug
