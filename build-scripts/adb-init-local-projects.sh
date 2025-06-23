#!/bin/sh
set -e

if [ ! -d build/external/local-projects ]; then
    mkdir -p build/external/local-projects
    (
        cd build/external/local-projects;
        pwd;
        git clone https://github.com/Gleefre/simple-repl.git;
        git clone https://github.com/Gleefre/and-jni.git;
        git clone https://github.com/Gleefre/cl-android.git;
        git clone https://github.com/Gleefre/android-log.git;
    )
fi

adb push build/external/local-projects/simple-repl/ /data/local/tmp/quicklisp/local-projects/
adb push build/external/local-projects/and-jni/     /data/local/tmp/quicklisp/local-projects/
adb push build/external/local-projects/cl-android/  /data/local/tmp/quicklisp/local-projects/
adb push build/external/local-projects/android-log/ /data/local/tmp/quicklisp/local-projects/
