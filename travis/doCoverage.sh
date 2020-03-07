#!/usr/bin/env bash

#
# (c) Notice: Travis processor configuration file taken from the GTtest CI
#             build config
#

set -evx

pushToCoveralls=true

if [[ "$GCOV" == "" ]]; then
    GCOV="gcov"
fi

if [[ "$1" == "--nopush" ]]; then
    pushToCoveralls=false
    shift
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

env | sort
if [[ "$DEPS_ROOT" == "" ]]; then
    DEPS_ROOT=$PWD/deps
    echo "No deps directory (DEPS_ROOT) provided, falling back to: $DEPS_ROOT"
fi
DEPS_PREFIX="$DEPS_ROOT/build"
DEPS_LOCATION="$DEPS_ROOT/build/lib/cmake"
if [[ -e $DEPS_LOCATION ]]; then
    DEPS_FLAGS="-DCMAKE_PREFIX_PATH:PATH=$DEPS_PREFIX -DCMAKE_MODULE_PATH:PATH=$DEPS_LOCATION"
else
    DEPS_FLAGS=""
fi

# Find GTest doesn't have the courtesy to look in the cmake prefix location...
if [[ -e "$DEPS_ROOT/include/gtest/gtest.h" ]]; then
    export GTEST_ROOT="$DEPS_ROOT"
fi

SRC_ROOT="$PWD"

# Generate the build tree
mkdir Coverage || true
cd Coverage

# START: LCOV BUILD
# We need a bleeding edge lcov so that it can read gcc's new JSON format file
#
# This can be removed when travis supports an lcov>=1.14-2
git clone https://github.com/linux-test-project/lcov.git

pushd lcov
mkdir lcov_install
DESTDIR=lcov_install make install
_LCOV="$PWD/lcov_install/usr/local/bin/lcov"
popd
#
# END: LCOV BUILD

function LCov {
    $_LCOV --gcov-tool $GCOV $@
}

function CombineLCovFilesInto {
    output_file=$1
    shift
    args="--output-file=$output_file "
    for f in $@; do
        args+="-a $f "
    done
    LCov $args

}

function RemoveFromLCOVFile {
    lcov_file=$1
    pattern=$2

    set -o noglob
    LCov --output-file=$lcov_file --remove $lcov_file $@
    set +o noglob

}


cmake -DCMAKE_CXX_FLAGS=$CXX_FLAGS \
      -DCMAKE_BUILD_TYPE=Coverage \
      $DEPS_FLAGS  \
      --build . .. || exit


# Build the Code
make || exit

lcov_baseline_file="$PWD/lcov_baseline.info"
lcov_test_run_file="$PWD/lcov_test_run.info"
lcov_accumulated_file="$PWD/lcov.info"

LCov --no-external --capture  -b $SRC_ROOT -d . -i --output-file="$lcov_baseline_file" || exit 1

make test || exit

LCov --no-external --capture  -b $SRC_ROOT -d . --output-file="$lcov_test_run_file" || exit 1

cd ..

CombineLCovFilesInto $lcov_accumulated_file $lcov_baseline_file $lcov_test_run_file

RemoveFromLCOVFile $lcov_accumulated_file "$PWD/deps/*" "$PWD/test/*" "$LCOV_FILTERS"

echo "REPORTED_FILES: The following source files are reported by lcov analysis of the notes files"
LCov --list $lcov_accumulated_file

if [[ $pushToCoveralls == true ]]; then
    cpp-coveralls --root . --no-gcov --lcov-file=$lcov_accumulated_file $COVERALLS_FLAGS
else
    genhtml --demangle-cpp --legend --num-spaces 4 -s "$lcov_accumulated_file" --output-directory="Coverage/coverhtml"
fi

exit 0
