#!/bin/bash

DEPS_ROOT="$PWD/deps/build"
DEPS_LOCATION="$DEPS_ROOT/lib/cmake"
if [[ -e $DEPS_LOCATION ]]; then
    echo "Building project..."
else
    echo "Dependencies must be built first"
    exit 1
fi

# Find GTest doesn't have the courtesy to look in the cmake prefix location...
if [[ -e "$DEPS_ROOT/include/gtest/gtest.h" ]]; then
    export GTEST_ROOT="$DEPS_ROOT"
fi

mkdir -p Build
cd Build
cmake -DCMAKE_BUILD_TYPE=Release "-DCMAKE_PREFIX_PATH:PATH=$DEPS_LOCATION" .. || exit 1
make || exit 1
cd ..
