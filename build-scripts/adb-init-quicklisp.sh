#!/bin/sh
if [ ! -f build/external/quicklisp.lisp ]; then
    mkdir -p build/external
    ( cd build/external;
      wget https://beta.quicklisp.org/quicklisp.lisp )
fi

# Clean (adb)
adb shell rm -rf /data/local/tmp/quicklisp
adb shell rm -rf /data/local/tmp/quicklisp.lisp
adb shell rm -rf /data/local/tmp/.slime
adb shell rm -rf /data/local/tmp/.sbclrc
adb shell rm -rf /data/local/tmp/.cache/common-lisp

# Install quicklisp (adb)
adb push build/external/quicklisp.lisp /data/local/tmp/quicklisp.lisp
adb shell "cd /data/local/tmp ; export HOME=\$(pwd) ; ./sbcl/run-sbcl.sh --load quicklisp.lisp --eval '(quicklisp-quickstart:install)' --eval '(ql-util:without-prompting (ql:add-to-init-file))' --quit"
adb shell rm -rf /data/local/tmp/quicklisp.lisp
