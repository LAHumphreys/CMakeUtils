#!/usr/bin/env sh

#
# (c) Notice: Travis processor configuration file taken from the GTtest CI
#             build config
#

set -evx

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

env | sort
DEPS_LOCATION="$PWD/deps/build/lib/cmake"
if [[ -e $DEPS_LOCATION ]]; then
    DEPS_FLAGS="-DCMAKE_PREFIX_PATH:PATH=$DEPS_LOCATION"
else
    DEPS_FLAGS=""
fi

# Generate the build tree
mkdir Coverage || true
cd Coverage
cmake -DCMAKE_CXX_FLAGS=$CXX_FLAGS \
      -DCMAKE_BUILD_TYPE=Coverage \
      $DEPS_FLAGS 
      --build . .. || exit

# Build the Code
make || exit

# Run the tests
make test || exit

# Post the coveralls result
cd ..

coveralls -r . -b Coverage -e CMakeUtils -e dep -e Coverage/CmakeFiles -e Build -e test --gcov gcov-6 $@
