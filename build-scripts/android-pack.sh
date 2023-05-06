#!/bin/sh
set -e

if [ -z $DIR ]; then
    DIR=sbcl-pack
fi

mkdir -p android-libs
mkdir -p $DIR/obj
mkdir -p $DIR/output
mkdir -p $DIR/src/runtime
cp -r android-libs $DIR/
cp src/runtime/sbcl $DIR/src/runtime/
cp src/runtime/libsbcl.so $DIR/src/runtime/
cp output/sbcl.core $DIR/output/
cp -r obj/sbcl-home $DIR/obj/
cp run-sbcl.sh $DIR/
cp BUGS $DIR/
cp NEWS $DIR/
cp COPYING $DIR/
cp CREDITS $DIR/
cp pubring.pgp $DIR/
cp README $DIR/
