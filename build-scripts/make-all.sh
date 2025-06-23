#!/bin/sh
set -e

# Lisp environment (sbcl, quicklisp, local-projects)
./build-scripts/make-sbcl.sh
./build-scripts/adb-init-quicklisp.sh
./build-scripts/adb-init-local-projects.sh

# Lisp, C and Java
./build-scripts/make-core.sh
./build-scripts/make-c.sh
./build-scripts/make-java.sh  # basically ./gradlew assembleDebug

# cp build/outputs/apk/debug/simple-repl-debug.apk prebuilt-apk/
# ./gradlew installDebug
