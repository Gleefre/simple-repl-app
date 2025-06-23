#!/bin/sh
set -e

# Determine target abi
if [ -n "$1" ]; then
    abi=$1
elif [ -n "$ABI" ]; then
    abi=$ABI
else
    uname_arch=`adb shell uname -m`

    case $uname_arch in
        x86_64) abi=x86_64 ;;
        aarch64) abi=arm64-v8a ;;
        *) echo "Architecture $uname_arch is not supported."
           exit 1 ;;
    esac
fi
echo "Determined target $abi."

build_dir=sbcl-android-pptl-build-$abi

# Clean or clone (repo)
if [ -d "$build_dir" ];
then
    echo "Cleaning $build_dir."

    ( cd $build_dir;
      git checkout sbcl-android-upd-pptl;
      ./clean.sh;
      if [ -d android-libs ]; then rm -r android-libs; fi )
else
    echo "Cloning SBCL into $build_dir."
    git clone https://github.com/Gleefre/sbcl.git -b sbcl-android-upd-pptl $build_dir
fi

# Clean (adb)
echo "Deleting /data/local/tmp/sbcl on the target device."
adb shell rm -rf /data/local/tmp/sbcl

# Setup android-libs
echo "Creating $build_dir/android-libs."
mkdir -p $build_dir/android-libs
cp prebuilt/sbcl-android-libs/$abi/* $build_dir/android-libs

# Build
echo "Building SBCL."
( cd $build_dir;
  echo '"2.5.5-android"' > version.lisp-expr;
  ./make-android.sh --fancy )

# Pack
pack_dir=sbcl-android-pptl-$abi
echo "Packing SBCL into $pack_dir."
cp build-scripts/sbcl-android-pack.sh $build_dir
( cd $build_dir;
  ./sbcl-android-pack.sh $pack_dir;
  zip -r $pack_dir $pack_dir; )

# Move packed zip into prebuilt section
echo "Moving $build_dir/$pack_dir to prebuilt/sbcl."
mv $build_dir/$pack_dir.zip prebuilt/sbcl

# Copy libsbcl.so to libs folder, as well as from android-libs
echo "Copying sbcl-$abi/src/runtime/libsbcl.so to libs/$abi."
cp $build_dir/src/runtime/libsbcl.so libs/$abi
echo "Copying sbcl-$abi/android-libs/*.so to libs/$abi."
cp $build_dir/android-libs*.so libs/$abi
