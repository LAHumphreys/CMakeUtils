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

mkdir build || true
cd build
cmake -DCMAKE_CXX_FLAGS=$CXX_FLAGS \
      -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
      ../gtest
make

#
# Remove the old pacakge, we're about to install our own
#
# NOTE: If we don't do this, the old src directory is left in place, which
#       confuses rapidjson who will then try to build against it.
#
sudo apt-get -y remove libgtest-dev

sudo make install
