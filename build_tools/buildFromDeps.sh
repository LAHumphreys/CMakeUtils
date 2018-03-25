#!/bin/bash

DEPS_ROOT="$PWD/deps/build"
DEPS_LOCATION="$DEPS_ROOT/lib/cmake"
if [[ -e $DEPS_LOCATION ]]; then
    echo "Building project..."
else
    echo "Dependencies must be built first"
    exit 1
fi

# if possible, ask for the precise number of processors,
# otherwise take 2 processors as reasonable default; see
# https://docs.travis-ci.com/user/speeding-up-the-build/#Makefile-optimization
if [ -x /usr/bin/getconf ]; then
    NPROCESSORS=$(/usr/bin/getconf _NPROCESSORS_ONLN)
else
    NPROCESSORS=2
fi

# Tell make to use the processors. No preceding '-' required.
MAKEFLAGS="j${NPROCESSORS}"
export MAKEFLAGS

# Find GTest doesn't have the courtesy to look in the cmake prefix location...
if [[ -e "$DEPS_ROOT/include/gtest/gtest.h" ]]; then
    export GTEST_ROOT="$DEPS_ROOT"
fi

mkdir -p Build
cd Build
cmake -DCMAKE_BUILD_TYPE=Release "-DCMAKE_PREFIX_PATH:PATH=$DEPS_LOCATION" .. || exit 1
make || exit 1
cd ..
