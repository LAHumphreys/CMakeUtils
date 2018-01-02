#!/usr/bin/env sh
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

# Generate the build tree
mkdir Coverage || true
cd Coverage
cmake -DCMAKE_CXX_FLAGS=$CXX_FLAGS \
      -DCMAKE_BUILD_TYPE=Coverage \
      --build .
      ..

# Build the Code
make

# Run the tests
make test

# Post the coveralls result
cd ..
coveralls -r . -b Coverage -e dep -e Build -e test --gcov gcov-6 --verbose 
