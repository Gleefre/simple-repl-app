#!/bin/sh
if [ ! -f quicklisp.lisp ]; then
    wget https://beta.quicklisp.org/quicklisp.lisp
fi

# Clean
adb shell rm -rf /data/local/tmp/quicklisp
adb shell rm -rf /data/local/tmp/quicklisp.lisp
adb shell rm -rf /data/local/tmp/.slime
adb shell rm -rf /data/local/tmp/.sbclrc
adb shell rm -rf /data/local/tmp/.cache/common-lisp

adb push quicklisp.lisp /data/local/tmp
adb shell "cd /data/local/tmp ; export HOME=\$(pwd) ; ./sbcl/run-sbcl.sh --load quicklisp.lisp --eval '(quicklisp-quickstart:install)' --eval '(ql-util:without-prompting (ql:add-to-init-file))' --quit"

