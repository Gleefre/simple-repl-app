#!/bin/sh
set -e

if [ ! -d local-projects ]; then
    mkdir local-projects
    (
        cd ./local-projects ;
        pwd ;
        git clone https://github.com/Gleefre/simple-repl.git ;
        git clone https://github.com/Gleefre/and-jni.git ;
        git clone https://github.com/Gleefre/cl-android.git ;
        git clone https://github.com/Gleefre/android-log.git ;
    )
fi

adb push local-projects/simple-repl/ /data/local/tmp/quicklisp/local-projects/
adb push local-projects/and-jni/ /data/local/tmp/quicklisp/local-projects/
adb push local-projects/android-log/ /data/local/tmp/quicklisp/local-projects/
adb push local-projects/cl-android/ /data/local/tmp/quicklisp/local-projects/
